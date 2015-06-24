//
//  SCUAVSettingsEqualizerSendToTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUAVSettingsEqualizerSendToModel.h"

@interface SCUAVSettingsEqualizerSendToTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUAVSettingsEqualizerSendToModel *)model;

- (void)updateModel:(SCUAVSettingsEqualizerSendToModel *)model;

@end
