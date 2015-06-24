//
//  SCUCredentialManager.h
//  SavantControll
//
//  Created by Cameron Pulsford on 7/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

/**
 *  This class manages user credentials. All operations, except when noted, are implicitly applied to the current system.
 */
@interface SAVCredentialManager : NSObject

/**
 *  This will return the user name of the last person to connect to the current system.
 *  If there is no current system, it will attempt to get the last connected user name of the last connected system.
 */
@property (nonatomic, readonly) NSString *lastConnectedUserName;

/**
 *  This will return the password of the last person to connect to the current system.
 *  If there is no current system, it will attempt to get the password of the last connected user name of the last connected system.
 */
@property (nonatomic, readonly) NSString *lastConnectedPassword;

@property (nonatomic) NSString *cloudAuthenticationToken;

@property (nonatomic) NSString *cloudAuthenticationSecretKey;

@property (nonatomic) NSString *cloudAuthenticationID;

@property (nonatomic) NSString *cloudEmail;

@property (nonatomic) NSString *cloudUserName;

@property (nonatomic) NSString *cloudPassword;

- (NSString *)hostTokenForHomeID:(NSString *)homeID;

- (void)setHostToken:(NSString *)hostToken forHomeID:(NSString *)homeID;

/**
 *  Save a user name and a password against the current system.
 *
 *  @param userName        The user name to save.
 *  @param password        The password to save.
 *  @param persistPassword YES to persist the password; otherwise, NO.
 */
- (void)saveUserName:(NSString *)userName password:(NSString *)password persistPassword:(BOOL)persistPassword;

/**
 *  After trying to use cached credentials, call this to inform the credential manager to save out the new system.
 */
- (void)updateLastConnectedSystem;

/**
 *  Returns the password for the given user on the current system, or nil.
 *
 *  @param user The user whose password you need.
 *
 *  @return The password for the given user on the current system, or nil.
 */
- (NSString *)passwordForUserName:(NSString *)user;

/**
 *  Sign out of all instances.
 */
- (void)signOut;

@end
