//
//  SCUAVSettingsStepperCell.h
//  SavantController
//
//  Created by Stephen Silber on 7/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUStepper.h"

extern NSString *const SCUAVSettingsCellValueLabel;
extern NSString *const SCUAVSettingsStepperCellTextArray;
extern NSString *const SCUAVSettingsStepperCellButtonSize;
extern NSString *const SCUAVSettingsStepperCellValueRange;
extern NSString *const SCUAVSettingsStepperCellFormattedValue;

@interface SCUAVSettingsStepperCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) SCUButton *defaultButton;

@property (readonly, nonatomic) SCUStepper *stepper;

@property (readonly, nonatomic) UILabel *rightLabel;


- (void)updateStepper:(float)value;
- (void)updateStepperValueLabel:(float)value;
- (void)updateStepperFromFormattedValue:(NSString *)value;

@end
