//
//  NSDate+SAVExtensions.h
//  SavantControl
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

extern NSCalendarUnit const NSCalendarUnitDate;

@interface NSDate (SAVExtensions)

- (NSDate *)dateWithoutTimeComponents;
- (BOOL)isToday;
+ (NSDate *)today;

@end
