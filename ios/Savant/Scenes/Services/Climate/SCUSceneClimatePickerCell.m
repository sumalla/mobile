//
//  SCUSceneClimatePickerCell.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneClimatePickerCell.h"

@interface  SCUSceneClimatePickerCell ()

@property (nonatomic) SCUClimatePicker *pickerView;

@end

NSString *const SCUScenesClimatePickerCellKeyMinimumValue = @"SCUScenesClimatePickerCellKeyMinimumValue";
NSString *const SCUScenesClimatePickerCellKeyMaximumValue = @"SCUScenesClimatePickerCellKeyMaximumValue";
NSString *const SCUScenesClimatePickerCellKeyStepValue    = @"SCUScenesClimatePickerCellKeyStepValue";
NSString *const SCUScenesClimatePickerCellKeyCurrentValue = @"SCUScenesClimatePickerCellKeyCurrentValue";

@implementation SCUSceneClimatePickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.pickerView = [[SCUClimatePicker alloc] initWithFrame:CGRectZero];
        
        [self.contentView addSubview:self.pickerView];
        [self.contentView sav_setWidth:0.55 forView:self.pickerView isRelative:YES];
        [self.contentView sav_pinView:self.pickerView withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsCenterY];
    }
    
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)selectRowFromValue:(NSString *)value
{
    if (![value length])
    {
        [self.pickerView selectRow:0 inComponent:0 animated:NO];
    }
    else
    {
        NSInteger   intValue = [value integerValue];
        intValue -= self.pickerView.minimumValue;
        [self.pickerView selectRow:intValue inComponent:0 animated:NO];
    }
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.accessoryType = [info[SCUDefaultTableViewCellKeyAccessoryType] integerValue];
    
    if (info[SCUScenesClimatePickerCellKeyMinimumValue])
    {
        CGFloat min = [info[SCUScenesClimatePickerCellKeyMinimumValue] intValue];
        self.pickerView.minimumValue = min;
    }
    
    if (info[SCUScenesClimatePickerCellKeyStepValue])
    {
        NSInteger stepValue = [info[SCUScenesClimatePickerCellKeyStepValue] integerValue];
        self.pickerView.stepValue = stepValue;
    }
    
    if (info[SCUScenesClimatePickerCellKeyMaximumValue])
    {
        CGFloat max = [info[SCUScenesClimatePickerCellKeyMaximumValue] intValue];
        self.pickerView.maximumValue = max;
    }
    
    if (info[SCUScenesClimatePickerCellKeyCurrentValue])
    {
        [self selectRowFromValue:info[SCUScenesClimatePickerCellKeyCurrentValue]];
    }
    
    [self.pickerView reloadAllComponents];
}

@end
