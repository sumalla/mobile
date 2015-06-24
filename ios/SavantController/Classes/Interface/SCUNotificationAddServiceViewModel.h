//
//  SCUNotificationAddServiceViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 1/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"
#import "SCUIconSelectView.h"

#import <SavantControl/SAVNotification.h>

@protocol SCUNotificationsAddServiceViewDelegate <NSObject>

- (void)reloadData;

- (void)moveToRuleScreen;

@end

@interface SCUNotificationAddServiceViewModel : SCUNotificationCreationDataSource  <SCUIconSelectViewDelegate>

@property (nonatomic, weak) id<SCUNotificationsAddServiceViewDelegate> delegate;

- (NSString *)titleForHeaderInSection:(NSInteger)section;

- (NSInteger)indexForServiceType:(SAVNotificationServiceType)type;

- (NSArray *)availableServices;

@end
