//
//  SCUAnalytics.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

@interface SCUAnalytics : NSObject

+ (void)recordEvent:(NSString *)event;

+ (void)recordEvent:(NSString *)event withKey:(NSString *)key value:(NSString *)value;

+ (void)recordEvent:(NSString *)event properties:(NSDictionary *)properties;

@end
