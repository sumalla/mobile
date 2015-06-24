//
//  SCUCDServiceViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCDServiceViewModel.h"
#import "SCUPickerView.h"
#import "SCUButton.h"
#import "SCUNumberPadViewController.h"
#import "SCUButtonViewController.h"

@interface SCUCDServiceViewController ()

@property SCUPickerView *diskPicker;
@property SCUPickerView *trackPicker;
@property SCUNumberPadViewController *numberPad;
@property SCUButtonViewController *transportControls;
@property SCUButtonViewController *openClose;
@property SCUButtonViewController *buttonPanel;
@property SCUButton *shuffleButton;
@property SCUButton *repeatButton;
@property UILabel *diskLabel;
@property UILabel *trackLabel;
@property UILabel *progressLabel;

@property (nonatomic) SCUCDServiceViewModel *model;

@end