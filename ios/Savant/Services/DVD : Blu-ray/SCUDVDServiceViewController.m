//
//  SCUDVDServiceViewController2.m
//  SavantController
//
//  Created by Stephen Silber on 2/12/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDVDServiceViewController.h"
#import "SCUServiceViewController.h"
#import "SCUAVNumberPadViewController.h"
#import "SCUAVNavigationViewController.h"
#import "SCUPassthroughViewController.h"
#import "SCUOverflowTableViewController.h"
#import "SCUOverflowDummyViewController.h"

@implementation SCUDVDServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCUAVNavigationViewController class]) alloc] initWithService:self.service];
    [(SCUAVNavigationViewController *)navigationVC setHideBottomBar:YES];
    
    SCUOverflowTableViewController *tableViewController = [[SCUOverflowTableViewController alloc] initWithService:self.service];
    SCUServiceViewController *overlayVC = [[DeviceClassFromClass([SCUOverflowDummyViewController class]) alloc] initWithService:self.service andTableViewController:tableViewController];
    
    self.defaultVC = navigationVC;
    
    if ([UIDevice isPad])
    {
        self.viewControllers = @[navigationVC, overlayVC];
    }
    else
    {
        SCUServiceViewController *numberPadVC = [[DeviceClassFromClass([SCUAVNumberPadViewController class]) alloc] initWithService:self.service];
        self.viewControllers = @[navigationVC, numberPadVC, overlayVC];
    }
}

@end
