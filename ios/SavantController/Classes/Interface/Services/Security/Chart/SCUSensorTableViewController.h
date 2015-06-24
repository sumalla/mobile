//
//  SCUSensorTableViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"

@class SCUSecurityChartModel;

@interface SCUSensorTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUSecurityChartModel *)model;

@end
