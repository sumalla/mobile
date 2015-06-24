//
//  rpmDuplexStream.h
//  SavantMediaQuery
//
//  Created by Cameron Pulsford on 9/30/12.
//  Copyright (c) 2012  Savant Systems, LLC. All rights reserved.
//

//##OBJCLEAN_SKIP##

#import <Foundation/Foundation.h>

#ifdef GNUSTEP
#import "rpmGNUStepExtensions.h"
#endif

@protocol rpmDuplexStreamDelegate;

typedef enum
{
    rpmDuplexStreamLineDelimiter_None = 0,
    rpmDuplexStreamLineDelimiter_CR,
    rpmDuplexStreamLineDelimiter_LF,
    rpmDuplexStreamLineDelimiter_CRLF,
} rpmDuplexStreamLineDelimiter_t;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
#ifndef GNUSTEP
@interface rpmDuplexStream : NSObject <NSStreamDelegate>
#else
@interface rpmDuplexStream : NSObject
#endif
{
    id <rpmDuplexStreamDelegate> _delegate;
    
    //-------------------------------------------------------------------
    // Configuration data
    //-------------------------------------------------------------------
    NSHost*          _host;
    NSInteger        _port;
    NSString*        _address;
    BOOL             _wantsStrings;
    NSStringEncoding _stringEncoding;
    NSData*          _lineDelimiter;
    BOOL             _safeDataParsing;
    id               _userInfo;
    BOOL             _checkJPEG;
    NSInteger        _contentLength;
    NSInteger        _dataReceivedLength;


    //-------------------------------------------------------------------
    // Streams
    //-------------------------------------------------------------------
    NSInputStream*  _iStream;
    NSOutputStream* _oStream;
    NSUInteger      _opensCompleted; /* delegate's streamDidOpen: method will not be called until both streams have opened. */
    
    //-------------------------------------------------------------------
    // Buffers
    //-------------------------------------------------------------------
    NSMutableData* _readBuffer;
    NSMutableData* _writeBuffer;

    //-------------------------------------------------------------------
    // Timeout
    //-------------------------------------------------------------------
    NSTimer *_timeoutTimer;
    NSTimeInterval _timeoutTime;
}
#pragma clang diagnostic pop

@property (readwrite, assign) id <rpmDuplexStreamDelegate> delegate;
@property (readwrite, assign) BOOL                         wantsStrings;
@property (readwrite, assign) NSStringEncoding             stringEncoding; // Set to NSUTF8StringEncoding by default.
@property (readwrite, assign) BOOL                         safeDataParsing; // Set to YES by default. NO enables a small optimization.
@property (readwrite, assign) BOOL                         checkJPEG; // Set to NO by default. YES counts image data bytes (HTTP persistent)
@property (readwrite, assign) NSInteger                    contentLength; // used to determine end of the image stream (HTTP persistent)
@property (readwrite, assign) NSInteger                    dataReceivedLength; //count the jpeg data received until contentLength is reached
@property (readwrite, retain) id                           userInfo;
@property (readonly, atomic)  BOOL                         isConnected;
@property (readwrite, assign) NSTimeInterval               timeoutTime; // Set to -1 by default to use NSStream's implicit timeout.

//-------------------------------------------------------------------
//
//   Description
//       Configure the stream.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)configureWithURL:(NSURL *)url;
- (void)configureWithHost:(NSHost *)host port:(NSInteger)port;

//-------------------------------------------------------------------
//
//   Description
//       Set the line delimiter.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)setLineDelimiter:(rpmDuplexStreamLineDelimiter_t)lineDelimiter;

//-------------------------------------------------------------------
//
//   Description
//       Open the stream.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)open;

/**
 *  Returns the data that has yet to be returned to the delegate.
 *  Any data that is read is free'd from the read buffer.
 *
 *  @return unread data
 */
- (NSData *)unreadData;

//-------------------------------------------------------------------
//
//   Description
//       Close the stream.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)close;

//-------------------------------------------------------------------
//
//   Description
//       Write data to the stream and control if a line delimiter is
//       appended. No gurantees are made as to when the data gets
//       written.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)writeData:(NSData *)data appendLineDelimiter:(BOOL)appendLineDelimiter;

//-------------------------------------------------------------------
//
//   Description
//       Write a string to the stream. No gurantees are made as to
//       when the string gets written.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)writeString:(NSString *)string;

//-------------------------------------------------------------------
//
//   Description
//       More efficiently write an array of strings to the stream. No
//       guarantees are made as to when the string gets written.
//   Return Value
//
//   Caveats
//       
//-------------------------------------------------------------------
- (void)writeStrings:(NSArray *)strings;

//-------------------------------------------------------------------
//
//   Description
//       Convert data into a string using the string encoding
//       property. If range is nil the whole string will be
//       converted.
//   Return Value
//       If using the range would raise an out of bounds exception
//       nil is returned instead.
//   Caveats
//
//-------------------------------------------------------------------
- (NSString *)convertDataIntoString:(NSData *)data range:(NSRangePointer)range;

//-------------------------------------------------------------------
//
//   Description
//       These methods call the corresponding delegate methods.
//       Subclasses can override them to intercept different
//       messages, maybe to handle authentication automatically.
//       Calling super is optional.
//   Return Value
//
//   Caveats
//
//-------------------------------------------------------------------
- (void)streamDidOpen;
- (void)streamDidCloseWithError:(NSError *)error;
- (BOOL)streamDidReadPartialData:(NSData *)data; /* returns NO if the delegate is not implemented */
- (void)streamDidReadData:(NSData *)data;
- (void)streamDidReadLineData:(NSData *)lineData;
- (void)streamDidReadLineString:(NSString *)lineString;

@end

@protocol rpmDuplexStreamDelegate <NSObject>

@optional

/**
 *  The stream opened.
 *
 *  @param stream The stream.
 */
- (void)streamDidOpen:(rpmDuplexStream *)stream;

/**
 *  The stream closed with an error.
 *
 *  @param stream The stream.
 *  @param error  The error, or nil when unavailable.
 */
- (void)stream:(rpmDuplexStream *)stream didCloseWithError:(NSError *)error;

/**
 *  The stream is configured to read for lines, but a read completed and no lines were found.
 *
 *  @param stream The stream.
 *  @param data   The partial line data that was read.
 *
 *  @return YES if you would like to handle this data and flush the internal buffer, or NO to wait for the line to complete.
 */
- (BOOL)stream:(rpmDuplexStream *)stream didReadPartialData:(NSData *)data;

/**
 *  The stream is not configured to read for lines and has read some data.
 *
 *  @param stream The stream.
 *  @param data   The data that was read.
 */
- (void)stream:(rpmDuplexStream *)stream didReadData:(NSData *)data;

/**
 *  The stream is configured to read for lines and has read a complete line.
 *
 *  @param stream   The stream.
 *  @param lineData The line data, not including the line delimiter.
 */
- (void)stream:(rpmDuplexStream *)stream didReadLineData:(NSData *)lineData;

/**
 *  The stream is configured to read lines and want strings and has read a complete line.
 *
 *  @param stream     The stream.
 *  @param lineString The line string, not including the line delimiter.
 */
- (void)stream:(rpmDuplexStream *)stream didReadLineString:(NSString *)lineString;

/**
 *  The stream closed due to a timeout opening the connection.
 *
 *  @param stream The stream.
 */
- (void)streamDidCloseWithTimeout:(rpmDuplexStream *)stream;

@end

//##OBJCLEAN_ENDSKIP##
