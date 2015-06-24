//
//  SCUMediaTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUMediaDataModel.h"

@interface SCUMediaTableViewController : SCUModelTableViewController

- (instancetype)initWithModel:(SCUMediaDataModel *)mediaModel;

@end
