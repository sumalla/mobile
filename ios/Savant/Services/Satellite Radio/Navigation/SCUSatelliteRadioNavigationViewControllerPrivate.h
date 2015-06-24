//
//  SCUSatelliteRadioNavigationViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioNavigationViewController.h"
#import "SCUPickerView.h"
#import "SCUButton.h"
#import "SCUNumberPadViewController.h"

@interface SCUSatelliteRadioNavigationViewController ()

@property SCUPickerView *channelPicker;
@property SCUPickerView *categoryPicker;
@property SCUNumberPadViewController *numberPad;
@property UILabel *channelLabel;
@property UILabel *categoryLabel;
@property UILabel *albumLabel;
@property UILabel *artistLabel;
@property UILabel *songLabel;
@property SCUButton *scanButton;

@end
