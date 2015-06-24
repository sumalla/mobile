//
//  SCUCameraFullScreenViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraFullScreenViewController.h"
#import "SCUButton.h"

#import <SAVCameraEntity.h>

@interface SCUCameraFullScreenViewController ()

@property SAVCameraEntity *entity;
@property UILabel *zoneName;
@property UILabel *cameraName;
@property UIView *panTiltControls;
@property UIView *zoomBrightnessControls;
@property SCUButton *dismissButton;
@property UIImageView *imageView;

@end