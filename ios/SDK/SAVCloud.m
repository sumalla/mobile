//
//  SAVCloud.m
//  Savant
//
//  Created by Cameron Pulsford on 5/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVCloud.h"
#import "SAVCloudServices.h"
#import "SavantPrivate.h"
#import "SAVControlPrivate.h"
@import Extensions;

@implementation SAVCloud

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [Savant scs].authenticationToken = [Savant credentials].cloudAuthenticationToken;
        [Savant scs].secretKey = [Savant credentials].cloudAuthenticationSecretKey;
        [Savant scs].userID = [Savant credentials].cloudAuthenticationID;
    }
    
    return self;
}

- (BOOL)hasCloudCredentials
{
    return [Savant credentials].cloudAuthenticationToken ? YES : NO;
}

- (NSString *)cloudUserEmail
{
    return [Savant credentials].cloudEmail;
}

- (SCSCancelBlock)createCloudUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName acceptsTermsAndConditions:(BOOL)acceptsTermsAndConditions completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(email);
    NSParameterAssert(password);
    NSParameterAssert(firstName);
    NSParameterAssert(lastName);
    return [[Savant scs] createUserWithEmail:email
                                password:password
                               firstName:firstName
                                lastName:lastName
               acceptsTermsAndConditions:acceptsTermsAndConditions
                       completionHandler:completionHandler];
}

- (SCSCancelBlock)loginAsCloudUserWithEmail:(NSString *)email password:(NSString *)password completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(completionHandler);
    NSParameterAssert(email);
    NSParameterAssert(password);
    
    return [[Savant scs] loginWithEmail:email password:password completionHandler:completionHandler];
}

- (SCSCancelBlock)checkIfEmailExists:(NSString *)email completionHandler:(void (^)(BOOL exists))completionHandler
{
    NSParameterAssert(completionHandler);
    NSParameterAssert(email);
    return [[Savant scs] checkIfEmailExists:email completionHandler:^(BOOL success, NSNumber *exists, NSError *error, BOOL isHTTPTransportError) {
        if (success)
        {
            completionHandler([exists boolValue]);
        }
        else
        {
            completionHandler(NO);
        }
    }];
}

- (SCSCancelBlock)loginAsCloudUser:(SCSResponseBlock)completionHandler
{
    return [self loginAsCloudUserWithEmail:[Savant credentials].cloudEmail password:[Savant credentials].cloudPassword completionHandler:completionHandler];
}

- (SCSCancelBlock)cloudUsers:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(completionHandler);
    
    if ([Savant control].isDemoSystem)
    {
        dispatch_async_main(^{
            SAVCloudUser *user1 = [[SAVCloudUser alloc] init];
            user1.email = @"jesse@savant-demo.com";
            user1.name = @"Jesse";
            user1.identifier = @"1";
            user1.hasRemoteAccess = YES;
            user1.canManageUsers = YES;
            
            SAVCloudUser *user2 = [[SAVCloudUser alloc] init];
            user2.email = @"danny@savant-demo.com";
            user2.name = @"Danny";
            user2.identifier = @"2";
            user2.hasRemoteAccess = YES;
            user2.canManageUsers = YES;
            
            SAVCloudUser *user3 = [[SAVCloudUser alloc] init];
            user3.email = @"joey@savant-demo.com";
            user3.name = @"Joey";
            user3.identifier = @"3";
            user3.hasRemoteAccess = YES;
            
            SAVCloudUser *user4 = [[SAVCloudUser alloc] init];
            user4.email = @"d.j.@savant-demo.com";
            user4.name = @"D.J.";
            user4.identifier = @"4";
            user4.hasRemoteAccess = YES;
            
            SAVCloudUser *user5 = [[SAVCloudUser alloc] init];
            user5.email = @"stephanie@savant-demo.com";
            user5.name = @"Stephanie";
            user5.identifier = @"5";
            user5.hasRemoteAccess = YES;
            
            SAVCloudUser *user6 = [[SAVCloudUser alloc] init];
            user6.email = @"michelle@savant-demo.com";
            user6.name = @"Michelle";
            user6.identifier = @"6";
            user6.hasRemoteAccess = YES;
            
            SAVCloudUser *user7 = [[SAVCloudUser alloc] init];
            user7.email = @"kim@savant-demo.com";
            user7.name = @"Kim";
            user7.identifier = @"7";
            
            SAVCloudUser *user8 = [[SAVCloudUser alloc] init];
            user8.email = @"kate@savant-demo.com";
            user8.name = @"Kate";
            user8.identifier = @"8";
            
            completionHandler(YES, [@[user1, user2, user3, user4, user5, user6, user7, user8] sortedArrayUsingComparator:^NSComparisonResult(SAVCloudUser *u1, SAVCloudUser *u2) {
                return [u1.name compare:u2.name options:NSCaseInsensitiveNumericSearch];
            }], nil, NO);
        });
        
        return ^{};
    }
    else if ([Savant control].currentSystem.homeID)
    {
        return [[Savant scs] usersForHostWithUID:[Savant control].currentSystem.homeID completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
            
            NSArray *payload = nil;
            
            if (success)
            {
                payload = [data arrayByMappingBlock:^id(NSDictionary *userDict) {
                    return [[SAVCloudUser alloc] initWithDictionary:userDict];
                }];
            }
            
            completionHandler(success, payload, error, isHTTPTransportError);
        }];
    }
    else
    {
        completionHandler(NO, nil, nil, NO);
        return ^{};
    }
}

- (void)deleteUser:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user.identifier);
    
    if ([Savant control].isDemoSystem)
    {
        completionHandler(YES, nil, nil, NO);
    }
    else if ([Savant control].currentSystem.homeID)
    {
        [[Savant scs] deleteUserForhostWithUID:[Savant control].currentSystem.homeID user:user completionHandler:completionHandler];
    }
    else
    {
        completionHandler(NO, nil, nil, NO);
    }
}

- (void)resetPasswordForEmail:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(email);
    NSParameterAssert(completionHandler);
    
    [[Savant scs] requestPasswordResetForEmail:email completionHandler:completionHandler];
}

- (void)changePasswordWithUserID:(NSString *)userID oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(userID);
    NSParameterAssert(oldPassword);
    NSParameterAssert(newPassword);
    NSParameterAssert(completionHandler);
    
    [[Savant scs] changePasswordForUserID:userID oldPassword:oldPassword newPassword:newPassword completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        
        if (success)
        {
            [self loginAsCloudUserWithEmail:[Savant credentials].cloudEmail password:newPassword completionHandler:completionHandler];
        }
        else
        {
            completionHandler(NO, data, error, isHTTPTransportError);
        }
    }];
}

- (void)inviteUser:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user);
    NSParameterAssert(completionHandler);
    
    if ([Savant control].currentSystem.homeID)
    {
        [[Savant scs] inviteUser:user homeID:[Savant control].currentSystem.homeID completionHandler:completionHandler];
    }
    else
    {
        completionHandler(NO, nil, nil, NO);
    }
}

- (void)modifyUserName:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user);
    NSParameterAssert(completionHandler);
    [[Savant scs] modifyUserName:user completionHandler:completionHandler];
}

- (void)modifyUserPermissions:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user);
    NSParameterAssert(completionHandler);
    
    if ([Savant control].currentSystem.homeID)
    {
        [[Savant scs] modifyUserPermissions:user homeID:[Savant control].currentSystem.homeID completionHandler:completionHandler];
    }
    else
    {
        completionHandler(NO, nil, nil, NO);
    }
}

- (SCSCancelBlock)currentInfoForHomeWithHomeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(homeID);
    
    return [[Savant scs] listHomes:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
        
        BOOL foundSystem = NO;
        
        if (success && [data isKindOfClass:[NSArray class]])
        {
            for (NSDictionary *home in (NSArray *)data)
            {
                if ([home[@"id"] isEqualToString:homeID])
                {
                    foundSystem = YES;
                    completionHandler(YES, home, nil, NO);
                    break;
                }
            }
        }
        
        if (!foundSystem)
        {
            completionHandler(NO, nil, nil, NO);
        }
    }];
}

#pragma mark - Onboarding

- (BOOL)canOnboardSystem:(SAVSystem *)system
{
    return !system.isCloudSystem && (system.homeID && system.onboardKey && [Savant credentials].cloudAuthenticationID && [Savant credentials].cloudAuthenticationSecretKey && [Savant credentials].cloudAuthenticationToken);
}

- (void)onboardSystem:(SAVSystem *)system completionHandler:(void (^)(BOOL success, NSError *error))completionHandler
{
    NSParameterAssert(completionHandler);
    
    if (system.homeID && system.onboardKey)
    {
        [[Savant scs] onboardHostWithHomeID:system.homeID key:system.onboardKey completionHandler:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
            completionHandler(success, error);
            
            if (success)
            {
                if ([[Savant control].connectionManager.system.homeID isEqualToString:system.homeID])
                {
                    [Savant control].admin = YES;
                    [[Savant control].connectionManager promoteCurrentSystemToACloudSystem];
                }
            }
        }];
    }
    else
    {
        completionHandler(NO, nil);
    }
}

- (void)modifySystemName:(SAVSystem *)system completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(system);
    NSParameterAssert(completionHandler);
    [[Savant scs] modifySystemName:system completionHandler:completionHandler];
}

@end
