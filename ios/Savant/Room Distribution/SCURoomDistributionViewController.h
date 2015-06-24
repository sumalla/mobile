//
//  SCURoomDistributionViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelExpandableTableViewController.h"

@class SAVServiceGroup;

@interface SCURoomDistributionViewController : SCUModelExpandableTableViewController

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service;

@end
