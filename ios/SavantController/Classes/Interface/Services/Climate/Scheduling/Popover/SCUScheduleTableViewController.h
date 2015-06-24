//
//  SCUScheduleTableViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUSchedulingModel.h"

@class SCUSchedulingModel;

@interface SCUScheduleTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUSchedulingModel *)model andType:(SCUScheduleTableType)type;

@end
