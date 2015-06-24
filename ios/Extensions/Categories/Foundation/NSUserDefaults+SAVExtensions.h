//
//  NSUserDefaults+SAVExtensions.h
//  Pods
//
//  Created by Cameron Pulsford on 8/13/14.
//
//

@import Foundation;

@interface NSUserDefaults (SAVExtensions)

+ (void)sav_modifyDefaults:(void (^)(NSUserDefaults *defaults))modifyBlock;

/**
 *  Update the cache version for the given key. If the versions are not equal, the provided updateBlock will be performed.
 *
 *  @param version     The new version.
 *  @param key         The key.
 *  @param updateBlock The work to perform if this version is newer.
 */
+ (void)sav_updateCacheVersion:(NSUInteger)version forKey:(NSString *)key updateBlock:(dispatch_block_t)updateBlock;

@end
