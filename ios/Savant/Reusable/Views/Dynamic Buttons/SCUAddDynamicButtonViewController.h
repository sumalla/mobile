//
//  SCUAddDynamicButtonViewController.h
//  SavantController
//
//  Created by Jason Wolkovitz on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"

@class SCUAddDynamicButtonViewModel;
@protocol SCUAddDynamicButtonViewControllerDelegate;

@protocol SCUAddDynamicButtonViewControllerDelegate <NSObject>

- (void)finshedAddingObjects;
- (void)addButton:(NSDictionary *)button;

@end

@interface SCUAddDynamicButtonViewController : SCUModelTableViewController

@property SCUAddDynamicButtonViewModel *model;

@property (nonatomic, weak) id<SCUAddDynamicButtonViewControllerDelegate> delegate;

@end
