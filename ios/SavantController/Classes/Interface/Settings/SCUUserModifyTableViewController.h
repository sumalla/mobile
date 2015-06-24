//
//  SCUCreateInviteTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import <SavantControl/SavantControl.h>

@interface SCUUserModifyTableViewController : SCUModelTableViewController

- (instancetype)initWithCloudUser:(SAVCloudUser *)user;

@end
