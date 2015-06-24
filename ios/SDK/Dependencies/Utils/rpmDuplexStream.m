//
//  rpmDuplexStream.m
//  SavantMediaQuery
//
//  Created by Cameron Pulsford on 9/30/12.
//  Copyright (c) 2012  Savant Systems, LLC. All rights reserved.
//

//##OBJCLEAN_SKIP##

#import "rpmDuplexStream.h"

#define READ_SIZE 4096

@interface rpmDuplexStream ()
- (void)readBuffer;
- (void)writeBuffer;
- (void)maybeOpened;
- (void)receivedErrorFromStream:(NSStream *)stream;
- (void)purgeData;
@end

@implementation rpmDuplexStream

@synthesize delegate            = _delegate;
@synthesize wantsStrings        = _wantsStrings;
@synthesize stringEncoding      = _stringEncoding;
@synthesize safeDataParsing     = _safeDataParsing;
@synthesize checkJPEG           = _checkJPEG;
@synthesize contentLength       = _contentLength;
@synthesize dataReceivedLength  = _dataReceivedLength;
@synthesize userInfo            = _userInfo;
@synthesize timeoutTime         = _timeoutTime;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreceiver-forward-class"
- (void)dealloc
{
    _delegate = nil;
    [self close];
    [self purgeData];
    [_host release];
    [_lineDelimiter release];
    [_userInfo release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _stringEncoding = NSUTF8StringEncoding;
        _safeDataParsing = YES;
        _checkJPEG = NO;
        _contentLength = 0;
        _dataReceivedLength=0;
    }
    
    return self;
}

- (void)configureWithURL:(NSURL *)url
{
    [_address release];
    NSString *address = [url host] ? [url host] : [url absoluteString];
    _address = [address retain];

    _port = [url port] ? [[url port] integerValue] : 80;

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
    [self configureWithHost:[NSHost hostWithAddress:_address] port:_port];
#endif
}

- (void)configureWithHost:(NSHost *)host port:(NSInteger)port
{
    if (_host)
    {
        [_host release];
    }
    
    _host = [host retain];
    _port = port;
}
#pragma clang diagnostic push

- (void)setLineDelimiter:(rpmDuplexStreamLineDelimiter_t)lineDelimiter
{
    if (_lineDelimiter)
    {
        [_lineDelimiter release];
        _lineDelimiter = nil;
    }
    
    switch (lineDelimiter)
    {
        case rpmDuplexStreamLineDelimiter_None:
            break;
        case rpmDuplexStreamLineDelimiter_CR:
            _lineDelimiter = [[NSData alloc] initWithBytes:"\x0d" length:1];
            break;
        case rpmDuplexStreamLineDelimiter_LF:
            _lineDelimiter = [[NSData alloc] initWithBytes:"\x0a" length:1];
            break;
        case rpmDuplexStreamLineDelimiter_CRLF:
            _lineDelimiter = [[NSData alloc] initWithBytes:"\x0d\x0a" length:2];
            break;
    }
}

- (BOOL)isConnected
{
    @synchronized (self)
    {
        return _opensCompleted == 2;
    }
}

- (void)open
{
    @synchronized (self)
    {
        if (!(_iStream && _oStream))
        {
            [self purgeData];

            _readBuffer = [[NSMutableData alloc] init];
            _writeBuffer = [[NSMutableData alloc] init];

            NSInputStream *iStream = nil;
            NSOutputStream *oStream = nil;

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
            [NSStream getStreamsToHost:_host port:_port inputStream:&iStream outputStream:&oStream];
            _iStream = [iStream retain];
            _oStream = [oStream retain];
#else
            CFReadStreamRef readStream = NULL;
            CFWriteStreamRef writeStream = NULL;

            CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)_address, (unsigned int)_port, &readStream, &writeStream);

            iStream = (NSInputStream *)readStream;
            oStream = (NSOutputStream *)writeStream;
            _iStream = iStream;
            _oStream = oStream;
#endif

            _iStream.delegate = self;
            _oStream.delegate = self;
            
            [_iStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            _opensCompleted = 0;
            [_iStream open];
            [_oStream open];

            [_timeoutTimer invalidate];

            if (self.timeoutTime > 0)
            {
                _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutTime
                                                                 target:self
                                                               selector:@selector(streamDidTimeout)
                                                               userInfo:nil
                                                                repeats:NO];
            }
        }
    }
}

- (NSData *)unreadData
{
    NSData *unreadData = [[_readBuffer retain] autorelease];

    [_readBuffer release];
    _readBuffer = nil;

    return unreadData;
}

- (void)close
{
    @synchronized (self)
    {
        if (_iStream && _oStream)
        {
            //--------------------------------------------------
            // Cleanup the streams.
            //--------------------------------------------------
            [_timeoutTimer invalidate];
            _timeoutTimer = nil;
            _iStream.delegate = nil;
            _oStream.delegate = nil;
            [_iStream close];
            [_iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_oStream close];
            [_oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_iStream release];
            [_oStream release];
            _iStream = nil;
            _oStream = nil;

            _opensCompleted = 0;
            _dataReceivedLength =0;
            _contentLength =0;
            _checkJPEG= NO;

            [_timeoutTimer invalidate];
            _timeoutTimer = nil;
        }
    }
}

- (void)purgeData
{
    @synchronized(self)
    {
        //--------------------------------------------------
        // Release the I/O buffers.
        //--------------------------------------------------
        [_readBuffer release];
        _readBuffer = nil;
        [_writeBuffer release];
        _writeBuffer = nil;
    }
}

- (NSString *)convertDataIntoString:(NSData *)data range:(NSRangePointer)range
{
    NSUInteger dataLength = [data length];
    NSUInteger location = 0;
    NSUInteger length = dataLength;
    
    if (range)
    {
        location = range->location;
        length = range->length;
    }
    
    NSString *string = nil;
    
    //--------------------------------------------------
    // Don't convert the string if it would raise an out
    // of bounds exception. Leave string as nil.
    //--------------------------------------------------
    if (location + length <= dataLength)
    {
        string = [[[NSString alloc] initWithBytes:(char *)[data bytes] + location length:length encoding:self.stringEncoding] autorelease];
    }
    
    return string;
}

- (void)writeData:(NSData *)data appendLineDelimiter:(BOOL)appendLineDelimiter
{
    if (![data length])
    {
        return;
    }
    
    @synchronized (self)
    {
        //--------------------------------------------------
        // Append the data onto the write buffer.
        //--------------------------------------------------
        [_writeBuffer appendData:data];
        
        //--------------------------------------------------
        // Append the line delimiter onto the write buffer
        // if requested.
        //--------------------------------------------------
        if (appendLineDelimiter && _lineDelimiter)
        {
            [_writeBuffer appendData:_lineDelimiter];
        }
    }
    
    //--------------------------------------------------
    // Try to write the buffer.
    //--------------------------------------------------
    [self writeBuffer];
}

- (void)writeString:(NSString *)string
{
    [self writeData:[string dataUsingEncoding:self.stringEncoding] appendLineDelimiter:YES];
}

- (void)writeStrings:(NSArray *)strings
{
    @synchronized (self)
    {
        for (NSString *string in strings)
        {
            [_writeBuffer appendData:[string dataUsingEncoding:self.stringEncoding]];
            [_writeBuffer appendData:_lineDelimiter];
        }
    }
    
    [self writeBuffer];
}

#pragma mark - NSStreamDelegate methods

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventNone:
        {
            break;
        }
        case NSStreamEventOpenCompleted:
        {
            [self maybeOpened];
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            if (stream == _iStream)
            {
                [self readBuffer];
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            if (stream == _oStream)
            {
                [self writeBuffer];
            }
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            [self receivedErrorFromStream:stream];
            break;
        }
        case NSStreamEventEndEncountered:
        {
            [self receivedErrorFromStream:stream];
            break;
        }
    }
}

- (void)streamDidTimeout
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;

    if ([self.delegate respondsToSelector:@selector(streamDidCloseWithTimeout:)])
    {
        [self.delegate streamDidCloseWithTimeout:self];
    }
}

- (void)streamDidOpen
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;

    if ([self.delegate respondsToSelector:@selector(streamDidOpen:)])
    {
        [self.delegate streamDidOpen:self];
    }
}

- (void)streamDidCloseWithError:(NSError *)error
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;

    if ([self.delegate respondsToSelector:@selector(stream:didCloseWithError:)])
    {
        [self.delegate stream:self didCloseWithError:error];
    }
}

- (BOOL)streamDidReadPartialData:(NSData *)data
{
    BOOL flushData = NO;
    
    if ([self.delegate respondsToSelector:@selector(stream:didReadPartialData:)])
    {
        flushData = [self.delegate stream:self didReadPartialData:data];
    }
    
    return flushData;
}

- (void)streamDidReadData:(NSData *)data
{
    if ([self.delegate respondsToSelector:@selector(stream:didReadData:)])
    {
        [self.delegate stream:self didReadData:data];
    }
}

- (void)streamDidReadLineData:(NSData *)lineData
{
    if ([self.delegate respondsToSelector:@selector(stream:didReadLineData:)])
    {
        [self.delegate stream:self didReadLineData:lineData];
    }
}

- (void)streamDidReadLineString:(NSString *)lineString
{
    if ([self.delegate respondsToSelector:@selector(stream:didReadLineString:)])
    {
        [self.delegate stream:self didReadLineString:lineString];
    }
}

#pragma mark - Internal

- (void)readBuffer
{
    while ([_iStream hasBytesAvailable])
    {
        uint8_t buffer[READ_SIZE];
        NSInteger bytesRead = [_iStream read:(uint8_t *)&buffer maxLength:READ_SIZE];
        
        if (bytesRead <= 0)
        {
            [self receivedErrorFromStream:_iStream];
            return;
        }
        
        //-------------------------------------------------------------------
        // No line delimiter is specified so just send all data as is to the
        // delegate.
        //-------------------------------------------------------------------
        if (!_lineDelimiter)
        {
            if (self.safeDataParsing)
            {
                NSData *data = [NSData dataWithBytes:(const void *)buffer length:(NSUInteger)bytesRead];
                [self streamDidReadData:data];
            }
            else
            {
                NSData *data = [[NSData alloc] initWithBytesNoCopy:(void *)buffer length:(NSUInteger)bytesRead freeWhenDone:NO];
                [self streamDidReadData:data];
                [data release];
            }
            
            continue;
        }
        
        NSData *data = [[NSData alloc] initWithBytesNoCopy:(void *)buffer length:(NSUInteger)bytesRead freeWhenDone:NO];
        NSRange searchRange = NSMakeRange(0, (NSUInteger)bytesRead);
        
        while (searchRange.location < (NSUInteger)bytesRead)
        {
            NSRange rangeOfLineDelimiter = [data rangeOfData:_lineDelimiter options:0 range:searchRange];
            
            //-------------------------------------------------------------------
            // A line delimiter was not found so append all the data onto our
            // _readBuffer for now and break out of the loop.
            //-------------------------------------------------------------------
            if (rangeOfLineDelimiter.location == NSNotFound)
            {
                if (!_readBuffer)
                {
                    _readBuffer = [[NSMutableData alloc] initWithBytes:(const char *)[data bytes] + searchRange.location length:searchRange.length];
                    
                    //-------------------------------------------------------------------
                    // If the image is a jpeg and has a content length count the bytes in the image data
                    //-------------------------------------------------------------------
                    if(_checkJPEG && _contentLength > 0)
                    {
                        if(_dataReceivedLength > 0 )
                        {
                            //-------------------------------------------------------------------
                            // account for continuation of the read in middle of image data
                            //-------------------------------------------------------------------
                            _dataReceivedLength += searchRange.location;
                        }
                        _dataReceivedLength += searchRange.length ;
                    }
                }
                else
                {
                    [_readBuffer appendBytes:(uint8_t *)[data bytes] + searchRange.location length:searchRange.length];
                    
                    if(_checkJPEG && _contentLength > 0)
                    {
                        _dataReceivedLength +=searchRange.length;
                    }
                }
                
                if ([self streamDidReadPartialData:[[_readBuffer retain] autorelease]])
                {
                    [_readBuffer release];
                    _readBuffer = nil;
                }
                
                //-------------------------------------------------------------------
                // For HTTP Persistent, if the content-length of image data is read close the connection
                //-------------------------------------------------------------------
                if(_checkJPEG && _contentLength > 0)
                {
                    if( _contentLength == _dataReceivedLength)
                    {
                        [self receivedErrorFromStream:_iStream];
                    }
                }
                
                break;
            }
            
            NSUInteger location = searchRange.location;
            NSUInteger length = rangeOfLineDelimiter.location - location;
            
            if (length || (location == rangeOfLineDelimiter.location))
            {
                uint8_t *bytes = NULL;

                if ([_readBuffer length])
                {
                    //-------------------------------------------------------------------
                    // There is an existing _readBuffer which means we are completing a
                    // previous read.
                    //-------------------------------------------------------------------
                    [_readBuffer appendBytes:(uint8_t *)[data bytes] + location length:length];
                    length = [_readBuffer length];
                    bytes = (uint8_t *)[_readBuffer bytes];
                }
                else
                {
                    //-------------------------------------------------------------------
                    // This is a new read.
                    //-------------------------------------------------------------------
                    bytes = (uint8_t *)[data bytes] + location;
                }
                
                if (self.wantsStrings)
                {
                    if (self.safeDataParsing)
                    {
                        NSString *string = [[[NSString alloc] initWithBytes:(const void *)bytes length:length encoding:self.stringEncoding] autorelease];
                        [self streamDidReadLineString:string];
                    }
                    else
                    {
                        NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)bytes length:length encoding:self.stringEncoding freeWhenDone:NO];
                        [self streamDidReadLineString:string];
                        [string release];
                    }
                }
                else
                {
                    if ([_readBuffer length])
                    {
                        NSData *lineData = [[_readBuffer retain] autorelease];
                        [self streamDidReadLineData:lineData];
                    }
                    else if (self.safeDataParsing)
                    {
                        NSData *lineData = [NSData dataWithBytes:(const void *)bytes length:length];
                        [self streamDidReadLineData:lineData];
                    }
                    else
                    {
                        NSData *lineData = [[NSData alloc] initWithBytesNoCopy:(void *)bytes length:length freeWhenDone:NO];
                        [self streamDidReadLineData:lineData];
                        [lineData release];
                    }
                }
            }
            
            if (_readBuffer)
            {
                //-------------------------------------------------------------------
                // The _readBuffer has been completed so get rid of it.
                //-------------------------------------------------------------------
                [_readBuffer release];
                _readBuffer = nil;
            }
            
            //-------------------------------------------------------------------
            // Setup the search range and search for the next line.
            //-------------------------------------------------------------------
            NSUInteger offset = rangeOfLineDelimiter.location + rangeOfLineDelimiter.length;
            searchRange.location = offset;
            searchRange.length = (NSUInteger)bytesRead - offset;
        }
        
        [data release];
        
        if (bytesRead < READ_SIZE)
        {
            break;
        }
    }
}

- (void)writeBuffer
{
    @synchronized (self)
    {
        NSUInteger totalBytesToWrite = [_writeBuffer length];
        NSRange sendRange = NSMakeRange(0, totalBytesToWrite);
        
        while (sendRange.length && [_oStream hasSpaceAvailable])
        {
            NSInteger bytesWritten = [_oStream write:(const uint8_t *)[_writeBuffer bytes] + sendRange.location maxLength:sendRange.length];
            
            if (bytesWritten <= 0)
            {
                [self receivedErrorFromStream:_oStream];
                return;
            }
            
            sendRange.location += (NSUInteger)bytesWritten;
            sendRange.length -= (NSUInteger)bytesWritten;
        }
        
        if (sendRange.location == totalBytesToWrite)
        {
            //--------------------------------------------------
            // All of the data could be written so reset the
            // buffer.
            //--------------------------------------------------
            [_writeBuffer setLength:0];
        }
        else
        {
            //--------------------------------------------------
            // Not all of the data could be written. Set the
            // buffer to just the unwritten data.
            //--------------------------------------------------
            [_writeBuffer replaceBytesInRange:NSMakeRange(0, sendRange.location) withBytes:NULL length:0];
        }
    }
}

- (void)maybeOpened
{
    @synchronized (self)
    {
        _opensCompleted++;
        
        if (_opensCompleted == 2)
        {
            [self streamDidOpen];
        }
    }
}

- (void)receivedErrorFromStream:(NSStream *)stream
{
    NSError *error = [stream streamError];
    [self close];
    [self streamDidCloseWithError:error];
}

@end

//##OBJCLEAN_ENDSKIP##
