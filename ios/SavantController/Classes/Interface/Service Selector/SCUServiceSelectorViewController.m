//
//  SCUServiceSelectorViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceSelectorViewController.h"
#import "SCUServiceSelectorTableViewController.h"
#import "SCUInterface.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUServiceSelectorViewController ()

@end

@implementation SCUServiceSelectorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUServiceSelectorTableViewController *tableViewController = [[SCUServiceSelectorTableViewController alloc] init];

    UIView *view = nil;

    [self sav_addChildViewController:tableViewController];
    view = self.view;

    [view sav_addFlushConstraintsForView:tableViewController.view];
}

@end
