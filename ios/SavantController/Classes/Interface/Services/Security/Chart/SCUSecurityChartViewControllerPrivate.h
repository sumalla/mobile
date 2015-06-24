//
//  SCUSecurityChartViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityChartViewController.h"
#import "SCUSecurityChartModel.h"
#import "SCUButton.h"
#import "SCUSensorTableViewController.h"

@interface SCUSecurityChartViewController ()

@property SCUSecurityChartModel *model;
@property UILabel *roomsTitle;
@property SCUButton *roomsSelector;
@property SCUButton *systemSelector;

@property SCUButton *criticalButton;
@property SCUButton *troubleButton;
@property SCUButton *unknownButton;
@property SCUButton *readyButton;
@property SCUButton *allButton;

@property SCUSensorTableViewController *sensorTableViewController;

@end