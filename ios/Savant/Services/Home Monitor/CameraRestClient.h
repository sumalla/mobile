//
//  JanusClient.h
//  AppRTCDemo
//
//  Created by Joseph Ross on 2/24/15.
//  Copyright (c) 2015 Savant Systems LLC. All rights reserved.
//

@import UIKit;
#import "SAVVideoView.h"

@class CameraRestClient;

@protocol CameraRestClientDelegate
- (void)cameraRestClientReadyToAttachVideo:(CameraRestClient *)cameraRestClient;
@end

@interface CameraRestClient : NSObject
- (instancetype)initWithDelegate:(NSObject<CameraRestClientDelegate>*)delegate;
- (void)connectToUrl:(NSString*)url;
- (void)hangup;
- (void)attachVideoToView:(SAVVideoView*)videoView;
@end
