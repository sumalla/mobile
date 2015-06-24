//
//  SCUAnalytics.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAnalytics.h"
#import <Mixpanel/Mixpanel.h>
@import SDK;

@implementation SCUAnalytics

+ (void)startUp
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *token = @"696ecbe3c0c0cfefe48b8eba826c0429";

        switch ([Savant control].cloudServerAddress)
        {
            case SAVCloudServerAddressQA:
            case SAVCloudServerAddressAlpha:
            case SAVCloudServerAddressTraining:
                token = @"bf826f7b8fb70b0ec7de0547f8dcf328";
                break;
            case SAVCloudServerAddressBeta:
                token = @"ad2f76352b27604399c2b6868e353079";
                break;
            case SAVCloudServerAddressDev1:
            case SAVCloudServerAddressDev2:
                token = @"68ae9bf79938fc59a5aff3fcc0a3ada3";
                break;
            case SAVCloudServerAddressUnknown:
            case SAVCloudServerAddressProduction:
                token = @"696ecbe3c0c0cfefe48b8eba826c0429";
                break;
        }

        if (token)
        {
            [Mixpanel sharedInstanceWithToken:token];
        }
    });
}

+ (void)recordEvent:(NSString *)event
{
    if ([[Savant cloud] cloudUserEmail])
    {
        [self startUp];
        [[Mixpanel sharedInstance] track:event];
    }
}

+ (void)recordEvent:(NSString *)event withKey:(NSString *)key value:(NSString *)value
{
    if ([[Savant cloud] cloudUserEmail])
    {
        [self startUp];

        if (key && value)
        {
            [[Mixpanel sharedInstance] track:event properties:@{key: value}];
        }
        else
        {
            [[Mixpanel sharedInstance] track:event];
        }
    }
}

+ (void)recordEvent:(NSString *)event properties:(NSDictionary *)properties
{
    if ([[Savant cloud] cloudUserEmail])
    {
        [self startUp];

        if ([properties count])
        {
            [[Mixpanel sharedInstance] track:event properties:properties];
        }
        else
        {
            [[Mixpanel sharedInstance] track:event];
        }
    }
}

@end
