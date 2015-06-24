//
//  SCUAVVideoSettingsViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUAVSettingsVideoModel.h"

@class SCUAVSettingsVideoSelectModel;

@interface SCUAVSettingsVideoTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUAVSettingsVideoModel *)model;

@end
