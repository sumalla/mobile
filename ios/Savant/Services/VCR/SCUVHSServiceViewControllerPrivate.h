//
//  SCUVHSServiceViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVHSServiceViewController.h"
#import "SCUButtonViewController.h"
#import "SCUTransportButtonCollectionViewController.h"

@interface SCUVHSServiceViewController ()

@property SCUTransportButtonCollectionViewController *buttonViewController;
@property SCUButtonViewController *transportControls;
@property SCUButtonViewController *eject;
@property UIImageView *vcrImage;

@end