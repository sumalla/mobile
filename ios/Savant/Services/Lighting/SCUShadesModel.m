//
//  SCUShadesModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 1/26/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUShadesModel.h"
#import "SCULightingModelPrivate.h"

@implementation SCUShadesModel

- (SCULightingEntityType)lightingTypes
{
    return SCULightingEntityTypeShadeDimmer |
    SCULightingEntityTypeShadeSwitch;
}

@end
