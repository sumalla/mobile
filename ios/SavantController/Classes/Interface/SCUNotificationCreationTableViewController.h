//
//  SCUNotificationCreationTableViewController.h
//  SavantController
//
//  Created by Stephen Silber on 1/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUPassthroughViewController.h"
#import "SCUModelExpandableTableViewController.h"

typedef NS_ENUM(NSInteger, SCUNotificationTransitionType)
{
    SCUNotificationTransitionTypeDefault,
    SCUNotificationTransitionTypeBottom,
    SCUNotificationTransitionTypeTop
};

@class SCUNotificationCreationDataSource, SAVNotification, SCUNotificationCreationViewController;

@interface SCUNotificationCreationTableViewController : SCUModelExpandableTableViewController

- (instancetype)initWithNotification:(SAVNotification *)notification;

@property SCUNotificationCreationDataSource *model;
@property (weak) SCUNotificationCreationViewController *creationVC;
@property (readonly, nonatomic) SCUPassthroughViewController *passthroughVC;

@end