//
//  SCUNotificationCreationSendOptionsViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUNotificationCreationSendOptionsViewModel.h"

#import <SavantControl/SAVNotification.h>

@interface SCUNotificationCreationSendOptionsViewModel ()

@property (nonatomic) NSArray *dataSource;

@end


typedef NS_ENUM(NSUInteger, SCUNotificationSendType)
{
    SCUNotificationSendType_Notification,
    SCUNotificationSendType_Email
};

static NSString *const SCUNotificationCreationSendOptionKeyNotificationType = @"SCUNotificationCreationSendOptionKeyNotificationType";

@implementation SCUNotificationCreationSendOptionsViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    
    if (self)
    {
        [self prepareData];
    }
    
    return self;
}

- (void)prepareData
{
    NSArray *dataSource = @[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Notification", nil),
                              SCUNotificationCreationSendOptionKeyNotificationType: @(SCUNotificationSendType_Notification)},
                            @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Email", nil),
                              SCUNotificationCreationSendOptionKeyNotificationType: @(SCUNotificationSendType_Email)}];
    
    self.dataSource = [dataSource copy];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForIndexPath:indexPath] mutableCopy];
    
    switch (indexPath.row)
    {
        case 0:
            // Notification
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = self.notification.isPushDeliveryEnabled ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone);
            break;
        case 1:
            // Email
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = self.notification.isEmailDeliveryEnabled ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone);
    }
    
    return modelObject;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = [self modelObjectForIndexPath:indexPath];
    SCUNotificationSendType type = [modelObject[SCUNotificationCreationSendOptionKeyNotificationType] integerValue];
    switch (type)
    {
        case SCUNotificationSendType_Notification:
            self.notification.pushDeliveryEnabled = !self.notification.isPushDeliveryEnabled;
            break;
        case SCUNotificationSendType_Email:
            self.notification.emailDeliveryEnabled = !self.notification.isEmailDeliveryEnabled;
            break;
    }
    
    [self.delegate reloadRowAtIndexPath:indexPath];
}

@end
