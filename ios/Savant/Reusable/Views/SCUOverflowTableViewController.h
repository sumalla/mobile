//
//  SCUOverflowTableViewController.h
//  SavantController
//
//  Created by Stephen Silber on 2/11/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"
#import "SCUModelTableViewController.h"
#import "SCUOverflowTableViewModel.h"

@protocol SCUOverlayDelegate <NSObject>

- (void)willDismissTableViewControllerWithCancelled:(BOOL)cancelled;

@end

@interface SCUOverflowTableViewController : SCUModelTableViewController

- (instancetype)initWithService:(SAVService *)service;

- (SCUServiceViewModel *)serviceViewModel;

@property (nonatomic, weak) id<SCUOverlayDelegate> delegate;

@property (nonatomic) BOOL reorderEnabled;

@end
