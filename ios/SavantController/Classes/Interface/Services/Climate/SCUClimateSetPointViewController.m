//
//  SCUClimateSetPointViewController.m
//  SavantController
//
//  Created by David Fairweather on 6/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateSetPointViewController.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUClimateSetPointViewController () <SCUPickerViewDelegate>

@property (nonatomic) SCUPickerView *setPointPickerView;
@property (nonatomic) UILabel *currentSetPointValueLabel;
@property (nonatomic) UILabel *setPointHeaderLabel;
@property (nonatomic) UIColor *color;
@property (nonatomic) NSInteger setPointType;

@end

@implementation SCUClimateSetPointViewController

- (instancetype)initWithColorSchem:(UIColor *)color setPointType:(NSInteger)setPointType
{
    self = [super init];
    if (self)
    {
        self.color = color;
        self.setPointType = setPointType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.setPointPickerView = [[SCUPickerView alloc] initWithFrame:CGRectZero andConfiguration:SCUPickerViewConfigurationTwoArrowsVertical];
    if (!self.currentSetPointValueLabel)
    {
        self.currentSetPointValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    self.setPointHeaderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    self.setPointPickerView.delegate = self;
//    [self.setPointPickerView enlargeButtonsInPickerViewBySize:10.0f];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.text = self.headerString;
    headerLabel.textColor = [UIColor sav_colorWithRGBValue:0xFFFFFF];
    headerLabel.font = [UIFont fontWithName:@"Gotham" size:([UIDevice isPad] ? 20.0f : 16.0f)];
    
    [self.view addSubview:headerLabel];
    [self.view addSubview:self.setPointPickerView];
    [self.view addSubview:self.currentSetPointValueLabel];
    
    self.currentSetPointValueLabel.textColor = self.color;
    [self.setPointPickerView changeColorOfButtonsToColor:self.color];
   
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectZero];
    separatorView.backgroundColor = [[SCUColors shared] color03];
    separatorView.alpha = 0.3f;
    
    [self.view addSubview:separatorView];
    
    [self.view addConstraints:
     [NSLayoutConstraint sav_constraintsWithOptions:0
                                            metrics:@{
                                                      @"pickerWidth": @(50),
                                                      @"pickerHeight": @(90),
                                                      @"pickerRightOffset": @([UIDevice isPad] ? 80 : 10),
                                                      @"lineLocation": @([UIDevice isPad] ? 50 : 40)
                                                      }
                                              views:@{
                                                      @"headerLabel": headerLabel,
                                                      @"label": self.currentSetPointValueLabel,
                                                      @"picker": self.setPointPickerView,
                                                      @"separatorView": separatorView
                                                      }
                                            formats:@[
                                                      @"|-[headerLabel]",
                                                      @"|[separatorView]|",
                                                      @"V:|[headerLabel(lineLocation)][separatorView(1)][label]-|",
                                                      @"[label][picker(pickerWidth)]-(pickerRightOffset)-|",
                                                      @"picker.height = pickerHeight",
                                                      @"picker.centerY = label.centerY",
                                                      ]]];
}

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    [self.delegate climateAdjustmentWithDirection:direction forClimateSetPointType:self.setPointType];
}

- (void)setCurrentValueAttributedString:(NSAttributedString *)currentValueAttributedString
{
    _currentValueAttributedString = currentValueAttributedString;
    if (!self.currentSetPointValueLabel)
    {
        self.currentSetPointValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    self.currentSetPointValueLabel.attributedText = currentValueAttributedString;
    //[self.currentSetPointValueLabel sizeToFit];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.delegate climateAdjustmentDismissed];
}

@end
