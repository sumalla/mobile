//
//  SCUDatePickerCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDatePickerCell.h"

NSString *const SCUPickerCellKeyDate = @"SCUClimateHistoryPickerCellKeyDate";
NSString *const SCUPickerCellKeySeconds = @"SCUClimateHistoryPickerCellKeySeconds";
NSString *const SCUPickerCellKeyMaxDate = @"SCUClimateHistoryPickerCellKeyMaxDate";
NSString *const SCUPickerCellKeyMinDate = @"SCUClimateHistoryPickerCellKeyMinDate";
NSString *const SCUPickerCellKeyDateType = @"SCUClimateHistoryPickerCellKeyDateType";
NSString *const SCUPickerCellKeyDateFormat = @"SCUClimateHistoryPickerCellKeyDateFormat";

@interface SCUDatePickerCell ()

@property PMEDatePicker *datePicker;

@end

@implementation SCUDatePickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.datePicker = [[PMEDatePicker alloc] initWithFrame:CGRectZero];
        self.datePicker.dateFormatTemplate = @"MMMyyyyd";
        self.datePicker.textColor = [[SCUColors shared] color04];
        self.datePicker.textFont = [UIFont fontWithName:@"Gotham-Light" size:18];
        [self.contentView addSubview:self.datePicker];
        [self.contentView sav_addFlushConstraintsForView:self.datePicker];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (info[SCUPickerCellKeyDate])
    {
        self.datePicker.date = info[SCUPickerCellKeyDate];
    }
    else if (info[SCUPickerCellKeySeconds])
    {
        self.datePicker.seconds = [info[SCUPickerCellKeySeconds] floatValue];
    }

    self.datePicker.maximumDate = info[SCUPickerCellKeyMaxDate];
    self.datePicker.minimumDate = info[SCUPickerCellKeyMinDate];
    self.datePicker.dateFormatTemplate = info[SCUPickerCellKeyDateFormat] ? info[SCUPickerCellKeyDateFormat] : @"MMMyyyd";
}

@end
