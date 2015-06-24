//
//  SAVCloud.h
//  Savant
//
//  Created by Cameron Pulsford on 5/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SAVSystem.h"
#import "SAVCloudUser.h"
#import "SAVCloudBlockTypes.h"

@interface SAVCloud : NSObject

/**
 *  Determine if there are valid cloud credentials.
 *
 *  @return YES if there are valid cloud credentials; otherwise, NO.
 */
- (BOOL)hasCloudCredentials;

/**
 *  Returns the current cloud email or nil.
 *
 *  @return The current cloud email or nil.
 */
- (NSString *)cloudUserEmail;

/**
 *  Create a cloud user.
 *
 *  @param email                     The new users email.
 *  @param password                  The new users password.
 *  @param firstName                 The new users first name.
 *  @param lastName                  The new users last name.
 *  @param acceptsTermsAndConditions Whether or not the user accepted the terms and coniditons.
 *  @param completionHandler         The completion handler.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)createCloudUserWithEmail:(NSString *)email password:(NSString *)password firstName:(NSString *)firstName lastName:(NSString *)lastName acceptsTermsAndConditions:(BOOL)acceptsTermsAndConditions completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Login as a cloud user.
 *
 *  @param email             The users email.
 *  @param password          The users password.
 *  @param completionHandler The completion handler.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)loginAsCloudUserWithEmail:(NSString *)email password:(NSString *)password completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Check if an email exists.
 *
 *  @param email             The email to check.
 *  @param completionHandler The completion handler.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)checkIfEmailExists:(NSString *)email completionHandler:(void (^)(BOOL exists))completionHandler;

/**
 *  Login with the saved cloud credentials.
 *
 *  @param completionHandler The completion handler.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)loginAsCloudUser:(SCSResponseBlock)completionHandler;

/**
 *  Get a list SAVCloudUsers for the current system.
 *
 *  @param completionHandler The completion handler.
 */
- (SCSCancelBlock)cloudUsers:(SCSResponseBlock)completionHandler;

/**
 *  Delete a user.
 *
 *  @param user              The user.
 *  @param completionHandler The completion handler.
 */
- (void)deleteUser:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Reset the password for a cloud user.
 *
 *  @param email             The email to reset.
 *  @param completionHandler The completion handler.
 */
- (void)resetPasswordForEmail:(NSString *)email completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Change the password for a user.
 *
 *  @param userID            The user ID.
 *  @param oldPassword       The old password.
 *  @param newPassword       The new password.
 *  @param completionHandler The completion handler.
 */
- (void)changePasswordWithUserID:(NSString *)userID oldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Invite/modify a user.
 *
 *  @param user              The user.
 *  @param completionHandler The completion handler.
 */
- (void)inviteUser:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Modify a users name. You may only change the current users name.
 *
 *  @param user              The user.
 *  @param completionHandler The completion handler.
 */
- (void)modifyUserName:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Modify a users permissions. You may only change a different users permissions.
 *
 *  @param user              The user.
 *  @param completionHandler The completion handler.
 */
- (void)modifyUserPermissions:(SAVCloudUser *)user completionHandler:(SCSResponseBlock)completionHandler;

/**
 *  Query the latest information for a given homeID.
 *
 *  @param homeID            The homeID.
 *  @param completionHandler The completion handler.
 *
 *  @return A cancel block.
 */
- (SCSCancelBlock)currentInfoForHomeWithHomeID:(NSString *)homeID completionHandler:(SCSResponseBlock)completionHandler;

#pragma mark - Onboarding

/**
 *  Determine whether the given system can be onboarded.
 *
 *  @param system The system.
 *
 *  @return YES if the system can be onboarded; otherwise, NO.
 */
- (BOOL)canOnboardSystem:(SAVSystem *)system;

/**
 *  Onboard the given system.
 *
 *  @param system            The system to onboard.
 *  @param completionHandler The completion handler.
 */
- (void)onboardSystem:(SAVSystem *)system completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

/**
 *  Modify a system/home name.
 *
 *  @param system            The system to rename.
 *  @param completionHandler The completion handler.
 */
- (void)modifySystemName:(SAVSystem *)system completionHandler:(SCSResponseBlock)completionHandler;
 

@end
