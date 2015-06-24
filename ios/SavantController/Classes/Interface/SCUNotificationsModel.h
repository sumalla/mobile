//
//  SCUNotificationsModel.h
//  SavantController
//
//  Created by Julian Locke on 1/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

@class SAVNotification;

typedef NS_ENUM(NSUInteger, SCUNotificationsCellType)
{
    SCUNotificationsCellTypeToggle,
    SCUNotificationsCellTypeInvisible,
};

@protocol SCUNotificationsModelDelegate <NSObject>

- (void)reloadData;

- (void)endRefresh;

- (void)presentEditNotification:(SAVNotification *)notification;

- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUNotificationsModel : SCUNotificationCreationDataSource

@property (nonatomic, weak) id<SCUNotificationsModelDelegate> delegate;

- (void)loadData;

- (void)listenToToggleSwitch:(UISwitch *)toggleSwitch forIndexPath:(NSIndexPath *)indexPath;

- (void)deleteAtIndexPath:(NSIndexPath *)indexPath;

@end
 