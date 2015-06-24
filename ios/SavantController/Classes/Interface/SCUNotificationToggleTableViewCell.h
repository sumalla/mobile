//
//  SCUNotificationToggleTableViewCell.h
//  SavantController
//
//  Created by Julian Locke on 1/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUNotificationToggleTableViewCellKeyValue;
extern NSString *const SCUNotificationToggleTableViewCellKeyAnimate;

@interface SCUNotificationToggleTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) UISwitch *toggleSwitch;

@end
