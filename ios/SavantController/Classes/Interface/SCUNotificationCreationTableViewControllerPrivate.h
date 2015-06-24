//
//  SCUNotificationCreationTableViewControllerPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUNotificationCreationDataSource.h"

#import <SavantControl/SavantControl.h>

@interface SCUNotificationCreationTableViewController ()

- (void)dismissViewController;
- (void)popViewController;
- (void)popViewControllerCanceled;
- (void)popToRootViewController;

@end