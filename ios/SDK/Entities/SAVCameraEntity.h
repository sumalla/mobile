//
//  SAVCameraEntity.h
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import UIKit;
#import "SAVEntity.h"

typedef NS_ENUM(NSInteger, SAVCameraEntityFormat)
{
    SAVCameraEntityFormat_Unknown = -1,
    SAVCameraEntityFormat_JPG,
    SAVCameraEntityFormat_MJPG,
    SAVCameraEntityFormat_H264
};

typedef NS_OPTIONS(NSUInteger, SAVCameraEntityScale)
{
    SAVCameraEntityScale_Preview = 1 << 0,
    SAVCameraEntityScale_Fullscreen = 1 << 1,
};

typedef NS_ENUM(NSInteger, SAVCameraEntityFetchState)
{
    SAVCameraEntityFetchState_Unknown = -1,
    SAVCameraEntityFetchState_Stopped,
    SAVCameraEntityFetchState_Local,
    SAVCameraEntityFetchState_Remote
};

@protocol SAVCameraEntityDelegate;

@interface SAVCameraEntity : SAVEntity

@property NSURL *previewURL;
@property NSURL *fullscreenURL;

@property SAVCameraEntityFormat previewFormat;
@property SAVCameraEntityFormat fullscreenFormat;

@property NSTimeInterval previewFramerate;
@property NSTimeInterval fullscreenFramerate;

@property BOOL inGlobalZone;

@property (readonly) SAVCameraEntityFetchState previewFetchState;
@property (readonly) SAVCameraEntityFetchState fullscreenFetchState;

@property (nonatomic, readonly) BOOL hasPTZ;

- (void)startPreviewStream;
- (void)stopPreviewStream;
- (void)startFullscrenStream;
- (void)stopFullscreenStream;

- (void)addObserver:(id <SAVCameraEntityDelegate>)observer;
- (void)removeObserver:(id <SAVCameraEntityDelegate>)observer;

/**
 * Returns the format type from a string.
 *
 * @param formatString A string representing the format
 * @return An SAVCameraEntityFormat representing the format or SAVCameraEntityFormat_Unknown if it is not a valid format string.
 */
- (SAVCameraEntityFormat)formatFromString:(NSString *)formatString;

- (SAVCameraEntityFetchState)fetchStateForScale:(SAVCameraEntityScale)scale;

@end

@protocol SAVCameraEntityDelegate <NSObject>

- (void)receivedImage:(UIImage *)image ofScale:(SAVCameraEntityScale)scale fromEntity:(SAVCameraEntity *)entity;

@end
