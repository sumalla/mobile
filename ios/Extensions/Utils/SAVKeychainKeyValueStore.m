//
//  rpmKeychainKeyValueStore.m
//  Keychainer
//
//  Created by Zev Eisenberg on 8/12/13.
//  Copyright (c) 2013 Zev Eisenberg. All rights reserved.
//

#import "SAVKeychainKeyValueStore.h"
@import Security;

//--------------------------------------------------
// This code is modified from an example posted at
// http://useyourloaf.com/blog/2010/03/29/simple-iphone-keychain-access.html
// and originally retrieved 12 August 2013 by Zev Eisenberg
//--------------------------------------------------

static NSString *ServiceName = nil;
static id<SAVKeychainKeyValueStoreErrorReportingDelegate> gDelegate = nil;

@implementation SAVKeychainKeyValueStore

+ (void)setServiceName:(NSString *)serviceName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ServiceName = serviceName;
    });
}

+ (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withAccessType:(id)accessType
{
    BOOL success = [self setKeychainObject:object forKey:key accessType:accessType];

    if (!success)
    {
        NSString *message = @"SAVKeychainKeyValueStore: error setting object";
        [gDelegate didEncounterKeychainError:message];
        NSLog(@"%@", message);
    }
}

+ (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    if (object)
    {
        [self setObject:object forKey:key withAccessType:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly];
    }
    else
    {
        [self deleteKeychainObjectForKey:key];
    }
}

+ (id)objectForKey:(NSString *)k
{
    NSString *key = k ? k : @"";

    NSMutableDictionary *searchDictionary = [self newSearchDictionaryForItemWithKey:key];

    // Add search attributes
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    // Add search return types
    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    CFTypeRef resultData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary,
                                          &resultData);

    id object = nil;

    switch (status)
    {
        case errSecSuccess:
        {
            if (resultData)
            {
                object = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)resultData];
            }

            break;
        }
        case errSecItemNotFound:
        {
            break;
        }
        default:
        {
            [self printMessageForOSStatus:status];
            break;
        }
    }

    if (resultData)
    {
        CFRelease(resultData);
    }

    return object;
}

+ (NSMutableDictionary *)newSearchDictionaryForItemWithKey:(NSString *)key
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];

    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:ServiceName forKey:(__bridge id)kSecAttrService];

    return searchDictionary;
}

+ (BOOL)setKeychainObject:(id<NSCoding>)object forKey:(NSString *)key accessType:(id)accessType
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];

    if (!data)
    {
        return [self deleteKeychainObjectForKey:key];
    }

    NSMutableDictionary *dictionary = [self newSearchDictionaryForItemWithKey:key];

    [dictionary setObject:data forKey:(__bridge id)kSecValueData];
    [dictionary setObject:accessType forKey:(__bridge id)kSecAttrAccessible];

    BOOL success = NO;

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);

    switch (status)
    {
        case errSecSuccess:
        {
            success = YES;
            break;
        }
        case errSecDuplicateItem:
        {
            success = [self updateKeychainObject:object forKey:key];
            break;
        }
        default:
        {
            [self printMessageForOSStatus:status];
            break;
        }
    }

    return success;
}

+ (BOOL)updateKeychainObject:(id<NSCoding>)object forKey:(NSString *)key
{
    NSMutableDictionary *searchDictionary = [self newSearchDictionaryForItemWithKey:key];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [updateDictionary setObject:data forKey:(__bridge id)kSecValueData];
    [updateDictionary setObject:(__bridge id)kSecAttrAccessibleAlwaysThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);

    if (status == errSecSuccess)
    {
        return YES;
    }

    [self printMessageForOSStatus:status];
    return NO;
}

+ (BOOL)deleteAllKeychainEntries
{
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword});

    if (status == errSecSuccess)
    {
        return YES;
    }

    return NO;
}

+ (BOOL)deleteKeychainObjectForKey:(NSString *)key
{
    NSMutableDictionary *searchDictionary = [self newSearchDictionaryForItemWithKey:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);

    if (status == errSecSuccess)
    {
        return YES;
    }

    [self printMessageForOSStatus:status];
    return NO;
}

+ (void)printMessageForOSStatus:(OSStatus)status
{
    NSString *errorMessage = nil;

    switch (status)
    {
        case (errSecSuccess):
        {
            errorMessage = @"no error";
            break;
        }
        case (errSecUnimplemented):
        {
            errorMessage = @"errSecUnimplemented - Function or operation not implemented.";
            break;
        }
        case (errSecParam):
        {
            errorMessage = @"errSecParam - One or more parameters passed to the function were not valid.";
            break;
        }
        case (errSecAllocate):
        {
            errorMessage = @"errSecAllocate - Failed to allocate memory.";
            break;
        }
        case (errSecNotAvailable):
        {
            errorMessage = @"errSecNotAvailable - No trust results are available.";
            break;
        }
        case (errSecAuthFailed):
        {
            errorMessage = @"errSecAuthFailed - Authorization/Authentication failed.";
            break;
        }
        case (errSecDuplicateItem):
        {
            errorMessage = @"errSecDuplicateItem - The item already exists.";
            break;
        }
        case (errSecItemNotFound):
        {
            errorMessage = @"errSecItemNotFound - The item cannot be found.";
            break;
        }
        case (errSecInteractionNotAllowed):
        {
            errorMessage = @"errSecInteractionNotAllowed - Interaction with the Security Server is not allowed.";
            break;
        }
        case (errSecDecode):
        {
            errorMessage = @"errSecDecode - Unable to decode the provided data.";
            break;
        }
        default:
        {
            errorMessage = @"unknown error";
            break;
        }
    }

    NSString *message = [NSString stringWithFormat:@"SCUKeychainKeyValueStore:: Status %ld, message '%@'", (long)status, errorMessage];
    [gDelegate didEncounterKeychainError:message];
    NSLog(@"%@", message);
}

+ (void)setErrorDelegate:(id<SAVKeychainKeyValueStoreErrorReportingDelegate>)errorReportingDelegate
{
    NSParameterAssert([errorReportingDelegate conformsToProtocol:@protocol(SAVKeychainKeyValueStoreErrorReportingDelegate)]);
    gDelegate = errorReportingDelegate;
}

@end
