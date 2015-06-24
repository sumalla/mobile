//
//  SCUAVSettingsButtonCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUButton.h"
#import <SavantExtensions/SavantExtensions.h>

extern NSString *const SCUAVSettingsCellValueLabel;

@interface SCUAVSettingsButtonCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) SCUButton *rightButton;

@property (readonly, nonatomic) UILabel *rightLabel;

@end
