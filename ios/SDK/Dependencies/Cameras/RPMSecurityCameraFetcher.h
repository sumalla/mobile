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

@import Foundation;

@protocol RPMSecurityCameraFetcherDelegate;
@class rpmDuplexStream;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
@interface RPMSecurityCameraFetcher : NSObject
{
    NSTimer  *_imageUpdate;
    NSTimer  *_timeoutTimer;
    NSString *_imagePath;
    NSString *_username;
    NSString *_password;
    NSMutableData *_fetchingImage;
    NSString *_cameraName;
    NSTimeInterval _frequency;
    NSMapTable *_registeredUIs;
    NSThread  *_fetchThread;
    NSString *_host;
    NSInteger _port;
    NSTimeInterval _fetchStartTime;
    
    //-------------------------------------------------------------------
    // Camera streaming
    //-------------------------------------------------------------------
    rpmDuplexStream *_duplexStream;
    NSString *_boundary;
    NSInteger _statusCode;

    //-------------------------------------------------------------------
    // Digest Auth Helpers
    //-------------------------------------------------------------------
    NSInteger _requestCounter;
    NSString *_nonce;
    NSString *_realm;
    NSString *_algorithm;
    NSString *_qopType;
    NSString *_opaque;

    BOOL _hasHeaders;
    BOOL _foundJPEG;
}
#pragma clang diagnostic pop

@property (readonly, copy) NSString *imagePath;
@property (readonly, copy) NSString *host;
@property (readonly) NSInteger port;
@property (readonly, copy) NSString *username;
@property (readonly, copy) NSString *password;
@property (readonly, copy) NSString *cameraName;

- (id)initWithPath:(NSString *)imagePath cameraName:(NSString *)name;

/**
 *  Begin receiving image data for observer.
 *
 *  @param frequency FPS @ which to receive image data
 *  @param observer  observer delegate
 */
- (void)fetchWithFrequency:(NSNumber *)frequency forObserver:(id <RPMSecurityCameraFetcherDelegate>)observer;

/**
 *  Stop receiving image data for observer.
 *
 *  @param observer observer delegate
 */
- (void)stopFetchingForObserver:(id <RPMSecurityCameraFetcherDelegate>)observer;

/**
 *  Notify the fetcher that the observer is ready to receive the next frame.
 *
 *  @param observer observer delegate
 */
- (void)transferCompleteForObserver:(id <RPMSecurityCameraFetcherDelegate>)observer;

@end

@protocol RPMSecurityCameraFetcherDelegate <NSObject>

- (void)didReceiveImageData:(NSData *)imageData fromFetcher:(RPMSecurityCameraFetcher *)fetcher;

@optional
- (void)failedToFetchImageDataFromFetcher:(RPMSecurityCameraFetcher *)fetcher;

/**
 *  If the delegate returns YES for this method, the fetcher will wait until the delegate calls -transferCompleteForObserver: 
 *  before sending the next frame, regardless of the requested frequency.
 *
 *  @return BOOL indicating if the fetcher should wait.
 */
- (BOOL)waitForTransferCompletion;

@end
