//
//  SCUDatePickerCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import <PMEDatePicker/PMEDatePicker.h>

extern NSString *const SCUPickerCellKeyDate;
extern NSString *const SCUPickerCellKeySeconds;
extern NSString *const SCUPickerCellKeyMaxDate;
extern NSString *const SCUPickerCellKeyMinDate;
extern NSString *const SCUPickerCellKeyDateType;
extern NSString *const SCUPickerCellKeyDateFormat;

@interface SCUDatePickerCell : SCUDefaultTableViewCell

@property (readonly) PMEDatePicker *datePicker;

@end
