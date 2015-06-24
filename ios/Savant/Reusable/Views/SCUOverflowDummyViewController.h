//
//  SCUTVOverlayTableViewController.h
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUServiceViewController.h"

@class SCUOverflowViewController, SCUOverflowTableViewController;

@interface SCUOverflowDummyViewController : SCUServiceViewController

- (instancetype)initWithService:(SAVService *)service andTableViewController:(SCUOverflowTableViewController *)tableView;

@property (nonatomic) NSInteger preferredIndex;

@property (nonatomic, weak) SCUServiceTabBarController *tabController;

@end
