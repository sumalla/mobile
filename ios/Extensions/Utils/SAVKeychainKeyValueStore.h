//
//  rpmKeychainKeyValueStore.h
//  Keychainer
//
//  Created by Zev Eisenberg on 8/12/13.
//  Copyright (c) 2013 Zev Eisenberg. All rights reserved.
//

@import Foundation;

/**
 *  Hacky delegate for reporting (not handling) errors.
 */
@protocol SAVKeychainKeyValueStoreErrorReportingDelegate <NSObject>

- (void)didEncounterKeychainError:(NSString *)error;

@end

//--------------------------------------------------
// This class acts as an abstraction bridge
// to allow you to use the keychain as a key/value
// store just like NSUserDefaults. It is intended
// to store things that you want to be secure, and
// that you don’t want restored to a different
// device in the event of a restore from an
// encrypted backup.
//
// When writing to the keychain, this class passes
// kSecAttrAccessibleAlwaysThisDeviceOnly for the
// kSecAttrAccessible key. This ensures that it will
// not restore from backup across different devices.
// This is the desired behavior for Savant ID storage.
// To use different kSecAttrAccessibility values,
// use the +setObject:forKey:withAccessType: method.
//--------------------------------------------------
@interface SAVKeychainKeyValueStore : NSObject

+ (void)setServiceName:(NSString *)serviceName;

/**
 *  Save an object into the keychain.
 *
 *  @param object     The object to store.
 *  @param key        The key to store the object against.
 *  @param accessType The kSecAttrAccessibility type.
 */
+ (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withAccessType:(id)accessType;

/**
 *  Save an object into the keychain using the kSecAttrAccessibleAlwaysThisDeviceOnly accessibility type. Usually, this is the method you will want.
 *
 *  @param object The object to store.
 *  @param key    The key to store the object against.
 */
+ (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;

+ (id)objectForKey:(NSString *)key;

+ (BOOL)deleteAllKeychainEntries;

+ (BOOL)deleteKeychainObjectForKey:(NSString *)key;

+ (void)setErrorDelegate:(id<SAVKeychainKeyValueStoreErrorReportingDelegate>)errorReportingDelegate;

@end
