//
//  SCUSettingsModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

static NSString *SCUSettingsKeyAction = @"SCUSettingsKeyAction";
static NSString *SCUSettingsKeyRequirement = @"SCUSettingsKeyRequirement";

@interface SCUSettingsModel ()

- (NSArray *)parseActions:(NSArray *)actions;

@end
