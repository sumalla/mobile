//
//  SAVCloudUser.h
//  SavantControl
//
//  Created by Cameron Pulsford on 8/19/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVUser.h"

@interface SAVCloudUser : SAVUser <NSCopying>

@property (nonatomic) NSString *email;

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *firstName;

@property (nonatomic) NSString *lastName;

@property (nonatomic) NSString *identifier;

@property (nonatomic) NSSet *serviceBlackList;

@property (nonatomic, getter = isCurrentUser) BOOL currentUser;

@property (nonatomic) BOOL hasRemoteAccess;

@property (nonatomic) BOOL canManageUsers;

@property (nonatomic) BOOL canManageNotifications;

@end
