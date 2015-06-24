//
//  SCUSceneClimatePickerCell.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUClimatePicker.h"

extern NSString *const SCUScenesClimatePickerCellKeyMinimumValue;
extern NSString *const SCUScenesClimatePickerCellKeyMaximumValue;
extern NSString *const SCUScenesClimatePickerCellKeyCurrentValue;
extern NSString *const SCUScenesClimatePickerCellKeyStepValue;

@interface SCUSceneClimatePickerCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) SCUClimatePicker *pickerView;

@end
