//
//  SCURadioNavigationViewControllerPrivate.h
//  SavantController
//
//  Created by David Fairweather on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSliderView.h"
#import "SCUButton.h"
#import "SCUPickerView.h"
#import "SCURadioNavigationViewController.h"
#import "SCURadioNavigationViewModel.h"
#import "SCUNumberPadViewController.h"

@interface SCURadioNavigationViewController ()

@property (nonatomic) SCURadioNavigationViewModel *model;

@property (nonatomic) UIView *tunerStripView;
@property (nonatomic) SCUSliderView *sliderView;
@property (nonatomic) SCUPickerView *tunePicker;
@property (nonatomic) SCUPickerView *seekPicker;
@property (nonatomic) SCUButton *AMButton;
@property (nonatomic) SCUButton *FMButton;
@property (nonatomic) SCUButton *scanButton;
@property (nonatomic) SCUButton *favoritesButton;
@property (nonatomic) UILabel *currentFrequencyLabel;
@property (nonatomic) UILabel *bandLabel;
@property (nonatomic) UILabel *MHzLabel;

@property (nonatomic) BOOL isFirstLoading;

@property (nonatomic) CGFloat tunerStripWidth;
@property (nonatomic) CGFloat tunerStripHeight;
@property (nonatomic) CGFloat numberPadHeight;
@property (nonatomic) CGFloat numberPadWidth;
@property (nonatomic) CGFloat topPadding;
@property (nonatomic) CGFloat pickerWidth;
@property (nonatomic) CGFloat buttonSpacing;
@property (nonatomic) CGFloat bandLabelSize;
@property (nonatomic) CGFloat buttonWidth;
@property (nonatomic) CGFloat scanButtonWidth;
@property (nonatomic) CGFloat OffsetFromFrequencyLabel_X;
@property (nonatomic) CGFloat OffsetFromFrequencyLabel_Y;

@property (nonatomic) UIView *sliderBackground;
@property (nonatomic) CGFloat sliderViewHeight;

@property (nonatomic) UIView *numberPadInfoBox;
@property (nonatomic) UIView *numberPadContainer;
@property (nonatomic) UILabel *numberPadInfoBoxLabel;
@property (weak) NSTimer *numberTimeOutTimer;
@property (nonatomic) NSTimeInterval numberPadDefaultVisableTime;

@property (nonatomic) SCUButtonViewController *numberPad;

@end
