//
//  NSUserDefaults+SAVExtensions.m
//  Pods
//
//  Created by Cameron Pulsford on 8/13/14.
//
//

#import "NSUserDefaults+SAVExtensions.h"

@implementation NSUserDefaults (SAVExtensions)

+ (void)sav_modifyDefaults:(void (^)(NSUserDefaults *defaults))modifyBlock
{
    NSParameterAssert(modifyBlock);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    modifyBlock(defaults);
    [defaults synchronize];
}

+ (void)sav_updateCacheVersion:(NSUInteger)version forKey:(NSString *)key updateBlock:(dispatch_block_t)updateBlock
{
    NSParameterAssert(key);
    NSParameterAssert(updateBlock);

    NSNumber *oldVersion = [[[self class] standardUserDefaults] objectForKey:key];

    if (!oldVersion || [oldVersion unsignedIntegerValue] != version)
    {
        [[self class] sav_modifyDefaults:^(NSUserDefaults *defaults) {
            [defaults setObject:@(version) forKey:key];
        }];

        updateBlock();
    }
}

@end
