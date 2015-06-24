//
//  SCUNumericPickerView.m
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumericPickerView.h"
@import Extensions;

@interface SCUNumericPickerView () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic) CGFloat value;

@end

@implementation SCUNumericPickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _minValue = 0;
        _maxValue = 1;
        _delta = .1;
        self.dataSource = self;
        self.delegate = self;
        [self setValue:0 animated:NO];
    }
    return self;
}

#pragma mark - methods

- (void)reloadData
{
    CGFloat value = self.value;
    [self reloadAllComponents];
    [self setValue:value animated:NO];
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated
{
    self.value = value;

    [self selectRow:[self rowForValue:value] inComponent:0 animated:animated];
}

- (NSUInteger)rowForValue:(CGFloat)value
{
    NSUInteger row = 0;

    if (self.values)
    {
        row = [self.values indexOfObject:@(value)];

        if (row == NSNotFound)
        {
            row = 0;
        }
    }
    else
    {
        row = (NSInteger)(value / self.delta - self.minValue);
    }

    return row;
}

- (CGFloat)valueForRow:(NSUInteger)row
{
    return self.values ? [self.values[row] floatValue] : row * self.delta + self.minValue * self.delta;
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor ? textColor : [[SCUColors shared] color03];
    [self reloadData];
}

- (void)setTextFont:(UIFont *)textFont
{
    _textFont = textFont ? textFont : [UIFont systemFontOfSize:20];
    [self reloadData];
}

- (void)setMinValue:(CGFloat)minValue
{
    _minValue = minValue;
    [self reloadData];
}

- (void)setMaxValue:(CGFloat)maxValue
{
    _maxValue = maxValue;
    [self reloadData];
}

- (void)setDelta:(CGFloat)delta
{
    _delta = delta;
    [self reloadData];
}

- (void)setValues:(NSArray *)values
{
    _values = values;
    [self reloadData];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.values ? [self.values count] : ((self.maxValue - self.minValue) * self.delta + 1);
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%f", [self valueForRow:row]];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = (UILabel *)view;
    if (!label)
    {
        label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
    }
    label.textColor = self.textColor;
    label.font = self.textFont;
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];

    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [self setValue:[self valueForRow:row] animated:YES];
    [self didSelectRow];
    [self reloadData];
}

- (void)didSelectRow
{
    if (self.handler)
    {
        self.handler(self.value);
    }
}

@end
