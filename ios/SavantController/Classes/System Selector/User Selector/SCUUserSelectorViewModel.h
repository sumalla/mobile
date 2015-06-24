//
//  SCUUserSelectorModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

typedef NS_ENUM(NSUInteger, SCUUserSelectorTableViewCellType)
{
    SCUUserSelectorTableViewCellTypePlaceholder,
    SCUUserSelectorTableViewCellTypeUser,
};

@interface SCUUserSelectorViewModel : SCUDataSourceModel

@end
