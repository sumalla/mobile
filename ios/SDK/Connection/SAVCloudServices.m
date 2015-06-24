//
//  SAVCloudServices.m
//  SavantControl
//
//  Created by Cameron Pulsford on 8/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVCloudServices.h"
#import "SAVControlPrivate.h"
#import "SAVCredentialManager.h"
#import <CommonCrypto/CommonHMAC.h>
#import "rpmSharedLogger.h"
#import "SavantPrivate.h"
@import Extensions;

static NSString *const SAVCloudServicesBaseAPIUrl = @"edge/api";
static NSString *const SAVCloudClientIDKey = @"SAVCloudClientIDKey";
static NSString *const SAVCloudClientIDURLKey = @"SAVCloudClientIDURLKey";
static NSString *const SAVCloudPushNotificationIDKey = @"SAVCloudPushNotificationIDKey";


@interface SAVCloudServices () <NSURLSessionDelegate>

@property NSString *email;
@property NSString *password;

@end

//-------------------------------------------------------------------
// Never change the key.
//-------------------------------------------------------------------
static NSString *const SAVCloudServicesCacheKey = @"SAVImageModelCacheKey";

//-------------------------------------------------------------------
// Update the cache version if something major changes that warrants
// invalidating the cache.
//-------------------------------------------------------------------
static NSUInteger const SAVCloudServicesCacheVersion = 1;

@implementation SAVCloudServices

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [NSUserDefaults sav_updateCacheVersion:SAVCloudServicesCacheVersion forKey:SAVCloudServicesCacheKey updateBlock:^{
            [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
                [defaults removeObjectForKey:SAVCloudClientIDURLKey];
                [defaults removeObjectForKey:SAVCloudClientIDKey];
            }];
        }];
    }

    return self;
}

- (SCSCancelBlock)loginWithEmail:(NSString *)email password:(NSString *)password completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(email);
    NSParameterAssert(password);
    NSParameterAssert(completionHandler);

    [self invalidateAndCreateSession];

    NSURLRequest *request = [self loginRequestWithEmail:email password:password];

    return [self sendRequest:request success:^(NSDictionary *response) {
        if ([self handleLoginSuccessWithResponse:response email:email password:password])
        {
            completionHandler(YES, nil, nil, NO);
        }
        else
        {
            completionHandler(NO, nil, nil, NO);
        }
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)checkIfEmailExists:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(email);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"GET"
                                                   request:[NSString stringWithFormat:@"users/checkemail?email=%@", email]
                                                      body:nil
                                              requiresAuth:NO];

    return [self sendRequest:request success:^(id response) {
        if ([response isKindOfClass:[NSNumber class]])
        {
            completionHandler(YES, @(![response boolValue]), nil, NO);
        }
        else
        {
            completionHandler(NO, nil, nil, NO);
        }
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (void)signOut
{
    NSString *clientId = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudClientIDKey];

    if ([clientId isKindOfClass:[NSString class]] && [clientId length] && [self.userID length])
    {
        NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                       request:[NSString stringWithFormat:@"users/%@/signout", self.userID]
                                                          body:@{@"clientId": clientId}
                                                  requiresAuth:YES];

        (void)[self sendRequest:request success:^(id response) {
            RPMLogErr(@"Successfully logged out");
        } failure:^(NSError *error, BOOL isHTTPTransportError) {
            RPMLogErr(@"Error logging out: %@", error);
        }];
    }
    else
    {
        RPMLogErr(@"Skipping logout");
    }
}

- (SCSCancelBlock)listHomes:(SCSResponseBlock)responseBlock
{
    NSParameterAssert(responseBlock);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:nil
                                                   request:[NSString stringWithFormat:@"users/%@/homes", self.userID]
                                                      body:nil
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        responseBlock(YES, response, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        responseBlock(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)onboardHostWithHomeID:(NSString *)homeID key:(NSString *)key completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(homeID);
    NSParameterAssert(key);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"homes/%@/onboard", homeID]
                                                      body:@{@"key": key}
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)modifySystemName:(SAVSystem *)system completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(system.homeID);
    NSParameterAssert(system.name);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"homes/%@", system.homeID]
                                                      body:@{@"name": system.name}
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)createUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName acceptsTermsAndConditions:(BOOL)acceptsTermsAndConditions completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(firstName);
    NSParameterAssert(lastName);
    NSParameterAssert(email);
    NSParameterAssert(password);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"POST"
                                                   request:@"users"
                                                      body:@{@"firstName": firstName,
                                                             @"lastName": lastName,
                                                             @"email": email,
                                                             @"password": password,
                                                             @"tsAndCsAccepted": @(acceptsTermsAndConditions)}
                                              requiresAuth:NO];

    return [self sendRequest:request success:^(id response) {
        [Savant credentials].cloudEmail = email;
        [Savant credentials].cloudPassword = password;
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)deleteUserForhostWithUID:(NSString *)uid user:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(uid);
    NSParameterAssert(user.identifier);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"DELETE"
                                                   request:[NSString stringWithFormat:@"homes/%@/users/%@", uid, user.identifier]
                                                      body:@{@"": @""}
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)usersForHostWithUID:(NSString *)uid completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(uid);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:nil
                                                   request:[NSString stringWithFormat:@"homes/%@/users", uid]
                                                      body:nil
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, response, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)requestPasswordResetForEmail:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(email);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"POST"
                                                   request:@"users/password/reset"
                                                      body:@{@"email": email}
                                              requiresAuth:NO];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(YES, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)changePasswordForUserID:(NSString *)userID oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(userID);
    NSParameterAssert(oldPassword);
    NSParameterAssert(newPassword);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"users/%@/password", userID]
                                                      body:@{@"oldPassword": oldPassword, @"newPassword": newPassword}
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)inviteUser:(SAVCloudUser *)user homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"POST"
                                                   request:[NSString stringWithFormat:@"homes/%@/users", homeID]
                                                      body:[user dictionaryRepresentation]
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)modifyUserName:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user.identifier);
    NSParameterAssert(user.firstName);
    NSParameterAssert(user.lastName);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"users/%@", user.identifier]
                                                      body:@{@"firstName": user.firstName, @"lastName": user.lastName}
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)modifyUserPermissions:(SAVCloudUser *)user homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(user);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);

    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"homes/%@/users/%@/permissions", homeID, user.identifier]
                                                      body:[user dictionaryRepresentation][@"permissions"]
                                              requiresAuth:YES];

    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)registerClientNecessary:(BOOL *)necessary completionHandler:(SCSResponseBlock)completionHandler
{
    if ([self isClientIDValid])
    {
        if (necessary)
        {
            *necessary = NO;
        }

        completionHandler(YES, nil, nil, NO);
        return NULL;
    }
    else
    {
        if (necessary)
        {
            *necessary = YES;
        }

        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setValue:[Savant control].deviceFormFactor forKey:@"deviceType"];
        [info setValue:[Savant control].deviceManufacturer forKey:@"manufacturer"];
        [info setValue:[Savant control].deviceModel forKey:@"model"];
        [info setValue:[Savant control].deviceModelVersion forKey:@"modelVersion"];
        [info setValue:[Savant control].deviceOperatingSystem forKey:@"os"];
        [info setValue:[Savant control].deviceOperatingSystemVersion forKey:@"osVersion"];

        BOOL devBuild = NO;
#ifdef DEBUG
        devBuild = YES;
#endif

        [info setValue:@(devBuild) forKey:@"devBuild"];

        NSURLRequest *request = [self urlRequestWithHTTPMethod:@"POST"
                                                       request:@"clients"
                                                          body:info
                                                  requiresAuth:NO];

        return [self sendRequest:request success:^(NSString *response) {
            if ([response isKindOfClass:[NSString class]] && [response length])
            {
                [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
                    [defaults setObject:response forKey:SAVCloudClientIDKey];
                    [defaults setObject:[[Savant control] cloudWebAddress] forKey:SAVCloudClientIDURLKey];
                }];

                completionHandler(YES, nil, nil, NO);
            }
            else
            {
                completionHandler(NO, nil, nil, NO);
            }
        } failure:^(NSError *error, BOOL isHTTPTransportError) {
            completionHandler(NO, nil, error, isHTTPTransportError);
        }];
    }
}

- (SCSCancelBlock)updatePushNotificationToken:(NSString *)token
{
    if (!token)
    {
        return NULL;
    }

    NSString *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudPushNotificationIDKey];

    if (!oldToken || ![token isEqualToString:oldToken])
    {
        //-------------------------------------------------------------------
        // The old token is stale so delete it.
        //-------------------------------------------------------------------
        if (oldToken)
        {
            [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
                [defaults removeObjectForKey:SAVCloudPushNotificationIDKey];
            }];
        }

        if ([self isClientIDValid])
        {
            NSString *clientID = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudClientIDKey];

            NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                           request:@"clients"
                                                              body:@{@"clientId": clientID, @"pushNotificationIdentifier": token}
                                                      requiresAuth:NO];

            return [self sendRequest:request success:^(id response) {

                //-------------------------------------------------------------------
                // Save out the new token.
                //-------------------------------------------------------------------
                [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
                    [defaults setObject:token forKey:SAVCloudPushNotificationIDKey];
                }];

                //-------------------------------------------------------------------
                // If we are currently logged in, log in again to associate the new
                // token with the current user.
                //-------------------------------------------------------------------
                if ([Savant credentials].cloudEmail && [Savant credentials].cloudPassword)
                {
                    [[Savant cloud] loginAsCloudUser:^(BOOL success, id data, NSError *error, BOOL isHTTPTransportError) {
                        ;
                    }];
                }

            } failure:^(NSError *error, BOOL isHTTPTransportError) {
                ;
            }];
        }
    }

    return NULL;
}

- (SCSCancelBlock)registerNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(notification);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"POST"
                                                   request:[NSString stringWithFormat:@"homes/%@/triggers", homeID]
                                                      body:[notification dictionaryRepresentation]
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)unregisterNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(notification.identifier);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"DELETE"
                                                   request:[NSString stringWithFormat:@"homes/%@/triggers/%@", homeID,notification.identifier]
                                                      body:nil
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)editNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(notification.identifier);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"homes/%@/triggers/%@", homeID, notification.identifier]
                                                      body:[notification dictionaryRepresentation]
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)listNotificationTriggersWithHomeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"GET"
                                                   request:[NSString stringWithFormat:@"homes/%@/triggers", homeID]
                                                      body:nil
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, response, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (SCSCancelBlock)setNotification:(SAVNotification *)notification enabled:(BOOL)enabled homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler
{
    NSParameterAssert(notification.identifier);
    NSParameterAssert(homeID);
    NSParameterAssert(completionHandler);
    
    NSURLRequest *request = [self urlRequestWithHTTPMethod:@"PUT"
                                                   request:[NSString stringWithFormat:@"homes/%@/triggers/%@/%@", homeID, notification.identifier, enabled ? @"enable" : @"disable" ]
                                                      body:nil
                                              requiresAuth:YES];
    
    return [self sendRequest:request success:^(id response) {
        completionHandler(YES, nil, nil, NO);
    } failure:^(NSError *error, BOOL isHTTPTransportError) {
        completionHandler(NO, nil, error, isHTTPTransportError);
    }];
}

- (BOOL)attemptReloginWithFailureBlock:(dispatch_block_t)failureBlock {
    BOOL callFailureBlock = YES;
    
    NSString *email = Savant.credentials.cloudEmail;
    NSString *password = Savant.credentials.cloudPassword;
    
    if ([email length] && [password length])
    {
        callFailureBlock = NO;
        RPMLogErr(@"Attempting to re-login");
        NSURLRequest *loginRequest = [self loginRequestWithEmail:email password:password];
        [[self.session dataTaskWithRequest:loginRequest completionHandler:^(NSData *loginData, NSURLResponse *loginResponse, NSError *loginError) {
            //-------------------------------------------------------------------
            // Delay the failure block until the new login request succeeds or fails.
            // Then let the user re-try.
            //-------------------------------------------------------------------
            failureBlock();
            
            NSHTTPURLResponse *loginURLResponse = (NSHTTPURLResponse *)loginResponse;
            
            if (loginURLResponse.statusCode == 200)
            {

                NSDictionary *loginResponseData = [NSJSONSerialization JSONObjectWithData:loginData options:0 error:NULL];
                
                if (loginResponseData)
                {
                    NSDictionary *loginPayloadData = loginResponseData[@"payload"];
                    if ([self handleLoginSuccessWithResponse:loginPayloadData email:email password:password])
                    {
                        RPMLogErr(@"Re-login attempt was successful");
                    }
                    else
                    {
                        RPMLogErr(@"Re-login attempt failed due to bad data");
                    }
                }
                else
                {
                    RPMLogErr(@"Re-login failed due to invalid date: %ld, %@", (long)loginURLResponse.statusCode, loginError);
                }
            }
            else
            {

                RPMLogErr(@"Re-login attempt failed");
            }
        }] resume];
    }
    else
    {
        RPMLogErr(@"Can not attempt to re-login");
    }
    return callFailureBlock;
}

#pragma mark - Private

- (NSURLRequest *)loginRequestWithEmail:(NSString *)email password:(NSString *)password
{
    self.email = email;
    self.password = password;

    NSMutableDictionary *body = [@{@"email": email, @"password": password} mutableCopy];

    NSString *clientID = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudClientIDKey];

    if (clientID)
    {
        body[@"clientId"] = clientID;
    }

    return [self urlRequestWithHTTPMethod:@"POST"
                                  request:@"users/login"
                                     body:body
                             requiresAuth:NO];
}

- (BOOL)handleLoginSuccessWithResponse:(NSDictionary *)response email:(NSString *)email password:(NSString *)password
{
    if ([response isKindOfClass:[NSDictionary class]])
    {
        self.authenticationToken = response[@"token"];
        self.secretKey = response[@"secretKey"];
        self.userID = [NSNull nilOrIdentityFromObject:response[@"id"]];

        if (!self.userID)
        {
            self.userID = [NSNull nilOrIdentityFromObject:response[@"userId"]];
        }

        NSString *firstName = [NSNull nilOrIdentityFromObject:response[@"firstName"]];
        NSString *lastName = [NSNull nilOrIdentityFromObject:response[@"lastName"]];

        NSString *name = nil;

        if ([firstName length] && [lastName length])
        {
            name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        }
        else if ([firstName length])
        {
            name = firstName;
        }
        else if ([lastName length])
        {
            name = lastName;
        }

        SAVCredentialManager *credentialManager = [Savant credentials];

        if ([name length])
        {
            credentialManager.cloudUserName = name;
        }

        credentialManager.cloudAuthenticationToken = self.authenticationToken;
        credentialManager.cloudAuthenticationSecretKey = self.secretKey;
        credentialManager.cloudAuthenticationID = self.userID;
        credentialManager.cloudEmail = email;
        credentialManager.cloudPassword = password;
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)isClientIDValid
{
    NSString *lastURL = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudClientIDURLKey];
    NSString *currentClientID = [[NSUserDefaults standardUserDefaults] objectForKey:SAVCloudClientIDKey];
    
    if (![[[Savant control] cloudWebAddress] isEqualToString:lastURL] || !currentClientID)
    {
        [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
            [defaults removeObjectForKey:SAVCloudClientIDURLKey];
            [defaults removeObjectForKey:SAVCloudClientIDKey];
        }];
        
        return NO;
    }
    else
    {
        return YES;
    }
}

- (NSString *)serviceScheme
{
    return Savant.control.cloudWebScheme;
}

- (NSString *)serviceAddress
{
    return Savant.control.cloudWebAddress;
}

- (NSInteger)servicePort
{
    return Savant.control.cloudWebPort;
}

- (NSString *)serviceRequestBase
{
    return SAVCloudServicesBaseAPIUrl;
}

@end
