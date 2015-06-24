//
//  SCUSecurityModelPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityModel.h"
#import "SCUStateReceiver.h"

#import <SavantControl/SavantControl.h>

static NSString *const SCUSecurityKeyPartition    = @"SCUSecurityKeyPartition";
static NSString *const SCUSecurityKeySensor       = @"SCUSecurityKeySensor";
static NSString *const SCUSecurityKeyService      = @"SCUSecurityKeyService";
static NSString *const SCUSecurityKeyUserSecurity = @"SCUSecurityKeyUserSecurity";
static NSString *const SCUSecurityKeyIdentifier   = @"SCUSecurityKeyIdentifier";

static NSString *const SCUUserSecurityIdentifer   = @"SVC_ENV_USERLOGIN_SECURITYSYSTEM";
static NSString *const SCUSecurityIdentifer       = @"SVC_ENV_SECURITYSYSTEM";

@interface SCUSecurityModel () <SCUStateReceiver>

@property NSDictionary *securityEntities;
@property NSString *currentSystem;

@property NSHashTable *unknownSensorsTable;
@property NSHashTable *readySensorsTable;
@property NSHashTable *troubleSensorsTable;
@property NSHashTable *criticalSensorsTable;

@property BOOL isOnScreen;

- (void)cleanup;

@end