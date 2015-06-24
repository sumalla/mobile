//
//  SCUGenericMediaServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGenericMediaServiceViewController.h"
#import "SCUAVNavigationViewController.h"
#import "SCUAVNumberPadViewController.h"
#import "SCUOverflowTableViewController.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUButton.h"

@implementation SCUGenericMediaServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCUAVNavigationViewController class]) alloc] initWithService:self.service];
    [(SCUAVNavigationViewController *)navigationVC setHideBottomBar:YES];
    
    SCUOverflowTableViewController *tableViewController = [[SCUOverflowTableViewController alloc] initWithService:self.service];
    SCUOverflowDummyViewController *overlayVC = [[SCUOverflowDummyViewController alloc] initWithService:self.service
                                                                                 andTableViewController:tableViewController];
    
    self.defaultVC = navigationVC;
    
    overlayVC.tabController = self;
    
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
