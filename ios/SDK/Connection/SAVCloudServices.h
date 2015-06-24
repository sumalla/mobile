//
//  SAVCloudServices.h
//  SavantControl
//
//  Created by Cameron Pulsford on 8/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
#import "SAVRestServices.h"

@class SAVCloudUser, SAVNotification, SAVSystem;

@interface SAVCloudServices : SAVRestServices

@property (nonatomic) NSString *authenticationToken;
@property (nonatomic) NSString *secretKey;
@property (nonatomic) NSString *userID;

#pragma mark - Login/out

- (SCSCancelBlock)loginWithEmail:(NSString *)email password:(NSString *)password completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)checkIfEmailExists:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler;

- (void)signOut;

#pragma mark - Home interactions

- (SCSCancelBlock)listHomes:(SCSResponseBlock)responseBlock;

- (SCSCancelBlock)onboardHostWithHomeID:(NSString *)homeID key:(NSString *)key completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)modifySystemName:(SAVSystem *)system completionHandler:(SCSResponseBlock)completionHandler;

#pragma mark - User management

- (SCSCancelBlock)createUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName acceptsTermsAndConditions:(BOOL)acceptsTermsAndConditions completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)deleteUserForhostWithUID:(NSString *)uid user:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)usersForHostWithUID:(NSString *)uid completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)requestPasswordResetForEmail:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)changePasswordForUserID:(NSString *)userID oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)inviteUser:(SAVCloudUser *)user homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)modifyUserName:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)modifyUserPermissions:(SAVCloudUser *)user homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

#pragma mark - Notification management

- (SCSCancelBlock)registerClientNecessary:(BOOL *)necessary completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)updatePushNotificationToken:(NSString *)token;

- (SCSCancelBlock)registerNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)unregisterNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)editNotificationTrigger:(SAVNotification *)notification homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)listNotificationTriggersWithHomeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

- (SCSCancelBlock)setNotification:(SAVNotification *)notification enabled:(BOOL)enabled homeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

@end
