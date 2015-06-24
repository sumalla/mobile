//
//  NSNull+SAVExtensions.h
//  SavantExtensions
//
//  Created by Cameron Pulsford on 10/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

#define SAV_AS_CLASS(object, className) ((className *)([object isKindOfClass:[className class]] ? object : nil))

@interface NSNull (SAVExtensions)

+ (id)nilOrIdentityFromObject:(id)object;

@end
