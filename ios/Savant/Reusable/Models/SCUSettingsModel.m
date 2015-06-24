//
//  SCUSettingsModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSettingsModel.h"
#import "SCUSettingsModelPrivate.h"
@import Extensions;

@implementation SCUSettingsModel

- (NSArray *)parseActions:(NSArray *)actions
{
    //-------------------------------------------------------------------
    // Parses the current actions and removes any items whose
    // requirements aren't met.
    //-------------------------------------------------------------------
    NSMutableArray *mutableActions = [actions mutableCopy];

    for (NSDictionary *action in [actions copy])
    {
        NSString *requirement = action[SCUSettingsKeyRequirement];

        if (requirement)
        {
            if ([requirement isKindOfClass:[NSString class]] && [self respondsToSelector:NSSelectorFromString(requirement)])
            {
                SEL selector = NSSelectorFromString(requirement);
                SAVFunctionForSelector(function, self, selector, BOOL);

                BOOL req = function(self, selector);

                if (!req)
                {
                    [mutableActions removeObject:action];
                }
            }
            else if ([requirement isKindOfClass:[NSNumber class]])
            {
                if (![requirement boolValue])
                {
                    [mutableActions removeObject:action];
                }
            }
        }
    }

    return [mutableActions copy];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id modelObject = [self modelObjectForIndexPath:indexPath];

    if (modelObject[SCUSettingsKeyAction])
    {
        SEL selector = NSSelectorFromString(modelObject[SCUSettingsKeyAction]);
        SAVFunctionForSelector(function, self, selector, void);
        function(self, selector);
    }
}

@end
