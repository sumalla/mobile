//
//  SCUModelTableViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"
#import "SCUDefaultTableViewCell.h"

@interface SCUModelTableViewController : UITableViewController

#pragma mark - Methods to subclass

@property (nonatomic, readonly) UITableViewStyle preferredTableViewStyle;

@property (nonatomic, readonly, strong) id<SCUDataSourceModel> tableViewModel;

- (CGFloat)defaultRowHeight;

- (void)reconfigureCells;

@end

@interface SCUModelTableViewController (Optional)

- (void)registerCells;

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath;

- (void)configureHeader:(UIView *)header withType:(NSUInteger)type section:(NSInteger)section;

- (CGFloat)heightForCellWithType:(NSUInteger)type;

@end
