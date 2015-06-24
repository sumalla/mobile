//
//  SCUPickerCell.h
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUPickerCellKeyValue;
extern NSString *const SCUPickerCellKeyMaxValue;
extern NSString *const SCUPickerCellKeyMinValue;
extern NSString *const SCUPickerCellKeyDelta;
extern NSString *const SCUPickerCellKeyValues;

@class SCUSecondsPickerView;

@interface SCUSecondsPickerCell : SCUDefaultTableViewCell

@property (readonly) SCUSecondsPickerView *pickerView;

@end
