//
//  SCUNotifcationCreationDataSource.m
//  SavantController
//
//  Created by Stephen Silber on 1/21/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

#import <SavantControl/SAVNotification.h>

@interface SCUNotificationCreationDataSource ()

@property (nonatomic) NSArray *dataSource;

@end

@implementation SCUNotificationCreationDataSource

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super init];
    
    if (self)
    {
        self.notification = notification;
    }
    
    return self;
}

- (void)doneEditing
{

}

@end
