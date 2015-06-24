//
//  SCUContentViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
@class SCUToolbar, SCUServiceViewController, SCUDrawerViewController, SCURootViewController;
@protocol SCUMainToolbarManager;

@interface SCUContentViewController : UIViewController

@property (readonly) SCUToolbar *mainToolbar;

- (void)presentViewController:(UIViewController <SCUMainToolbarManager> *)vc;

- (void)presentViewController:(UIViewController <SCUMainToolbarManager> *)vc animated:(BOOL)animated;

- (void)presentServiceViewController:(SCUServiceViewController <SCUMainToolbarManager> *)vc animated:(BOOL)animated;

- (void)presentServiceSelector:(UIBarButtonItem *)sender;

@property (nonatomic, readonly, strong) SCUServiceViewController *currentServiceViewController;

@property (nonatomic, readonly, strong) SCUDrawerViewController *currentDrawerViewController;

@property (nonatomic, readonly, strong) SCURootViewController *currentRootviewController;

- (void)leaveServiceScreenAnimated:(BOOL)animated;

@end
