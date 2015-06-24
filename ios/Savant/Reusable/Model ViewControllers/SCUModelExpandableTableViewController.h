//
//  SCUModelExpandableTableViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelTableViewController.h"

@interface SCUModelExpandableTableViewController : SCUModelTableViewController

@property (nonatomic, readonly, strong) id<SCUExpandableDataSourceModel> tableViewModel;

- (void)toggleIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated updateBlock:(dispatch_block_t)update;
- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)removeParentRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation updateBlock:(dispatch_block_t)update;;
- (void)removeParentRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation  updateBlock:(dispatch_block_t)update;
- (void)addParentRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation;
- (void)addParentRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)reconfigureIndexPaths:(NSArray *)indexPaths;

@end

@interface SCUModelExpandableTableViewController (Optional)

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;

@end