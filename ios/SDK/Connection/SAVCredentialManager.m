//
//  SCUCredentialManager.m
//  SavantControll
//
//  Created by Cameron Pulsford on 7/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVCredentialManager.h"
@import Extensions;
#import <SDK/SDK.h>

static NSString *const SAVFirstRun = @"SAVFirstRun";
static NSString *const SAVLastConnectedUID = @"SAVLastConnectedUID";
static NSString *const SAVCloudAuthenticationToken = @"SAVCloudAuthenticationToken";
static NSString *const SAVCloudAuthenticationSecretKey = @"SAVCloudAuthenticationSecretKey";
static NSString *const SAVCloudAuthenticationID = @"SAVCloudAuthenticationID";
static NSString *const SAVHostToken = @"SAVHostToken";
static NSString *const SAVCloudEmail = @"SAVCloudEmail";
static NSString *const SAVCloudUserName = @"SAVCloudUserName";
static NSString *const SAVCloudPassword = @"SAVCloudPassword";

@implementation SAVCredentialManager

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        //-------------------------------------------------------------------
        // Keychain entries are not deleted when the app is uninstalled, but
        // user defaults are. Clear all the previous keychain entries the
        // first time the app is run.
        //-------------------------------------------------------------------
        if (![[NSUserDefaults standardUserDefaults] boolForKey:SAVFirstRun])
        {
            [SAVKeychainKeyValueStore deleteAllKeychainEntries];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:SAVFirstRun];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }

    return self;
}

#pragma mark - Last connected system

- (NSString *)lastConnectedUserName
{
    return [SAVKeychainKeyValueStore objectForKey:[self credentialKeyForLastUserAllowLastConnectedSystem:YES]];
}

- (NSString *)lastConnectedPassword
{
    return [SAVKeychainKeyValueStore objectForKey:[self credentialKeyForLastPasswordAllowLastConnectedSystem:YES]];
}

#pragma mark - General login

- (void)saveUserName:(NSString *)userName password:(NSString *)password persistPassword:(BOOL)persistPassword
{
    [self saveLastSystemUID];

    //-------------------------------------------------------------------
    // Save the last connected user.
    //-------------------------------------------------------------------
    [SAVKeychainKeyValueStore setObject:userName forKey:[self credentialKeyForLastUserAllowLastConnectedSystem:NO]];

    if (persistPassword)
    {
        //-------------------------------------------------------------------
        // Save the last connected password.
        //-------------------------------------------------------------------
        [SAVKeychainKeyValueStore setObject:password forKey:[self credentialKeyForLastPasswordAllowLastConnectedSystem:NO]];

        //-------------------------------------------------------------------
        // Save the password against this specific user name as well. We save
        // passwords for multiple users.
        //-------------------------------------------------------------------
        [SAVKeychainKeyValueStore setObject:password forKey:[self credentialKeyForUserName:userName]];
    }
}

- (void)updateLastConnectedSystem
{
    [self saveLastSystemUID];
}

- (NSString *)passwordForUserName:(NSString *)userName
{
    return [SAVKeychainKeyValueStore objectForKey:[self credentialKeyForUserName:userName]];
}

#pragma mark -

- (void)saveLastSystemUID
{
    //-------------------------------------------------------------------
    // Save the UID of the current connected system in to the user defaults.
    // This allows to recall the lastConnectedUser/Password before a
    // connected has been started (when re-launching the app).
    //-------------------------------------------------------------------
    [SAVKeychainKeyValueStore setObject:[self uidAllowLastConnectedSystem:NO] forKey:SAVLastConnectedUID];
}

- (NSString *)credentialKeyForUserName:(NSString *)userName
{
    return [NSString stringWithFormat:@"%@-%@", [self uidAllowLastConnectedSystem:NO], [userName lowercaseString]];
}

- (NSString *)credentialKeyForLastUserAllowLastConnectedSystem:(BOOL)allowLastConnectedSystem
{
    return [NSString stringWithFormat:@"LastUser-%@", [self uidAllowLastConnectedSystem:allowLastConnectedSystem]];
}

- (NSString *)credentialKeyForLastPasswordAllowLastConnectedSystem:(BOOL)allowLastConnectedSystem
{
    return [NSString stringWithFormat:@"LastPassword-%@", [self uidAllowLastConnectedSystem:allowLastConnectedSystem]];
}

- (NSString *)uidAllowLastConnectedSystem:(BOOL)allowLastConnectedSystem
{
    NSString *uid = nil;

    if ([Savant control].currentSystem.hostID)
    {
        uid = [Savant control].currentSystem.hostID;
    }
    else if (allowLastConnectedSystem)
    {
        uid = [SAVKeychainKeyValueStore objectForKey:SAVLastConnectedUID];
    }

    return uid;
}

#pragma mark - Cloud

- (NSString *)cloudAuthenticationToken
{
    return [SAVKeychainKeyValueStore objectForKey:SAVCloudAuthenticationToken];
}

- (void)setCloudAuthenticationToken:(NSString *)cloudAuthenticationToken
{
    [SAVKeychainKeyValueStore setObject:cloudAuthenticationToken forKey:SAVCloudAuthenticationToken];
}

- (NSString *)cloudAuthenticationSecretKey
{
    return [SAVKeychainKeyValueStore objectForKey:SAVCloudAuthenticationSecretKey];
}

- (void)setCloudAuthenticationSecretKey:(NSString *)cloudAuthenticationSecretKey
{
    [SAVKeychainKeyValueStore setObject:cloudAuthenticationSecretKey forKey:SAVCloudAuthenticationSecretKey];
}

- (NSString *)cloudAuthenticationID
{
    return [SAVKeychainKeyValueStore objectForKey:SAVCloudAuthenticationID];
}

- (void)setCloudAuthenticationID:(NSString *)cloudAuthenticationID
{
    [SAVKeychainKeyValueStore setObject:cloudAuthenticationID forKey:SAVCloudAuthenticationID];
}

- (NSString *)cloudEmail
{
    return [SAVKeychainKeyValueStore objectForKey:SAVCloudEmail];
}

- (void)setCloudEmail:(NSString *)cloudEmail
{
    [SAVKeychainKeyValueStore setObject:cloudEmail forKey:SAVCloudEmail];
}

- (NSString *)cloudUserName
{
return [SAVKeychainKeyValueStore objectForKey:SAVCloudUserName];
}

- (void)setCloudUserName:(NSString *)cloudUserName
{
    [SAVKeychainKeyValueStore setObject:cloudUserName forKey:SAVCloudUserName];
}

- (NSString *)cloudPassword
{
    return [SAVKeychainKeyValueStore objectForKey:SAVCloudPassword];
}

- (void)setCloudPassword:(NSString *)cloudPassword
{
    [SAVKeychainKeyValueStore setObject:cloudPassword forKey:SAVCloudPassword];
}

- (NSString *)hostTokenForHomeID:(NSString *)homeID
{
    return [SAVKeychainKeyValueStore objectForKey:[self hostTokenKeyForHomeID:homeID]];
}

- (void)setHostToken:(NSString *)hostToken forHomeID:(NSString *)homeID
{
    if (homeID)
    {
        NSString *key = [self hostTokenKeyForHomeID:homeID];

        if (hostToken)
        {
            [SAVKeychainKeyValueStore setObject:hostToken forKey:key];
        }
        else
        {
            [SAVKeychainKeyValueStore deleteKeychainObjectForKey:key];
        }
    }
}

- (NSString *)hostTokenKeyForHomeID:(NSString *)homeID
{
    if (homeID)
    {
        return [NSString stringWithFormat:@"%@-%@", SAVHostToken, homeID];
    }
    else
    {
        return nil;
    }
}

- (void)setHostToken:(NSString *)hostToken
{
    [SAVKeychainKeyValueStore setObject:hostToken forKey:SAVHostToken];
}

#pragma mark - General

- (void)signOut
{
    [SAVKeychainKeyValueStore deleteAllKeychainEntries];
}

@end
