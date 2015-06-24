//
//  SCUAVSettingsEqualizerPresetTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUAVSettingsEqualizerPresetModel.h"

@interface SCUAVSettingsEqualizerPresetTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUAVSettingsEqualizerPresetModel *)model;

- (void)updateModel:(SCUAVSettingsEqualizerPresetModel *)model;

@end
