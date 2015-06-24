//
//  SCUSecurityPanelViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityPanelViewController.h"
#import "SCUSecurityPanelModel.h"
#import "SCUNumberPadViewController.h"
#import "SCUButtonViewController.h"
#import "SCUPickerView.h"
#import "SCUButton.h"
#import "SCUSensorLabel.h"

@interface SCUSecurityPanelViewController ()

@property SCUSecurityPanelModel *model;
@property SCUNumberPadViewController *numberPad;
@property SCUButtonViewController *panicButtons;
@property SCUButtonViewController *disarmButtons;
@property SCUPickerView *menuPicker;
@property SCUPickerView *userPicker;
@property UIView *pickerViews;
@property UILabel *label1;
@property UILabel *label2;
@property UILabel *label3;
@property UILabel *partitionTitle;
@property UILabel *armingStatusTitle;
@property SCUButton *partitionSelector;
@property SCUButton *systemSelector;
@property SCUButton *armingSelector;
@property UILabel *unknownLabel;
@property UILabel *criticalLabel;
@property UILabel *troubleLabel;
@property SCUSensorLabel *unknownCount;
@property SCUSensorLabel *troubleCount;
@property SCUSensorLabel *criticalCount;

@end
