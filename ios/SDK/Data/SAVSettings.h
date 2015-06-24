//
//  SAVSettings.h
//  SavantControl
//
//  Created by Nathan Trapp on 6/20/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

typedef void (^SAVSettingsKeyUpdate)(NSString *key, id setting);

@interface SAVSettings : NSObject

/**
 *  Resets all shared settings managers.
 */
+ (void)resetAllSettings;

/**
 *  Returns the shared local settings manager.
 *
 *  @return The shared local settings object.
 */
+ (instancetype)localSettings;

/**
 *  Synchronizes any changes made to the shared local settings manager and then releases it from memory.
 */
+ (void)resetLocalSettings;

/**
 *  Returns the shared user settings manager for the currently connect user.
 *
 *  @return The shared user settings object.
 */
+ (instancetype)userSettings;

/**
 *  Synchronizes any changes made to the shared user settings manager and then releases it from memory.
 */
+ (void)resetUserSettings;

/**
 *  Returns the shared global settings manager.
 *
 *  @return The shared global settings object.
 */
+ (instancetype)globalSettings;

/**
 *  Synchronizes any changes made to the shared global settings manager and then releases it from memory.
 */
+ (void)resetGlobalSettings;

/**
 *  Indicates if this settings manager automatically syncs its settings with the system.
 */
@property (nonatomic, readonly) BOOL syncsSettings;

/**
 *  Writes all modifications to disk.
 *
 *  @return YES if the data was saved succesfully to disk, otherwise NO.
 */
- (BOOL)synchronize;

/**
 *  Creates a custom settings store under the system path using the provided domain.
 *
 *  @param domain A user provided settings domain
 *
 *  @return A settings manager.
 */
- (instancetype)initWithDomain:(NSString *)domain;

/**
 *  Sets the value of the specified settings key under the given domain.
 *
 *  @param setting The setting to store.
 *  @param key     The key with which to associate the value.
 */
- (void)setObject:(id)setting forKey:(NSString *)key;

/**
 *  Removes the value of the specified settings key under the given domain.
 *
 *  @param key The key whose value you want to remove.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 *  Returns the value associated with a given key.
 *
 *  @param key A key in the current settings domain.
 *
 *  @return The object associated with the specified key, or nil if the key was not found.
 */
- (id)objectForKey:(NSString *)key;

/**
 *  Add an observer to notify when a key value is updated.
 *
 *  @param key    The key value to observe.
 *  @param block  The block to be executed when an update is received.
 *                The block is copied by the settings manager and (the copy) held until the observer registration is removed.
 *
 *  @return an observer An opaque object to act as the observer.
 */
- (id)addObserverForKey:(NSString *)key usingBlock:(SAVSettingsKeyUpdate)block;

/**
 *  Remove an observer registration.
 *
 *  @param observer An opaque observer object.
 */
- (void)removeObserver:(id)observer;

@end
