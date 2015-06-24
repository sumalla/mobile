//
//  SCUDayPickerCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUDayPickerCellKeySelectedDays;
extern NSString *const SCUDayPickerCellKeyAvailableDays;

typedef NS_OPTIONS(NSInteger, SCUDayPickerDays)
{
    SCUDayPickerDays_None = 0,
    SCUDayPickerDays_Sunday = 1 << 0,
    SCUDayPickerDays_Monday = 1 << 1,
    SCUDayPickerDays_Tuesday = 1 << 2,
    SCUDayPickerDays_Wednesday = 1 << 3,
    SCUDayPickerDays_Thursday = 1 << 4,
    SCUDayPickerDays_Friday = 1 << 5,
    SCUDayPickerDays_Saturday = 1 << 6,

    SCUDayPickerDays_All = 127,
    SCUDayPickerDays_Weekdays = 62,
    SCUDayPickerDays_Weekends = 65
};

typedef void (^SCUDayPickerCallback)(SCUDayPickerDays selectedDays);

@interface SCUDayPickerCell : SCUDefaultTableViewCell

@property (nonatomic) SCUDayPickerDays selectedDays;
@property (nonatomic) SCUDayPickerDays availableDays;
@property (strong) SCUDayPickerCallback callback;

@end
