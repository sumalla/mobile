//
//  SCUPickerCell.m
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecondsPickerCell.h"
#import "SCUSecondsPickerView.h"

NSString *const SCUPickerCellKeyValue    = @"SCUPickerCellKeyValue";
NSString *const SCUPickerCellKeyMaxValue = @"SCUPickerCellKeyMaxValue";
NSString *const SCUPickerCellKeyMinValue = @"SCUPickerCellKeyMinValue";
NSString *const SCUPickerCellKeyDelta    = @"SCUPickerCellKeyDelta";
NSString *const SCUPickerCellKeyValues   = @"SCUPickerCellKeyValues";

@interface SCUSecondsPickerCell ()

@property SCUSecondsPickerView *pickerView;

@end

@implementation SCUSecondsPickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.pickerView = [[SCUSecondsPickerView alloc] initWithFrame:CGRectZero];
        self.pickerView.textColor = [[SCUColors shared] color04];
        self.pickerView.textFont = [UIFont fontWithName:@"Gotham-Light" size:18];
        [self.contentView addSubview:self.pickerView];
        [self.contentView sav_addFlushConstraintsForView:self.pickerView];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (info[SCUPickerCellKeyValues])
    {
        self.pickerView.values = info[SCUPickerCellKeyValues];
    }
    else
    {
        self.pickerView.values = nil;
        self.pickerView.maxValue = [info[SCUPickerCellKeyMaxValue] floatValue];
        self.pickerView.minValue = [info[SCUPickerCellKeyMinValue] floatValue];
        self.pickerView.delta = [info[SCUPickerCellKeyDelta] floatValue];
    }

    [self.pickerView setValue:[info[SCUPickerCellKeyValue] floatValue] animated:NO];
}

@end
