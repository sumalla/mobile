//
//  SCURootViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURootViewController.h"
#import "SCUHomeGridCollectionViewController.h"
#import "SCUServicesFirstContainerViewController.h"
#import "SCUScenesViewController.h"
#import "SCUAVSettingsTableViewController.h"
#import "SCUNotificationCreationViewController.h"
#import "SCUInterface.h"

@implementation SCURootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUHomeGridCollectionViewController *rooms = [[SCUHomeGridCollectionViewController alloc] init];
    SCUServicesFirstContainerViewController *servicesFirst = [[SCUServicesFirstContainerViewController alloc] init];
    SCUScenesViewController *scenes = [[SCUScenesViewController alloc] init];
    SCUAVSettingsTableViewController *settings = [[SCUAVSettingsTableViewController alloc] init];
    SCUNotificationCreationViewController *notifications = [[SCUNotificationCreationViewController alloc] initWithState:SCUNotificationCreationState_NotificationsList andNotification:nil];

    self.viewControllers = @[rooms, servicesFirst, scenes, settings, notifications];

    self.toolbarHeight = 0;

    [self.delegate viewDidLoad];
}

- (NSString *)savedKey
{
    NSString *saveKey = @"rootView";

    if ([self.activeVC isKindOfClass:[SCUAVSettingsTableViewController class]] || [self.activeVC isKindOfClass:[SCUNotificationCreationViewController class]])
    {
        saveKey = nil;
    }
    
    return saveKey;
}

- (void)setActiveVC:(UIViewController *)activeVC
{
    //-------------------------------------------------------------------
    // Clear saved state when changing tabs.
    //-------------------------------------------------------------------
    if (self.activeVC)
    {
        [SCUInterface sharedInstance].currentRoom = nil;
        [SCUInterface sharedInstance].currentService = nil;
    }

    [super setActiveVC:activeVC];
}

@end
