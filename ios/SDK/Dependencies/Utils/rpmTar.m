//
//  rpmTar.m
//  tarTest
//
//  Created by ncipollo on 2/11/09.
//  Copyright 2009 Savant LLC. All rights reserved.
//

//##OBJCLEAN_SKIP##

#import "rpmTar.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"


@interface rpmTar (private)
//Process the different kinds of data.
-(BOOL)processHeader:(NSData*)header;
-(BOOL)processLongNameData:(NSData*)longName;
-(BOOL)processFileData:(NSData*)fileData;
//Create the file and file handle
-(void)createTheFile;
@end



@implementation rpmTar

- (id) init
{
    self = [super init];
    if (self != nil) 
    {
        _header = [ [NSMutableData alloc] init];
        _longNameData = [ [NSMutableData alloc] init];
        
        _currentState = TAR_HEADER_BLOCK;
        _outputPath = [@"/" retain];
    }
    return self;
}


-(id)initWithOutputPath:(NSString*)path
{
    self = [super init];
    if (self != nil) 
    {
        _header = [ [NSMutableData alloc] init];
        _longNameData = [ [NSMutableData alloc] init];
        
        _currentState = TAR_HEADER_BLOCK;
        _outputPath = [path retain];
    }
    return self;         
}

- (void) dealloc
{
    [_outputPath release];
    _outputPath = nil;
    
    [_header release];
    _header = nil;
    
    [_longNameData release];
    _longNameData = nil;
    
    [_file closeFile];
    [_file release];
    _file = nil;
    
    [_fileName release];
    _fileName = nil;
    
    [_error release];
    _error = nil;
    
    [super dealloc];
}


-(BOOL)processBlock:(NSData*)block
{
    NSAutoreleasePool *localPool = [ [NSAutoreleasePool alloc] init];
    BOOL retVal = NO;
    //When we are dealing with a new file, reset everything
    if(_newFile)
    {        
        [_header release];
        _header = nil;
        
        [_longNameData release];
        _longNameData = nil;
        
        [_file closeFile];
        [_file release];
        _file = nil;
        
        [_fileName release];
        _fileName = nil;
        _dataPos = 0;
        _datasize = 0;
        _isDir = NO;
                
        _currentState = TAR_HEADER_BLOCK;
        _newFile = NO;
    }
    
    //clear any errors before we go again
    if(_error)
    {
        [_error release];
        _error = nil;
    }
    
    //The tar processing state machine
    switch(_currentState)
    {
        case TAR_HEADER_BLOCK:
        retVal = [self processHeader:block];
        break;
        
        case TAR_LONGNAME_DATA_BLOCK:
        retVal = [self processLongNameData:block];
        break;
        
        case TAR_FILE_DATA_BLOCK:
        retVal = [self processFileData:block];
        break; 
    }
    [localPool release];
    return(retVal);
}

-(BOOL)processHeader:(NSData*)header
{
    BOOL isLongLinked = NO;
    NSString *tenativeName = nil;
    //If the header is malformed continue
    if([header length] != 512)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_HEADER_BADSIZE 
                                 userInfo:[NSDictionary dictionaryWithObject:@"The header block was not 512 bytes." forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        _newFile = YES;
        return NO;
    }
    
    //Get the tar header and setup ivars
    tarHeaderStruct *tarHeader = (tarHeaderStruct*)[header bytes];
    
    //Check for empty frame
    if(tarHeader->name[0] == 0)
    {
        //Just continue on until we catch a frame which could be real.
        _newFile = YES;
        return YES;
    }
    
    _datasize = strtoul(tarHeader->size, nil, 8);
    
    _isDir = (tarHeader->linkflag == '5');
    isLongLinked = (tarHeader->linkflag == 'L');    
    //Only support gnu tar
    NSString *magicString = [NSString stringWithCString:tarHeader->magic encoding:NSASCIIStringEncoding];
    if([magicString length] < 5)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_HEADER_UNSUPPORTEDTARTYPE 
                                 userInfo:[NSDictionary dictionaryWithObject:@"Unsupported Tar format or corrupt frame. Only GNU Tar is supported." forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        _newFile = YES;
        return NO;    
    }
    else if(![ [magicString substringToIndex:5] isEqualToString:@"ustar"])
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_HEADER_UNSUPPORTEDTARTYPE 
                                 userInfo:[NSDictionary dictionaryWithObject:@"Unsupported Tar format or corrupt frame. Only GNU Tar is supported." forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        _newFile = YES;
        return NO;
    }
    
    
    if(!_fileName)
    {
       //if we don't have a file name yet try and extract this from the block
        tenativeName = [ [ [NSString alloc] initWithBytes:tarHeader->name length:100 encoding:NSASCIIStringEncoding] autorelease];
        
        if([tenativeName length] > 0)
        {
            if([tenativeName isEqualToString:TAR_LONGLIST_FILENAME] || isLongLinked)
            {
                //In this case we have a long file name and need to take a seperate logic path. We need to read the next few blocks in order to fabricate the the name;
                _longNameData = [ [NSMutableData alloc] init];
                _dataPos = 0;
                _currentState = TAR_LONGNAME_DATA_BLOCK;
                
            }
            else
            {
                //We have a valid file name. It must have been shorter then 100 bytes. The joys of tar.
                _fileName = [tenativeName retain];
                [self createTheFile];
                _dataPos = 0;
                
                if(_datasize > 0)
                {
                    _currentState = TAR_FILE_DATA_BLOCK;
                }
                else
                {
                    _newFile = YES;
                }
            }            
        }   
        else
        {
            _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:ERROR_HEADER_BADFILENAME 
                                     userInfo:[NSDictionary dictionaryWithObject:@"The file name was empty. This is unsupported." forKey:NSLocalizedFailureReasonErrorKey] ];
            [_error retain];
            _newFile = YES;
        }
    }
    else
    {
        //if we already have a file name then we must have had a long name. Proceed to file reading.
        [self createTheFile];
        _dataPos = 0;
        
        if(_datasize > 0)
        {
            _currentState = TAR_FILE_DATA_BLOCK;
        }
        else
        {
            _newFile = YES;
        }
    }
    
    return YES;
}

-(BOOL)processLongNameData:(NSData*)longName
{
    NSData *subLongName = nil;
    NSRange subLongNameRange;
    uint bytesRead = 0;
    unsigned long remainingBytes = 0;
    
    //Check for block validity
    if([longName length] != 512)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_LONGNAME_BADSIZE 
                                 userInfo:[NSDictionary dictionaryWithObject:@"The long link name frame was not 512 bytes" forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        return NO;
    }
    //Check that we are in a valid frame
    if(_dataPos > _datasize)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_LONGNAME_BADFRAME 
                                 userInfo:[NSDictionary dictionaryWithObject:@"Bad long link frame. Trying to read out of bounds data." forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        return NO;
    }
    
    //Append the correct amount of data.
    remainingBytes = _datasize - _dataPos;
    if(remainingBytes > 512)
    {        
        subLongName = longName;
        bytesRead = 512;
    }
    else
    {
        bytesRead = (uint)remainingBytes;
        subLongNameRange.location = 0;
        subLongNameRange.length = bytesRead;
        subLongName = [longName subdataWithRange:subLongNameRange];
    }
    
    [_longNameData appendData:subLongName];
    
    _dataPos += bytesRead;
    
    if(_dataPos >= _datasize)
    {
        _currentState = TAR_HEADER_BLOCK; //The next thing we should see is a header
        if(_fileName)
        {
            [_fileName release];
            _fileName = nil;
        }
        
         _fileName = [ [NSString alloc] initWithBytes:[_longNameData bytes] length:[_longNameData length] encoding:NSASCIIStringEncoding];
        
    }
    return YES;
}

-(BOOL)processFileData:(NSData*)fileData
{
    NSData *subFileData = nil;
    NSRange subFileDataRange;
    uint bytesRead = 0;
    unsigned long remainingBytes = 0;
    
    //Check for block validity
    if([fileData length] != 512)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_FILEDATA_BADSIZE 
                                 userInfo:[NSDictionary dictionaryWithObject:@"The file data frame was not 512 bytes" forKey:NSLocalizedFailureReasonErrorKey] ];
        [_error retain];
        return NO ;
    }
    //Check that we are in a valid frame
    if(_dataPos > _datasize)
    {
        _error = [NSError errorWithDomain:RPMTAR_ERROR_DOMAIN code:RPMTAR_ERROR_FILEDATA_BADFRAME 
                                 userInfo:[NSDictionary dictionaryWithObject:@"Bad file data frame. Trying to read out of bounds data." forKey:NSLocalizedFailureReasonErrorKey] ];
        
        [_error retain];
        return NO;
    }
    
    //Append the correct amount of data.
    remainingBytes = _datasize - _dataPos;
    if(remainingBytes > 512)
    {        
        subFileData = fileData;
        bytesRead = 512;
    }
    else
    {
        bytesRead = (uint)remainingBytes;
        subFileDataRange.location = 0;
        subFileDataRange.length = bytesRead;
        subFileData = [fileData subdataWithRange:subFileDataRange];
    }
    
    [_file writeData:subFileData];
    
    _dataPos += bytesRead;
    
    if(_dataPos >= _datasize)
    {
        _currentState = TAR_HEADER_BLOCK; //The next thing we should see is a header
        _newFile = YES;//And it will be the header of a new file.
        
    }
    
    return YES;
    
}


-(void)createTheFile
{
    NSString *fullPath = [_outputPath stringByAppendingPathComponent:_fileName];
    BOOL isDirectory;
    if([ [NSFileManager defaultManager] fileExistsAtPath:[fullPath stringByDeletingLastPathComponent] ])
    {
        if([ [NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory])
        {
            if(!isDirectory)
            {
                [ [NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                [[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
            }
        }
        else
        {
            if(_isDir)
            {
				[ [NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            else
            {
                [[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
            }
        }
    }
    else
    {
        if(_isDir)
        {
			[ [NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        else
        {
			[ [NSFileManager defaultManager] createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            [[NSFileManager defaultManager] createFileAtPath:fullPath contents:nil attributes:nil];
        }
    }
    
    
    if(!_isDir)
    {
        if(_file)
        {
            [_file closeFile];
            [_file release];
            _file = nil;
        }
        
        _file = [ [NSFileHandle fileHandleForWritingAtPath:fullPath] retain];
    }
    
}

-(NSError*)error
{
    return(_error);
}

@end

//##OBJCLEAN_ENDSKIP##
#pragma clang diagnostic pop
