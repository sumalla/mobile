//
//  SCUMoreActionsViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMoreActionsViewModel.h"
#import "SCUSettingsModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUMainViewController.h"
#import "SCUInterface.h"
#import "SCUMoreActionsCell.h"
#import <SavantControl/SavantControlPrivate.h>
#import "SavantControlPrivate.h"

@interface SCUMoreActionsViewModel ()

@property NSArray *dataSource;
@property NSArray *moreActions;
@property (nonatomic, getter = areNotificationsEnabled) BOOL notificationsEnabled;

@end

@implementation SCUMoreActionsViewModel

#pragma mark - SCUDataSourceModel methods

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.notificationsEnabled = NO;
        [self loadData];
    }

    return self;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    [self updateCloudState];
}

- (void)loadData
{
    NSDictionary *notifications = @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"NOTIFICATIONS", nil),
                                    SCUDefaultTableViewCellKeyBorderType: @(SCUDefaultTableViewCellBorderTypeTopPartial),
                                    SCUSettingsKeyAction: NSStringFromSelector(@selector(showNotifications))};
    
    NSDictionary *settings =  @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"SETTINGS", nil),
                                SCUDefaultTableViewCellKeyBorderType: @(SCUDefaultTableViewCellBorderTypeTopPartial),
                                SCUSettingsKeyAction: NSStringFromSelector(@selector(showSettings))};
    
    if ([SavantControl sharedControl].currentSystem.areNotificationsEnabled)
    {
        self.moreActions = @[notifications, settings];
    }
    else
    {
        self.moreActions = @[settings];
    }
    
    self.dataSource = [self parseActions:self.moreActions];
    
    [self.delegate reloadData];
}

- (void)updateCloudState
{
    [[SavantControl sharedControl] cloudHomesWithCompletionHandler:^(BOOL success, NSArray *systems, NSError *error) {
        if (success && [systems count])
        {
            NSString *hostID = [SavantControl sharedControl].currentSystem.hostID;
            
            NSArray *matchingSystem = [systems arrayByMappingBlock:^id(SAVSystem *system) {
                
                if ([system.hostID isEqualToString:hostID])
                {
                    return system;
                }
                
                return nil;
            }];
            
            if ([matchingSystem count])
            {
                SAVSystem *match = [matchingSystem firstObject];
                [SavantControl sharedControl].currentSystem.notificationsEnabled = match.areNotificationsEnabled;
                [self loadData];
            }
        }
    }];
}

- (void)showSettings
{
    [[SCUInterface sharedInstance] presentSettings];
}

- (void)showNotifications
{
    [[SCUInterface sharedInstance] presentNotifications];
}

@end
