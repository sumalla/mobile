//
//  SCUSpinnerTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

typedef NS_ENUM(NSUInteger, SCUProgressTableViewCellAccessoryType)
{
    SCUProgressTableViewCellAccessoryTypeNone = 0,
    SCUProgressTableViewCellAccessoryTypeSpinner,
    SCUProgressTableViewCellAccessoryTypeCheckmark
};

extern NSString *const SCUProgressTableViewCellKeyAccessoryType;

@interface SCUProgressTableViewCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) UIActivityIndicatorView *spinnerView;

@end
