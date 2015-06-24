//
//  SCUNotificationAddRuleTableViewController.h
//  SavantController
//
//  Created by Stephen Silber on 1/22/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

typedef NS_ENUM(NSUInteger, SCUNotificationsAddServiceRuleType)
{
    SCUNotificationsAddServiceRuleType_Where,
    SCUNotificationsAddServiceRuleType_When,
    SCUNotificationsAddServiceRuleType_Send
};

@protocol SCUNotificationAddRuleViewDelegate <NSObject>

- (void)updateSliderLabel;

- (void)popToRootViewController;

@end

@class SCURangeSlider;

@interface SCUNotificationAddRuleViewModel : SCUNotificationCreationDataSource

- (SCUNotificationsAddServiceRuleType)ruleTypeForIndexPath:(NSIndexPath *)indexPath;

- (NSString *)headerTextForType:(NSUInteger)type;

- (void)saveNotificationWithEditing:(BOOL)editing;

- (void)deleteNotification;

- (void)updateTriggerValuesWithSlider:(SCURangeSlider *)slider;

- (BOOL)displaysScheduleTime;

@property (nonatomic, weak) id<SCUNotificationAddRuleViewDelegate> delegate;

@end
