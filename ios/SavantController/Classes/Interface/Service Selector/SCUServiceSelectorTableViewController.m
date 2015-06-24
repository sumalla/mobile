//
//  SCUServiceSelectorTableViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceSelectorTableViewController.h"
#import "SCUServiceSelectorModel.h"
#import "SCUServiceSelectorTableViewCell.h"
#import "SCUToolbar.h"
#import "SCUToolbarButton.h"
#import "SCUNavigationBar.h"
#import "SCUPlaceholderTableViewCell.h"

@interface SCUServiceSelectorTableViewController () <SCUServiceSelectorModelDelegate>

@property (nonatomic) SCUServiceSelectorModel *model;

@end

@implementation SCUServiceSelectorTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.90];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.model = [[SCUServiceSelectorModel alloc] init];
    self.model.delegate = self;

    self.tableView.delaysContentTouches = NO;
    self.tableView.rowHeight = [UIDevice isPhone] ? 60 : 70;

    self.tableView.contentInset = UIEdgeInsetsMake(-19, 0, 0, 0);
}

#pragma mark - Methods to subclass

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUServiceSelectorTableViewCell class] forCellType:SCUServiceSelectorModelCellTypeNormal];
    [self.tableView sav_registerClass:[SCUPlaceholderTableViewCell class] forCellType:SCUServiceSelectorModelCellTypePlaceholder];
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUServiceSelectorModelCellType cellType = (SCUServiceSelectorModelCellType)type;

    switch (cellType)
    {
        case SCUServiceSelectorModelCellTypeNormal:
        {
            SCUServiceSelectorTableViewCell *c = (SCUServiceSelectorTableViewCell *)cell;
            [self.model listenToPowerButton:c.powerButton forIndexPath:indexPath];
            break;
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUServiceSelectorModelCellType cellType = (SCUServiceSelectorModelCellType)type;

    switch (cellType)
    {
        case SCUServiceSelectorModelCellTypeNormal:
        {
            SCUServiceSelectorTableViewCell *c = (SCUServiceSelectorTableViewCell *)cell;
            [self.model listenToPowerButton:c.powerButton forChildIndexPath:child below:indexPath];
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.1;

    if (section == 0)
    {
        height = 20;
    }

    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.1;
}

#pragma mark - SCUServiceSelectorModelDelegate methods

- (void)reloadTable
{
    [self.tableView reloadData];
}

- (void)resetTableToTop
{
    [self.tableView sav_scrollToTop];
}

- (void)toggleIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        if ([[self.model expandedIndexPaths] containsObject:indexPath])
        {
            [self toggleIndex:indexPath animated:YES];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.tableView endUpdates];
            });
        }
        else
        {
            [self.tableView beginUpdates];
            [self toggleIndex:indexPath animated:YES];
            [(SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath] configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
            [self.tableView endUpdates];
        }
    }

    if ([[self.model expandedIndexPaths] containsObject:indexPath])
    {
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        NSInteger numberOfCells = [self.model numberOfChildrenBelowIndexPath:indexPath] + 2;

        NSUInteger index = [visibleIndexPaths indexOfObject:indexPath];

        if (([visibleIndexPaths count] - index) < (NSUInteger)numberOfCells)
        {
            dispatch_async_main(^{
                NSIndexPath *absoluteIndexPath = [self.model absoluteIndexPathForRelativeIndexPath:indexPath];
                [self.tableView scrollToRowAtIndexPath:absoluteIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            });
        }
    }
}

@end
