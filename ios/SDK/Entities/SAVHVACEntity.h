//
//  SAVHVACEntity.h
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVEntity.h"
@import UIKit;

@interface SAVHVACEntity : SAVEntity

// Single Vs. Multiple Set-Points
@property NSInteger tempSPCount;
@property NSInteger humiditySPCount;
@property BOOL heatSetPoint;
@property BOOL coolSetPoint;
@property BOOL autoMode;
@property BOOL humidifySetPoint;
@property BOOL dehumidifySetPoint;
@property BOOL history;

+ (NSString *)addDegreeSuffix:(NSString *)value;
+ (NSAttributedString *)addDegreeSuffix:(NSString *)value baseFont:(UIFont *)baseFont degreeFont:(UIFont *)degreeFont withDegreeOffset:(float)offset;
+ (NSString *)addPercentSuffix:(NSString *)value;

@end
