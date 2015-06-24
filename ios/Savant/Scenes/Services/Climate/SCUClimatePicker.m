//
//  SCUClimatePicker.m
//  SavantController
//
//  Created by Stephen Silber on 8/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimatePicker.h"

@import Extensions;

@interface SCUClimatePicker () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) NSInteger minimumValue;
@property (nonatomic) NSInteger maximumValue;
@property (nonatomic) UIColor *textColor;

@end

//#define kRowHeight 30

@implementation SCUClimatePicker

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.dataSource = self;
        self.delegate = self;

        self.textColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];

        self.stepValue    = 1;
        self.minimumValue = 0;
        self.maximumValue = 100;
        
//        UIView *circle = [[UIView alloc ] initWithFrame:CGRectMake(CGRectGetWidth(self.frame) * 0.35, CGRectGetMidY(self.frame) - kRowHeight, 6, 6)];
//        circle.layer.cornerRadius = 3.0f;
//        circle.backgroundColor = [UIColor whiteColor];
//        
//        [self addSubview:circle];

    }
    
    return self;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    // FIX: Super hack - Only way to remove black row indicators on iOS 7
    // Probably need to build an SCUPicker at some point
    [(pickerView.subviews)[1] setHidden:YES];
    [(pickerView.subviews)[2] setHidden:YES];
 
    view = nil;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = self.textColor;
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont systemFontOfSize:18];
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];

    return label;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (row == 0)
    {
        return @"Default";
    }
    return [NSString stringWithFormat:@"%.0ld", (long)((row + self.minimumValue) / self.stepValue)];;
}

- (void)setMinimumValue:(NSInteger)minimumValue
{
    _minimumValue = minimumValue - 1;
}

- (void)setMaximumValue:(NSInteger)maximumValue
{
    _maximumValue = maximumValue;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.callback)
    {
        self.callback(self, row, component);
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return ((self.maximumValue - self.minimumValue) / self.stepValue) + 1;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

@end
