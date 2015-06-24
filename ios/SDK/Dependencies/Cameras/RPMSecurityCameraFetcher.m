//====================================================================
//
// RESTRICTED RIGHTS LEGEND
//
// Use, duplication, or disclosure is subject to restrictions.
//
// Unpublished Work Copyright (C) 2012 Savant Systems, LLC
// All Rights Reserved.
//
// This computer program is the property of 2012 Savant Systems, LLC and contains
// its confidential trade secrets.  Use, examination, copying, transfer and
// disclosure to others, in whole or in part, are prohibited except with the
// express prior written consent of 2012 Savant Systems, LLC.
//
//====================================================================
//
// AUTHOR: Nathan Trapp
//
// DESCRIPTION: 
//
//====================================================================

#import "RPMSecurityCameraFetcher.h"

#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
#import <rpmGeneralUtils/rpmSharedLogger.h>
#import <rpmGeneralUtils/rpmCocoaExtensions.h>
#import <rpmGeneralUtils/NSData+rpmBase64Encoding.h>
#import <rpmGeneralUtils/MD5.h>
#import <rpmGeneralUtils/rpmDuplexStream.h>
#else
#import "rpmSharedLogger.h"
#import "rpmDuplexStream.h"
#import "MD5.h"
#endif

#ifdef GNUSTEP
#import <rpmGeneralUtils/rpmGNUStepExtensions.h>
#endif

@interface MD5 (MD5Helpers)

+ (NSString *)digestForString:(NSString *)string;

@end

@implementation MD5 (MD5Helpers)

+ (NSString *)digestForString:(NSString *)string
{
    MD5 *md5 = [[MD5 alloc] initWithString:string encoding:NSUTF8StringEncoding];
    [md5 computeDigest];
    NSString *digest = [md5 digestAsString];
    [md5 release];
    return digest;
}

@end

static NSString *const SecurityCameraTransferComplete  = @"SecurityCameraTransferComplete";
static NSString *const SecurityCameraFrequency         = @"SecurityCameraFrequency";
static NSString *const SecurityCameraLastTransfer      = @"SecurityCameraLastTransfer";

@interface RPMSecurityCameraFetcher () <rpmDuplexStreamDelegate>

- (void)receivedImageUpdate:(NSData *)imageData;
- (void)fetchTimedOut;
- (void)finishAndWait:(NSTimeInterval)delay;
- (void)finish;
- (void)updateFetchFrequency:(NSTimeInterval)frequency;
- (void)startFetchOnThread:(NSDictionary *)passthrough;
- (void)failedToFetchImage;
- (void)_fetchImage;

- (void)streamReceivedStatusCode:(NSInteger)statusCode;
- (void)authenticate:(NSString *)authHeader;
- (void)resetAuthValues;

- (NSData *)stripTrailingBytes:(NSData *)data;
- (BOOL)isValidJpegData:(NSData *)data;

@end

@implementation RPMSecurityCameraFetcher

@synthesize imagePath = _imagePath;
@synthesize username = _username;
@synthesize password = _password;
@synthesize cameraName = _cameraName;
@synthesize host = _host;
@synthesize port = _port;

- (id)initWithPath:(NSString *)imagePath cameraName:(NSString *)name
{
    self = [super init];
    if (self != nil)
    {
        _cameraName = [name retain];

        if ([imagePath hasPrefix:@"http"])
        {
            imagePath = [imagePath stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        }

        NSArray *components = [imagePath componentsSeparatedByString:@"@"];
        if ([components count] == 2)
        {
            imagePath = [components objectAtIndex:1];

            components = [[components objectAtIndex:0] componentsSeparatedByString:@":"];
            if ([components count])
            {
                _username = [[components objectAtIndex:0] retain];

                if ([components count] == 2)
                {
                    _password = [[components objectAtIndex:1] retain];
                }
                else
                {
                    _password = [@"" retain];
                }
            }
        }

        components = [imagePath componentsSeparatedByString:@"/"];
        if ([components count] >= 2)
        {
            NSString *host = [components objectAtIndex:0];
            components = [host componentsSeparatedByString:@":"];
            if ([components count] == 2)
            {
                _host = [[components objectAtIndex:0] retain];
                _port = [[components objectAtIndex:1] integerValue];
            }
            else
            {
                _host = [host retain];
                _port = 80;
            }

            _imagePath = [[[imagePath stringByReplacingOccurrencesOfString:_host withString:@""] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@":%ld", (long)_port] withString:@""] retain];
        }
        else
        {
            RPMLogErr(@"Camera (%@) did not provide a valid path and address %@", self.cameraName, imagePath);
            return nil;
        }

        _duplexStream = [[rpmDuplexStream alloc] init];
        _duplexStream.delegate = self;
        _duplexStream.timeoutTime = 5;

        [_duplexStream configureWithURL:[NSURL URLWithString:[@"http://" stringByAppendingString:[_host stringByAppendingFormat:@":%ld", (long)_port]]]];
        _duplexStream.lineDelimiter = rpmDuplexStreamLineDelimiter_CRLF;

#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS)
        _registeredUIs = [[NSMapTable weakToStrongObjectsMapTable] retain];
#else
        _registeredUIs = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsZeroingWeakMemory
                                                   valueOptions:NSPointerFunctionsObjectPointerPersonality | NSPointerFunctionsStrongMemory
                                                       capacity:0];
#endif
        _fetchThread = [NSThread currentThread];
    }
    return self;
}

- (void)dealloc
{
    [_imagePath release];
    _imagePath = nil;
    [_username release];
    _username = nil;
    [_password release];
    _password = nil;
    [_fetchingImage release];
    _fetchingImage = nil;
    [_cameraName release];
    _cameraName = nil;
    [_registeredUIs release];
    _registeredUIs = nil;
    [_host release];
    _host = nil;

    [_duplexStream release];
    _duplexStream = nil;
    [_boundary release];
    _boundary = nil;

    [_nonce release];
    _nonce = nil;
    [_realm release];
    _realm = nil;
    [_algorithm release];
    _algorithm = nil;
    [_qopType release];
    _qopType = nil;
    [_opaque release];
    _opaque = nil;

    [super dealloc];
}

- (void)fetchWithFrequency:(NSNumber *)frequency forObserver:(id <RPMSecurityCameraFetcherDelegate>)observer
{
    NSDictionary *passthrough = [NSDictionary dictionaryWithObjectsAndKeys:frequency, @"frequency", observer, @"observer", nil];

    if ([NSThread currentThread] == _fetchThread)
    {
        [self startFetchOnThread:passthrough];
    }
    else
    {
        [self performSelector:@selector(startFetchOnThread:) onThread:_fetchThread withObject:passthrough waitUntilDone:NO
#ifdef GNUSTEP
                    modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]
#endif
         ];
    }
}

- (void)startFetchOnThread:(NSDictionary *)passthrough
{
    NSNumber *frequency = [passthrough objectForKey:@"frequency"];
    id <RPMSecurityCameraFetcherDelegate> observer = [passthrough objectForKey:@"observer"];

    @synchronized(_registeredUIs)
    {
        if ([_registeredUIs objectForKey:observer])
        {
            [self stopFetchingForObserver:observer];
        }

        if (!frequency)
        {
            frequency = [NSNumber numberWithInt:1];
        }

        NSTimeInterval obseverFrequency = 1 / [frequency floatValue];

        [_registeredUIs setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:obseverFrequency], SecurityCameraFrequency,
                                   [NSDate distantPast], SecurityCameraLastTransfer,
                                   [NSNumber numberWithBool:YES], SecurityCameraTransferComplete
                                   ,nil]
                           forKey:observer];

        if (([_registeredUIs count] == 1) || obseverFrequency < [_imageUpdate timeInterval])
        {
            [self updateFetchFrequency:obseverFrequency];
        }
    }
}

- (void)updateFetchFrequency:(NSTimeInterval)frequency
{
    _frequency = frequency;

    if (![_duplexStream isConnected])
    {
        [self _fetchImage];
    }
}

- (void)_fetchImage
{
    [_duplexStream close];

    [_imageUpdate invalidate];
    _imageUpdate = nil;
    _fetchStartTime = [[NSDate date] timeIntervalSince1970];

    [_duplexStream open];

    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(fetchTimedOut) userInfo:nil repeats:NO];
}

- (void)stopFetchingForObserver:(id <RPMSecurityCameraFetcherDelegate>)observer
{
    if ([NSThread currentThread] != _fetchThread)
    {
        [self performSelector:_cmd onThread:_fetchThread withObject:observer waitUntilDone:NO
#ifdef GNUSTEP
                        modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]
#endif
         ];
        return;
    }

    @synchronized(_registeredUIs)
    {
        NSTimeInterval obseverFrequency = [[[_registeredUIs objectForKey:observer] objectForKey:SecurityCameraFrequency] floatValue];

        [_registeredUIs removeObjectForKey:observer];

        if (![_registeredUIs count])
        {
            [_duplexStream close];

            [_imageUpdate invalidate];
            _imageUpdate = nil;

            [_timeoutTimer invalidate];
            _timeoutTimer = nil;
        }
        // if this was the fetching frequency, adjust the frequency to the new lowest
        else if (obseverFrequency == _frequency && _frequency != 1)
        {
            obseverFrequency = 1;

            for (id <RPMSecurityCameraFetcherDelegate> obs in _registeredUIs)
            {
                NSMutableDictionary *observerData = [_registeredUIs objectForKey:obs];

                if ([[observerData objectForKey:SecurityCameraFrequency] floatValue] < obseverFrequency)
                {
                    obseverFrequency = [[observerData objectForKey:SecurityCameraFrequency] floatValue];
                }
            }

            [self updateFetchFrequency:obseverFrequency];
        }
    }

}

- (void)transferCompleteForObserver:(id<RPMSecurityCameraFetcherDelegate>)observer
{
    if ([NSThread currentThread] != _fetchThread)
    {
        [self performSelector:_cmd onThread:_fetchThread withObject:observer waitUntilDone:NO
#ifdef GNUSTEP
                        modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]
#endif
         ];
        return;
    }

    @synchronized(_registeredUIs)
    {
        NSMutableDictionary *observerData = [_registeredUIs objectForKey:observer];
        RPMLogDebug(@"Camera (%@) received transfer complete in %f seconds", self.cameraName, -[[observerData objectForKey:SecurityCameraLastTransfer] timeIntervalSinceNow]);
        [observerData setObject:[NSNumber numberWithBool:YES] forKey:SecurityCameraTransferComplete];
    }
}

#pragma mark - Authentication

- (void)authenticate:(NSString *)authHeader
{
    RPMLogDebug(@"Handle authentication header: %@", authHeader);

    [_duplexStream close];
    [self resetAuthValues];

    if (_username && _password)
    {
        NSMutableArray *components = [[authHeader componentsSeparatedByString:@" "] mutableCopy];
        if ([components count] >= 2)
        {
            NSString *authType = [[components objectAtIndex:1] lowercaseString];

            //-------------------------------------------------------------------
            // Digest Auth
            //-------------------------------------------------------------------
            if ([authType isEqualToString:@"digest"] && [components count] >= 3)
            {
                BOOL shouldConnect = YES;

                //-------------------------------------------------------------------
                // Remove the header and auth type
                //-------------------------------------------------------------------
                [components removeObjectAtIndex:0];
                [components removeObjectAtIndex:0];

                NSString *header = [components componentsJoinedByString:@" "];
                header = [header stringByReplacingOccurrencesOfString:@", " withString:@","];

                //-------------------------------------------------------------------
                // Parse authentication header into individual directives.
                //
                // Example digest request header:
                // WWW-Authenticate: Digest realm="AXIS_00408C923E54", nonce="0013b078Y274915fd7ef48ab6f35d58fc6611936d82959", stale=FALSE, qop="auth"
                //-------------------------------------------------------------------
                NSScanner *scanner = [NSScanner scannerWithString:header];
                NSMutableDictionary *headerData = [NSMutableDictionary dictionary];

                NSString *key = nil;
                while ([scanner scanUpToString:@"=" intoString:&key])
                {
                    key = [[key stringByReplacingOccurrencesOfString:@"\"" withString:@""] lowercaseString];

                    scanner.scanLocation++;

                    NSString *value = nil;

                    [scanner scanUpToString:@"," intoString:&value];

                    //-------------------------------------------------------------------
                    // SCR 45579: Values are case sensitive. Don't lowercase anything
                    // that is echoed back to the device
                    //-------------------------------------------------------------------
                    value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@""];

                    //-------------------------------------------------------------------
                    // Lowercase qop and algorithm values for easier containsObject checks later
                    //-------------------------------------------------------------------
                    if ([key isEqualToString:@"qop"] || [key isEqualToString:@"algorithm"])
                    {
                        value = [value lowercaseString];
                    }

                    if (key && value)
                    {
                        [headerData setObject:value forKey:key];
                    }

                    if (scanner.scanLocation < [header length])
                    {
                        scanner.scanLocation++;
                    }
                }

                //-------------------------------------------------------------------
                // Build auth data from specified directives
                //-------------------------------------------------------------------
                for (NSString *optionType in headerData)
                {
                    NSArray *optionValues = [[headerData objectForKey:optionType] componentsSeparatedByString:@","];

                    if (optionType && [optionValues count])
                    {
                        if ([optionType isEqualToString:@"realm"])
                        {
                            _realm = [[[optionValues objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\"" withString:@""] retain];
                        }
                        else if ([optionType isEqualToString:@"qop"])
                        {
                            if ([optionValues containsObject:@"auth"])
                            {
                                _qopType = [@"auth" retain];
                            }
                            else if ([optionValues containsObject:@"auth-int"])
                            {
                                _qopType = [@"auth-int" retain];
                            }
                            else
                            {
                                RPMLogErr(@"Camera: %@ cannot use digest authentication, no supported qop directive: %@", self.cameraName, optionValues);
                                shouldConnect = NO;
                            }
                        }
                        else if ([optionType isEqualToString:@"nonce"])
                        {
                            _nonce = [[[optionValues objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\"" withString:@""] retain];
                        }
                        else if ([optionType isEqualToString:@"algorithm"])
                        {
                            if ([optionValues containsObject:@"md5"])
                            {
                                _algorithm = [@"md5" retain];
                            }
                            else if ([optionValues containsObject:@"md5-sess"])
                            {
                                _algorithm = [@"md5-sess" retain];
                            }
                            else
                            {
                                RPMLogErr(@"Camera: %@ cannot use digest authentication, no supported algorithm directive: %@", self.cameraName, optionValues);
                                shouldConnect = NO;
                            }
                        }
                        else if ([optionType isEqualToString:@"opaque"])
                        {
                            _opaque = [[[optionValues objectAtIndex:0] stringByReplacingOccurrencesOfString:@"\"" withString:@""] retain];
                        }
                    }
                }

                if (_realm && _nonce)
                {
                    //-------------------------------------------------------------------
                    // Reconnect immediately with new authentication information
                    //-------------------------------------------------------------------
                    if (shouldConnect)
                    {
                        [_duplexStream open];
                    }
                    else
                    {
                        [self failedToFetchImage];
                    }
                }
                else
                {
                    RPMLogErr(@"Camera: %@ cannot build digest auth response, failed to receive realm: %@ or nonce: %@", self.cameraName, _realm, _nonce);
                    
                    [self failedToFetchImage];
                }
            }
            //-------------------------------------------------------------------
            // Basic Auth
            //-------------------------------------------------------------------
            else if ([authType isEqualToString:@"basic"])
            {
                RPMLogErr(@"Camera (%@) failed basic auth", self.cameraName);

                [self failedToFetchImage];
            }
            else
            {
                RPMLogErr(@"Camera (%@) received unsupported authType: %@", self.cameraName, authType);

                [self failedToFetchImage];
            }
        }
        
        [components release];
        
    }
    else
    {
        RPMLogErr(@"Camera (%@) requires authentication, but no username/password provided", self.cameraName);

        [self failedToFetchImage];
    }
}

- (void)resetAuthValues
{
    _requestCounter = 0;
    [_nonce release];
    _nonce = nil;
    [_realm release];
    _realm = nil;
    [_qopType release];
    _qopType = nil;
    [_algorithm release];
    _algorithm = nil;
    [_opaque release];
    _opaque = nil;
}

- (void)cleanup
{
    [_fetchingImage release];
    _fetchingImage = nil;

    [_boundary release];
    _boundary = nil;

    _statusCode = 0;

    _hasHeaders = NO;
    _foundJPEG =NO;
}

#pragma mark - rpmDuplexStreamDelegate

/**
 *  The stream opened.
 *
 *  @param stream The stream.
 */
- (void)streamDidOpen:(rpmDuplexStream *)stream
{
    [self cleanup];

    //-------------------------------------------------------------------
    // Build the HTTP request
    //-------------------------------------------------------------------

    NSString *method = @"GET";
    NSString *uri = _imagePath;

    NSString *request = [NSString stringWithFormat:@"%@ %@ HTTP/1.0", method, uri];
    //-------------------------------------------------------------------
    // Look like Safari
    //-------------------------------------------------------------------
    request = [request stringByAppendingFormat:@"\r\n%@", @"User-Agent: Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25"];

    //-------------------------------------------------------------------
    // Prefer digest auth
    //-------------------------------------------------------------------
    if (_nonce && _realm)
    {
        _requestCounter++;

        NSString *response = nil;
        NSString *ha1 = nil;
        NSString *ha2 = nil;

        NSString *cnonce = [MD5 digestForString:[[NSProcessInfo processInfo] globallyUniqueString]];

        //-------------------------------------------------------------------
        // Calculate the digest response based on the provided arguments
        //-------------------------------------------------------------------

        if ([_algorithm isEqualToString:@"md5-sess"])
        {
            //-------------------------------------------------------------------
            // MD5(MD5(username:realm:password):nonce:cnonce)
            //-------------------------------------------------------------------
            ha1 = [MD5 digestForString:[[MD5 digestForString:[NSString stringWithFormat:@"%@:%@:%@", _username, _realm, _password]] stringByAppendingFormat:@":%@:%@", _nonce, cnonce]];
        }
        else
        {
            //-------------------------------------------------------------------
            // MD5(username:realm:password)
            //-------------------------------------------------------------------
            ha1 = [MD5 digestForString:[NSString stringWithFormat:@"%@:%@:%@", _username, _realm, _password]];
        }

        if ([_qopType isEqualToString:@"auth-int"])
        {
            //-------------------------------------------------------------------
            // MD5(method:digestURI:MD5(entityBody))
            //-------------------------------------------------------------------
            ha2 = [MD5 digestForString:[NSString stringWithFormat:@"%@:%@:%@", method, uri, [MD5 digestForString:@""]]];
        }
        else
        {
            //-------------------------------------------------------------------
            // MD5(method:digestURI)
            //-------------------------------------------------------------------
            ha2 = [MD5 digestForString:[NSString stringWithFormat:@"%@:%@", method, uri]];
        }

        if (_qopType)
        {
            //-------------------------------------------------------------------
            // MD5(HA1:nonce:nonceCount:clientNonce:qop:HA2)
            //-------------------------------------------------------------------
            response = [MD5 digestForString:[NSString stringWithFormat:@"%@:%@:%08ld:%@:%@:%@", ha1, _nonce, (long)_requestCounter, cnonce, _qopType, ha2]];
        }
        else
        {
            //-------------------------------------------------------------------
            // MD5(HA1:nonce:HA2)
            //-------------------------------------------------------------------
            response = [MD5 digestForString:[NSString stringWithFormat:@"%@:%@:%@", ha1, _nonce, ha2]];
        }

        //-------------------------------------------------------------------
        // Add the digest Authorization header
        //-------------------------------------------------------------------

        NSString *header = [NSString stringWithFormat:@"Authorization: Digest username=\"%@\", realm=\"%@\", nonce=\"%@\", uri=\"%@\", nc=%08ld, cnonce=\"%@\", response=\"%@\"", _username, _realm, _nonce, uri, (long)_requestCounter, cnonce, response];

        if (_qopType)
        {
            header = [header stringByAppendingFormat:@", qop=\"%@\"", _qopType];
        }

        if (_opaque)
        {
            header = [header stringByAppendingFormat:@", opaque=\"%@\"", _opaque];
        }

        request = [request stringByAppendingFormat:@"\r\n%@", header];
    }
    //-------------------------------------------------------------------
    // If we don't have digest info, but there is a user/password
    // always add the basic Authorization header
    //-------------------------------------------------------------------
    else if (_username && _password)
    {
#if ((TARGET_OS_MAC || GNUSTEP) && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || LION_ELEMENTS))
        NSString *authHeader = [NSString stringWithFormat:@"Authorization: Basic %@", [NSData base64EncodedString:[NSString stringWithFormat:@"%@:%@", _username, _password]]];
#else
        NSString *authHeader = [NSString stringWithFormat:@"Authorization: Basic %@", [[[NSString stringWithFormat:@"%@:%@", _username, _password] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]];
#endif
        request = [request stringByAppendingFormat:@"\r\n%@", authHeader];
    }

    RPMLogDebug(@"Camera (%@) request sent: %@", self.cameraName, request);

    [_duplexStream writeString:[request stringByAppendingString:@"\r\n"]];
}

/**
 *  The stream is configured to read for lines and has read a complete line.
 *
 *  @param stream   The stream.
 *  @param lineData The line data, not including the line delimiter.
 */
- (void)stream:(rpmDuplexStream *)stream didReadLineData:(NSData *)lineData
{
    //-------------------------------------------------------------------
    // If the data is a string, it's not image data (probably headers)
    //-------------------------------------------------------------------
    NSString *header = [[[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding] autorelease];

    //-------------------------------------------------------------------
    // This is an MJPG stream and we finished a section
    // We should have a complete image
    //-------------------------------------------------------------------
    if (header && _boundary && [header hasSuffix:_boundary])
    {
        if (_fetchingImage)
        {
            [self receivedImageUpdate:_fetchingImage];

            _fetchStartTime = [[NSDate date] timeIntervalSince1970];

            [_fetchingImage release];
            _fetchingImage = nil;
        }

        //-------------------------------------------------------------------
        // Wait for the next CRLF before continuing
        //-------------------------------------------------------------------
        _hasHeaders = NO;

        return;
    }

    if (!_hasHeaders)
    {
        //-------------------------------------------------------------------
        // We never received headers for this connection, bail out and try again
        //-------------------------------------------------------------------
        if (!header)
        {
            RPMLogErr(@"Camera (%@) failed to receive headers for url: %@", self.cameraName, self.imagePath);

            [self failedToFetchImage];
            return;
        }

        //-------------------------------------------------------------------
        // When we receive a blank line, we know headers are complete
        //-------------------------------------------------------------------
        if ([header length])
        {
            //-------------------------------------------------------------------
            // Status code received
            //-------------------------------------------------------------------
            if ([header hasPrefix:@"HTTP"])
            {
                NSArray *components = [header componentsSeparatedByString:@" "];
                if ([components count] >= 2)
                {
                    _statusCode = [[components objectAtIndex:1] integerValue];

                    [self streamReceivedStatusCode:_statusCode];
                }
            }
            //-------------------------------------------------------------------
            // Authentication was requested
            //-------------------------------------------------------------------
            else if ([header hasPrefix:@"WWW-Authenticate: "])
            {
                [self authenticate:header];
            }
            //-------------------------------------------------------------------
            // Boundary data received, this is a multipart stream (MJPG)
            //-------------------------------------------------------------------
            else if ([header rangeOfString:@"boundary="].location != NSNotFound)
            {
                NSArray *components = [header componentsSeparatedByString:@"boundary="];

                if ([components count] == 2)
                {
                    [_boundary release];
                    _boundary = [[components lastObject] retain];

                    RPMLogDebug(@"Camera (%@) is MJPG stream with boundary string %@", self.cameraName, _boundary);
                }
            }
            //-------------------------------------------------------------------
            // space before equals seen in Panasonic WJ-GXE100
            //-------------------------------------------------------------------
            else if ([header rangeOfString:@"boundary ="].location != NSNotFound)
            {
                NSArray *components = [header componentsSeparatedByString:@"boundary ="];
                
                if ([components count] == 2)
                {
                    [_boundary release];
                    _boundary = [[components lastObject] retain];
                    
                    RPMLogDebug(@"Camera (%@) is MJPG stream with boundary  string %@", self.cameraName, _boundary);
                }
            }
            //-------------------------------------------------------------------
            // Content is JPEG
            //-------------------------------------------------------------------
            else if ([header hasPrefix:@"Content-Type: image/jpeg"])
            {
                _foundJPEG = YES;
            }
            else if ([header hasPrefix:@"Content-Length: "])
            {
                NSString * contentLengthString = [header substringFromIndex:[@"Content-Length: " length]];
                NSInteger contentLength = [contentLengthString integerValue];
               
                if(contentLength >0 )
                {
                    [stream setContentLength:contentLength];
                }
            }
        }
        else
        {
            if([stream contentLength]>0 && _foundJPEG)
            {
                [stream setCheckJPEG:YES];
            }
            _hasHeaders = YES;
        }
    }
    //-------------------------------------------------------------------
    // Anything that's not a header is treated as image data
    // New data is appended until end of stream or the next boundary marker
    //-------------------------------------------------------------------
    else
    {
        if (!_fetchingImage)
        {
            _fetchingImage = [[NSMutableData alloc] init];
        }

        if ([_fetchingImage length])
        {
            [_fetchingImage appendBytes:"\x0d\x0a" length:2];
        }

        [_fetchingImage appendData:lineData];
    }
}

- (void)stream:(rpmDuplexStream *)stream didCloseWithError:(NSError *)error
{
    if ([_registeredUIs count])
    {
        //-------------------------------------------------------------------
        // The stream closed unexpectedly
        //-------------------------------------------------------------------
        if (error)
        {
            RPMLogErr(@"Camera (%@) stream closed with error %@ (%ld)", self.cameraName, [error localizedDescription], (long)[error code]);

            [self failedToFetchImage];
        }
        else
        {
            //-------------------------------------------------------------------
            // Fetch any remaining data from the stream
            //-------------------------------------------------------------------
            NSData *remainingData = [stream unreadData];
            NSData *imageData = nil;

            if ([_fetchingImage length])
            {
                [_fetchingImage appendBytes:"\x0d\x0a" length:2];
                [_fetchingImage appendData:remainingData];

                imageData = _fetchingImage;
            }
            else
            {
                NSString *header = [[[NSString alloc] initWithData:remainingData encoding:NSUTF8StringEncoding] autorelease];
                if (!header)
                {
                    imageData = remainingData;
                }
                else if ([remainingData length])
                {
                    RPMLogErr(@"Camera (%@) received non-image data %@", self.cameraName, header);
                }
            }

            if ([imageData length])
            {
                [self receivedImageUpdate:imageData];
            }
            else if ([remainingData length])
            {
                [self failedToFetchImage];
            }
        }
    }

    [self cleanup];
}

- (void)streamDidCloseWithTimeout:(rpmDuplexStream *)stream
{
    RPMLogErr(@"Camera (%@) timed out during stream open", self.cameraName);

    [self failedToFetchImage];
}

- (void)streamReceivedStatusCode:(NSInteger)statusCode
{
    //-------------------------------------------------------------------
    // These are server failures
    //-------------------------------------------------------------------
    if (statusCode >= 400 || statusCode < 200)
    {
        RPMLogErr(@"Camera (%@) received server error %ld", self.cameraName, (long)statusCode);

        [self failedToFetchImage];
    }
    //-------------------------------------------------------------------
    // TODO: Received a redirection request, should we handle this?
    //-------------------------------------------------------------------
    else if (statusCode >= 300)
    {
        RPMLogErr(@"Camera (%@) returned redirection request, treating as failure %ld", self.cameraName, (long)statusCode);

        [self failedToFetchImage];
    }
    else
    {
        RPMLogDebug(@"Camera (%@) received successful status code: %ld", self.cameraName, (long)statusCode);
    }
}

#pragma mark - Helpers

- (NSData *)stripTrailingBytes:(NSData *)data
{
    NSData *searchData = [NSData dataWithBytes:"\xff\xd9" length:2];
#ifdef GNUSTEP
    NSRange endRange = [data rangeOfData:searchData range:NSMakeRange(0, [data length])];
#else
    NSRange endRange = [data rangeOfData:searchData options:NSDataSearchBackwards range:NSMakeRange(0, [data length])];
#endif

    if (endRange.location != NSNotFound)
    {
        data = [data subdataWithRange:NSMakeRange(0, endRange.location + endRange.length)];
    }

    return data;
}

- (BOOL)isValidJpegData:(NSData *)data
{
    BOOL ret = NO;

    if ([data length] >= 2)
    {
        NSUInteger totalBytes = [data length];
        const unsigned char *bytes = [data bytes];

        ret = (bytes[0] == 0xff &&
               bytes[1] == 0xd8 &&
               bytes[totalBytes-2] == 0xff &&
               bytes[totalBytes-1] == 0xd9);
    }

    return ret;
}

#pragma mark - Result Handling

- (void)receivedImageUpdate:(NSData *)imageData
{
    RPMLogDebug(@"Camera (%@) received image update", self.cameraName);

    //-------------------------------------------------------------------
    // Some cameras return multiple null bytes after the image data wich need to be pruned
    //-------------------------------------------------------------------
    imageData = [self stripTrailingBytes:imageData];

    if ([self isValidJpegData:imageData])
    {
        NSDate *currentTime = [NSDate date];

        @synchronized(_registeredUIs)
        {
            for (id <RPMSecurityCameraFetcherDelegate> observer in [[_registeredUIs copy] autorelease])
            {
                NSMutableDictionary *observerData = [_registeredUIs objectForKey:observer];

                if ([currentTime timeIntervalSinceDate:[observerData objectForKey:SecurityCameraLastTransfer]] > [[observerData objectForKey:SecurityCameraFrequency] floatValue])
                {
                    if ([observer respondsToSelector:@selector(waitForTransferCompletion)] && [observer waitForTransferCompletion])
                    {
                        // transfer in progress
                        if (![[observerData objectForKey:SecurityCameraTransferComplete] boolValue])
                        {
                            continue;
                        }
                    }

                    [observer didReceiveImageData:[[imageData copy] autorelease] fromFetcher:self];
                    [observerData setObject:currentTime forKey:SecurityCameraLastTransfer];
                    [observerData setObject:[NSNumber numberWithBool:NO] forKey:SecurityCameraTransferComplete];
                }
            }
        }

        [self finish];
    }
    else
    {
        RPMLogErr(@"Camera (%@) received invalid JPEG data", self.cameraName);

        [self failedToFetchImage];
    }
}

- (void)fetchTimedOut
{
    RPMLogErr(@"Camera (%@) Fetch timed out for url: %@", self.cameraName, self.imagePath);

    [self failedToFetchImage];
}

- (void)finish
{
    [self finishAndWait:0];
}

- (void)finishAndWait:(NSTimeInterval)delay
{
    [_fetchingImage release];
    _fetchingImage = nil;

    [_timeoutTimer invalidate];
    _timeoutTimer = nil;

    [_imageUpdate invalidate];
    _imageUpdate = nil;

    RPMLogDebug(@"Camera (%@) completed fetch in %f seconds", self.cameraName, [[NSDate date] timeIntervalSince1970] - _fetchStartTime);

    //-------------------------------------------------------------------
    // This is a JPG stream or we disconnected, we need to fetch the next frame
    //-------------------------------------------------------------------
    if (!_boundary || !_duplexStream.isConnected)
    {
        [_duplexStream close];

        if (!delay)
        {
            NSTimeInterval frequencyWithFetchTimeOffset = _frequency - _fetchStartTime;
            NSTimeInterval frequency = .01; // frames shouldn't ever be fetched faster than 60FPS

            if (frequencyWithFetchTimeOffset > .01)
            {
                frequency = frequencyWithFetchTimeOffset;
            }

            _imageUpdate = [NSTimer scheduledTimerWithTimeInterval:frequency target:self selector:@selector(_fetchImage) userInfo:nil repeats:NO];
        }
        else
        {
            _imageUpdate = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(_fetchImage) userInfo:nil repeats:NO];
        }
    }
}

- (void)failedToFetchImage
{
    for (id <RPMSecurityCameraFetcherDelegate> observer in _registeredUIs)
    {
        if ([observer respondsToSelector:@selector(failedToFetchImageDataFromFetcher:)])
        {
            [observer failedToFetchImageDataFromFetcher:self];
        }
    }

    RPMLogErr(@"Camera (%@) failed to fetch image, retrying in 5 seconds", self.cameraName);

    [self finishAndWait:5];
}

@end
