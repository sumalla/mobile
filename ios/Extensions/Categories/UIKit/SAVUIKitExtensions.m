//
//  SAVUIKitExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SAVUIKitExtensions.h"

Class DeviceClassFromClass(Class className)
{
    NSString *classString = NSStringFromClass(className);
    Class returnClass = NULL;

    if ([UIDevice isPad])
    {
        returnClass = NSClassFromString([NSString stringWithFormat:@"%@Pad", classString]);
    }
    else
    {
        returnClass = NSClassFromString([NSString stringWithFormat:@"%@Phone", className]);
    }

    if (![returnClass class])
    {
        returnClass = className;
    }

    return returnClass;
}
