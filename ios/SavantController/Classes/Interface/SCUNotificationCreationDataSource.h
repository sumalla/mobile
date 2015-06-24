//
//  SCUNotifcationCreationDataSource.h
//  SavantController
//
//  Created by Stephen Silber on 1/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@class SAVNotification;

@interface SCUNotificationCreationDataSource : SCUExpandableDataSourceModel

- (instancetype)initWithNotification:(SAVNotification *)notification;

@property (nonatomic) SAVNotification *notification;

@property (nonatomic, readonly) NSArray *dataSource;

@end

@interface SCUNotificationCreationDataSource (Optional)

- (void)doneEditing;

@end
