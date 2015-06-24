//
//  SCUTVOverlayViewController.h
//  SavantController
//
//  Created by Stephen Silber on 2/3/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"
#import "SCUServiceViewController.h"

@class SAVService, SCUOverflowDummyViewController, SCUOverflowTableViewController;

@protocol SCUOverflowPresentationDelegate <NSObject>

- (void)willDismissViewControllerWithCancelled:(BOOL)cancel;

@end

@interface SCUOverflowViewController : SCUServiceViewController

- (instancetype)initWithService:(SAVService *)service andTableViewController:(SCUOverflowTableViewController *)tableView;

- (void)willDismissTableViewControllerWithCancelled:(BOOL)cancelled;

@property (nonatomic, weak) id<SCUOverflowPresentationDelegate> delegate;

@end