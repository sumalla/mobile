//
//  SCUAVSettingsSelectCell.h
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUAVSettingsCellLeftValueLabel;

@interface SCUAVSettingsSelectCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) UILabel *valueLabel;

@end
