//
//  SCUSurveillanceServiceViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSurveillanceServiceViewController.h"
#import "SCUSurveillanceNavigationViewController.h"
#import "SCUSurveillanceNumberPadViewController.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowTableViewController.h"

@implementation SCUSurveillanceServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCUSurveillanceNavigationViewController class]) alloc] initWithService:self.service];
    SCUOverflowTableViewController *tableViewController = [[SCUOverflowTableViewController alloc] initWithService:self.service];
    SCUOverflowDummyViewController *overlayVC = [[SCUOverflowDummyViewController alloc] initWithService:self.service
                                                                                                         andTableViewController:tableViewController];

    self.defaultVC = navigationVC;

    if ([UIDevice isPad])
    {
        self.viewControllers = @[navigationVC, overlayVC];
    }
    else
    {
        SCUServiceViewController *numberPadVC = [[DeviceClassFromClass([SCUSurveillanceNumberPadViewController class]) alloc] initWithService:self.service];
        self.viewControllers = @[navigationVC, numberPadVC, overlayVC];
    }
}

@end
