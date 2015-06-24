//
//  SCUSceneCreationDialog.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAlertView.h"

@class SAVScene;

typedef NS_ENUM(NSUInteger, SCUSceneCreationDialogAction)
{
    SCUSceneCreationDialogActionCapture,
    SCUSceneCreationDialogActionCreate,
};

typedef void (^SCUSceneCreationDialogCallback)(SCUSceneCreationDialogAction action, SAVScene *scene);

@interface SCUSceneCreationDialog : SCUAlertView

@property (nonatomic, copy) SCUSceneCreationDialogCallback sceneCallback;
@property (nonatomic, copy) dispatch_block_t startCaptureCallback;

- (void)captureCompleteWithScene:(SAVScene *)scene;

@end
