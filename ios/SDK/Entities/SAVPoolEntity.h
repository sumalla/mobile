//
//  SAVPoolEntity.h
//  SavantControl
//
//  Created by Jason Wolkovitz on 10/10/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVEntity.h"
#import "SAVHVACEntity.h"

typedef NS_ENUM(NSUInteger, SAVPoolAuxStates)
{
    SAVPoolAuxStateNone,
    SAVPoolAuxStateOn,
    SAVPoolAuxStateOff,
    SAVPoolAuxStateEnabled,
    SAVPoolAuxStatePumpLow,
    SAVPoolAuxStatePumpHigh    
};

@interface SAVPoolEntity : SAVHVACEntity

@property NSMutableDictionary *auxiliaryNumberLabels;
@property NSMutableArray *auxiliaryNumberOrder;

//+ (NSString *)addDegreeSuffix:(NSString *)value;

- (void)addAuxiliaryNumber:(NSString *)number label:(NSString *)label;
- (SAVPoolAuxStates)poolStateFromString:(NSString *)value;

@end