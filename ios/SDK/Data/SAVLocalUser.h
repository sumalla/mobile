//
//  SAVLocalUser.h
//  SavantControl
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVUser.h"

@interface SAVLocalUser : SAVUser

@property (nonatomic) NSString *accountName;
@property (nonatomic) BOOL requiresAuthentication;

@end
