//
//  SCULightingTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelExpandableTableViewController.h"
#import "SCULightingModel.h"

@interface SCULightingTableViewController : SCUModelExpandableTableViewController

- (instancetype)initWithModel:(SCULightingModel *)model;

@property (nonatomic, getter = isRoomImageAlwaysInTable) BOOL roomImageAlwaysInTable;

@end
