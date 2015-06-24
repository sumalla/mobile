//
//  SCUClimateHistoryDataFilterViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"

@protocol SCUClimateHistoryDataFilterDelegate;

@interface SCUClimateHistoryDataFilterViewController : SCUModelTableViewController

- (instancetype)initWithDelegate:(id <SCUClimateHistoryDataFilterDelegate>)delegate;

@end


