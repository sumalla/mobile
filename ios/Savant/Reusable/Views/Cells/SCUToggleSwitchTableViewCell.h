//
//  SCUSignInSwitchTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUToggleSwitchTableViewCellKeyValue;
extern NSString *const SCUToggleSwitchTableViewCellKeyAnimate;
extern NSString *const SCUToggleSwitchTableViewCellKeyImage;

@interface SCUToggleSwitchTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) UISwitch *toggleSwitch;
@property (nonatomic, readonly) UIImageView *toggleImageView;

@end
