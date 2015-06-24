//
//  SCUSchedulingCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultCollectionViewCell.h"

@protocol SCUSchedulingCellDelegate;
@class SCUSchedulingEditingViewController;

@interface SCUSchedulingCell : SCUDefaultCollectionViewCell

@property (nonatomic, weak) SCUSchedulingEditingViewController *editingViewController;
@property (nonatomic, weak) id <SCUSchedulingCellDelegate> delegate;

@end


@protocol SCUSchedulingCellDelegate <NSObject>

- (void)reloadDataForCell:(SCUSchedulingCell *)cell;
- (SCUSchedulingEditingViewController *)editingViewControllerForCell:(SCUSchedulingCell *)cell;

@end