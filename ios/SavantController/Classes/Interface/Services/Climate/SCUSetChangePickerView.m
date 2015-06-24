//
//  SCUSetChangePickerView.m
//  SavantController
//
//  Created by David Fairweather on 5/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSetChangePickerView.h"
#import "SCUServiceViewController.h"

#define PICKER_ROW_MULTIPLIER   1

@interface SCUSetChangePickerView () <UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic) NSMutableArray *timeBands;
@property (nonatomic) CGFloat componentWidth;

@property (nonatomic) NSMutableArray *hourData;
@property (nonatomic) NSMutableArray *minuteData;
@property (nonatomic) NSMutableArray *bandData;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) CGFloat titleWidth;
@property (nonatomic) CGFloat titleHeight;
@property (nonatomic) CGFloat titleOffset_X;
@property (nonatomic) CGFloat titleOffset_Y;

@property (nonatomic) UILabel *timeLabel;
@property (nonatomic) CGFloat timeWidth;
@property (nonatomic) CGFloat timeHeight;

@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *fontColor;

@property (nonatomic) CGFloat pickerWidth;
@property (nonatomic) CGFloat pickerHeight;

@property (nonatomic) BOOL isHidden;

@end

@implementation SCUSetChangePickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        [self addSubview:self.pickerView];
        
        self.userInteractionEnabled = YES;
        
        self.componentWidth = [UIDevice isPad] ? 50.0f : 25.0f;
        self.componentHeight = self.componentWidth;
        
        self.titleWidth = [UIDevice isPad] ? 180.0f : 80.0f;
        self.titleHeight = 50.0f;
        
//        self.titleOffset_X = [UIDevice isPad] ? 110.0f : 50.0f;
//        self.titleOffset_Y = 65.0f;

        self.timeWidth = [UIDevice isPad] ? 110.0f : 50.0f;
        self.timeHeight = 50.0f;
        
        self.pickerWidth = [UIDevice isPad] ? 160.0f : 100.0f;
        self.pickerHeight = [UIDevice isPad] ? 200.0f : 100.0f;
        
        self.font = [UIFont fontWithName:@"Gotham" size:[UIDevice isPad] ? 26.0f : 14.0f];
        self.fontColor = [UIColor sav_colorWithRGBValue:0xDFE0E2];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.font = self.font;
        self.titleLabel.textColor = self.fontColor;
        self.titleLabel.text = @"Set Until";
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.titleLabel];
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLabel.font = self.font;
        self.timeLabel.textColor = self.fontColor;
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        self.timeLabel.userInteractionEnabled = YES;
        [self addSubview:self.timeLabel];
        
        self.hourData = [[NSMutableArray alloc] init];
        self.minuteData = [[NSMutableArray alloc] init];
        self.bandData = [[NSMutableArray alloc] init];
        
        NSString *dataString;
        
        for (int i = 0; i < 12; ++i)
        {
            dataString = [NSString stringWithFormat:@"%li", (long)i + 1];
            [self.hourData addObject:dataString];
        }
        
        for (int i = 0; i < 60; ++i)
        {
            dataString = i < 10 ? [NSString stringWithFormat:@"0%li", (long)i] : [NSString stringWithFormat:@"%li", (long)i];
            [self.minuteData addObject:dataString];
        }
        
        [self.bandData addObject:@"AM"];
        [self.bandData addObject:@"PM"];
        
        self.timeLabel.text = @"1:00AM";
        
        [self showPickerVisibility:NO];
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat offset = 15.0f;
    CGFloat pickerVerticalOffset = [UIDevice isPad] ? 10.0f : -30.0f;
    
    [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                metrics:@{@"width": @(self.titleWidth),
                                                                          @"height": @(self.titleHeight),
                                                                          @"offset": @(offset),
                                                                          @"timeWidth": @(self.timeWidth),
                                                                          @"timeHeight": @(self.timeHeight),
                                                                          @"pickerWidth": @(self.pickerWidth),
                                                                          @"pickerHeight": @(self.pickerHeight),
                                                                          @"pickerVertOffset": @(pickerVerticalOffset)}
                                                                  views:@{@"label": self.titleLabel,
                                                                          @"time": self.timeLabel,
                                                                          @"picker": self.pickerView}
                                                                formats:@[@"label.width = width",
                                                                          @"label.left = super.left + offset",
                                                                          @"V:|[label]|",
                                                                          
                                                                          @"time.width = timeWidth",
                                                                          @"time.right = super.right - offset",
                                                                          @"V:|[time]|",
                                                                          
                                                                          @"picker.centerY = super.centerY + pickerVertOffset",
                                                                          @"picker.right = super.right - offset",
                                                                          @"picker.width = pickerWidth",
                                                                          @"picker.height = pickerHeight"]]];
    
    [super layoutSubviews];
}

- (void)showPickerVisibility:(BOOL)visible
{
    if (visible)
    {
        self.isHidden = NO;
        self.timeLabel.hidden = YES;
    }
    else
    {
        self.isHidden = YES;
        self.timeLabel.hidden = NO;
    }
    
    [self.pickerView reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            return 12 * PICKER_ROW_MULTIPLIER;
        case 1:
            return 60 * PICKER_ROW_MULTIPLIER;
        case 2:
            return 2;
    }
    
    return 0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            return self.componentWidth;
        case 1:
            return self.componentWidth;
        case 2:
            return self.componentWidth;
    }
    
    return 0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return self.componentHeight;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, [self pickerView:self.pickerView widthForComponent:component], self.titleHeight)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:self.fontColor];
    [label setFont:self.font];
    label.textAlignment = NSTextAlignmentRight;
    
    label.hidden = self.isHidden;
    
    NSInteger lastObject = [self.pickerView.subviews count] - 1;
    NSInteger secondLastObject = [self.pickerView.subviews count] - 2;
    
    [(self.pickerView.subviews)[lastObject] setHidden:YES];
    [(self.pickerView.subviews)[secondLastObject] setHidden:YES];
    
//    if (component < 2 && row >= ([self numberOfRowsInComponent:component] / PICKER_ROW_MULTIPLIER))
//        row = row % ([self numberOfRowsInComponent:component] / PICKER_ROW_MULTIPLIER);
    
    switch (component)
    {
        case 0:
            label.text = [NSString stringWithFormat:@"%ld", (long)row + 1];
            break;
        case 1:
            if (row < 10)
                label.text = [NSString stringWithFormat:@"0%ld", (long)row];
            else
                label.text = [NSString stringWithFormat:@"%ld", (long)row];
            break;
        case 2:
            if (row % 2 == 0)
                label.text = @"AM";
            else
                label.text = @"PM";
            break;
    }
    
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
//    if (row >= ([self numberOfRowsInComponent:component] / PICKER_ROW_MULTIPLIER) + 5)
//        [pickerView selectRow:row % ([self numberOfRowsInComponent:component] / PICKER_ROW_MULTIPLIER) inComponent:component animated:NO];
    self.timeLabel.text = @"";
    
    self.timeLabel.text = [self.timeLabel.text stringByAppendingString:[NSString stringWithFormat:@"%@:", (self.hourData)[[pickerView selectedRowInComponent:0]]]];
    self.timeLabel.text = [self.timeLabel.text stringByAppendingString:[NSString stringWithFormat:@"%@", (self.minuteData)[[pickerView selectedRowInComponent:1]]]];
    self.timeLabel.text = [self.timeLabel.text stringByAppendingString:[NSString stringWithFormat:@"%@", (self.bandData)[[pickerView selectedRowInComponent:2]]]];
}

@end
