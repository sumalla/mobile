//
//  SAVZone.h
//  SavantControl
//
//  Created by Ian Mortimer on 12/3/13.
//  Copyright (c) 2013 Savant Systems, LLC. All rights reserved.
//

@import Foundation;

@interface SAVZone : NSObject <NSCopying>

@property NSString *zoneId;
@property NSString *zoneName;
@property NSString *zoneType;

- (BOOL)isEqualToZone:(SAVZone *)zone;

@end
