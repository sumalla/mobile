//
//  SCUTVOverlayAddButtonTableViewController.h
//  SavantController
//
//  Created by Stephen Silber on 2/3/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUOverflowTableViewController.h"

@class SCUOverflowTableViewModel;

@interface SCUOverflowAddButtonTableViewController : SCUOverflowTableViewController

- (instancetype)initWithService:(SAVService *)service andModel:(SCUOverflowTableViewModel *)model;

- (void)setAdding:(BOOL)adding;

@end
