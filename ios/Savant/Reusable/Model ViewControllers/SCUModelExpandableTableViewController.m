//
//  SCUModelExpandableTableViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;
#import "SCUModelExpandableTableViewController.h"

@interface SCUModelExpandableTableViewController ()

@property (nonatomic) NSIndexPath *animatingIndexPath;

@end

@implementation SCUModelExpandableTableViewController

- (void)toggleIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    BOOL didExpand = [[self tableViewModel] toggleIndexPath:indexPath];

    if (animated)
    {
        [self.tableView beginUpdates];

        NSIndexPath *realIndexPath = [[self tableViewModel] absoluteIndexPathForRelativeIndexPath:indexPath];
        NSMutableArray *indexPaths = [NSMutableArray array];
        NSInteger numberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
        for (NSInteger i = 1; i <= numberOfChildren; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
        }

        if (didExpand)
        {
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        }
        else
        {
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        }

        [self.tableView endUpdates];
    }
    else
    {
        [self.tableView reloadData];
    }
}

- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if ([[[self tableViewModel] expandedIndexPaths] containsObject:indexPath])
    {
        [[self tableViewModel] toggleIndexPath:indexPath];


        if (animated)
        {
            [self.tableView beginUpdates];

            NSIndexPath *realIndexPath = [[self tableViewModel] absoluteIndexPathForRelativeIndexPath:indexPath];
            NSMutableArray *indexPaths = [NSMutableArray array];
            NSInteger numberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
            for (NSInteger i = 1; i <= numberOfChildren; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
            }

            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView reloadData];
        }
    }
}

- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (![[[self tableViewModel] expandedIndexPaths] containsObject:indexPath])
    {
        [[self tableViewModel] toggleIndexPath:indexPath];


        if (animated)
        {
            [self.tableView beginUpdates];

            NSIndexPath *realIndexPath = [[self tableViewModel] absoluteIndexPathForRelativeIndexPath:indexPath];
            NSMutableArray *indexPaths = [NSMutableArray array];
            NSInteger numberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
            for (NSInteger i = 1; i <= numberOfChildren; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
            }

            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];

            [self.tableView endUpdates];
        }
        else
        {
            [self.tableView reloadData];
        }
    }
}

- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated updateBlock:(dispatch_block_t)update
{
    [self.tableView beginUpdates];

    NSInteger originalNumberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
    update();
    NSInteger numberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
    NSIndexPath *realIndexPath = [[self tableViewModel] absoluteIndexPathForRelativeIndexPath:indexPath];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSMutableArray *reloadIndexPaths = [NSMutableArray array];

    if (originalNumberOfChildren > numberOfChildren)
    {
        for (NSInteger i = 1; i <= originalNumberOfChildren; i++)
        {
            if (i > numberOfChildren)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
            }
            else
            {
                if (i <= numberOfChildren)
                {
                    [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
                }
            }
        }

        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    else if (originalNumberOfChildren < numberOfChildren)
    {
        for (NSInteger i = 1; i <= numberOfChildren; i++)
        {
            if (i > originalNumberOfChildren)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
            }
            else
            {
                [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
            }
        }

        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
    else
    {
        for (NSInteger i = 1; i <= numberOfChildren; i++)
        {
            [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
        }
    }

    [self.tableView reloadRowsAtIndexPaths:reloadIndexPaths withRowAnimation:UITableViewRowAnimationNone];

    [self.tableView endUpdates];
}

- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    NSIndexPath *realIndexPath = [[self tableViewModel] absoluteIndexPathForRelativeIndexPath:indexPath];
    NSMutableArray *indexPaths = [NSMutableArray array];

    NSInteger numberOfChildren = [[self tableViewModel] numberOfChildrenBelowIndexPath:indexPath];
    for (NSInteger i = 1; i <= numberOfChildren; i++)
    {
        [indexPaths addObject:[NSIndexPath indexPathForRow:realIndexPath.row + i inSection:indexPath.section]];
    }

    if (animated)
    {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUDefaultTableViewCell *cell = nil;

    NSIndexPath *parentIndexPath = [[self tableViewModel] parentForAbsoluteIndexPath:indexPath];
    NSIndexPath *relativeIndexPath = [[self tableViewModel] relativeIndexPathForAbsoluteIndexPath:indexPath];

    if (parentIndexPath)
    {
        NSUInteger type = [[self tableViewModel] cellTypeForChild:relativeIndexPath belowIndexPath:parentIndexPath];

        NSString *identifier = [NSString stringWithFormat:@"%lu", (unsigned long)type];

        cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

        [cell configureWithInfo:[[self tableViewModel] modelObjectForChild:relativeIndexPath belowIndexPath:parentIndexPath]];

        if ([self respondsToSelector:@selector(configureCell:withType:forChild:belowIndexPath:)])
        {
            [self configureCell:cell withType:type forChild:relativeIndexPath belowIndexPath:parentIndexPath];
        }

        if ([[self tableViewModel] respondsToSelector:@selector(configureCell:withType:forChild:belowIndexPath:)])
        {
            [[self tableViewModel] configureCell:cell withType:type forChild:relativeIndexPath belowIndexPath:parentIndexPath];
        }

        cell.numberOfRowsInSection = [[self tableViewModel] numberOfChildrenBelowIndexPath:parentIndexPath];
    }
    else
    {
        NSUInteger type = [[self tableViewModel] cellTypeForIndexPath:relativeIndexPath];

        NSString *identifier = [NSString stringWithFormat:@"%lu", (unsigned long)type];

        cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

        [cell configureWithInfo:[[self tableViewModel] modelObjectForIndexPath:relativeIndexPath]];

        if ([self respondsToSelector:@selector(configureCell:withType:indexPath:)])
        {
            [self configureCell:cell withType:type indexPath:relativeIndexPath];
        }

        if ([[self tableViewModel] respondsToSelector:@selector(configureCell:withType:indexPath:)])
        {
            [[self tableViewModel] configureCell:cell withType:type indexPath:relativeIndexPath];
        }

        cell.numberOfRowsInSection = [[self tableViewModel] numberOfItemsInSection:relativeIndexPath.section];
    }

    cell.indexPath = relativeIndexPath;

    return cell;
}

- (void)reconfigureIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        [self reconfigureIndexPath:indexPath];
    }
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *absolutePath = [self.tableViewModel absoluteIndexPathForRelativeIndexPath:indexPath];
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:absolutePath];
    [cell configureWithInfo:[self.tableViewModel modelObjectForIndexPath:indexPath]];
}

- (void)removeParentRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation updateBlock:(dispatch_block_t)update
{
    [self removeParentRowsAtIndexPaths:@[indexPath] withRowAnimation:animation updateBlock:update];
}

- (void)removeParentRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation updateBlock:(dispatch_block_t)update
{
    NSMutableArray *absoluteIndexPaths = [[indexPaths arrayByMappingBlock:^id(NSIndexPath *index) {
        return [self.tableViewModel absoluteIndexPathForRelativeIndexPath:index];
    }] mutableCopy];
    
    for (NSIndexPath *index in indexPaths)
    {
        if ([[self.tableViewModel expandedIndexPaths] containsObject:index])
        {
            NSInteger children = [self.tableViewModel numberOfChildrenBelowIndexPath:index];
            for (NSInteger i = 1; i <= children; i++)
            {
                NSIndexPath *indexPath = [self.tableViewModel absoluteIndexPathForRelativeIndexPath:index];
                [absoluteIndexPaths addObject:[NSIndexPath indexPathForRow:indexPath.row + i inSection:indexPath.section]];
            }
            
            NSMutableArray *expanded = [[self.tableViewModel expandedIndexPaths] mutableCopy];
            [expanded removeObject:index];
            [self.tableViewModel updateExpandedIndexPaths:expanded];
        }
    }

	if (update)
		update();
    
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:15 options:0 animations:^{
        NSArray *expandedIndexPaths;
        
        for (NSIndexPath *indexPath in indexPaths)
        {
            expandedIndexPaths = [[self.tableViewModel expandedIndexPaths] arrayByMappingBlock:^id(NSIndexPath *index) {
                NSInteger row = (index.row > indexPath.row) ? index.row - 1 : index.row;
                return [NSIndexPath indexPathForRow:row inSection:indexPath.section];
            }];
            [self.tableViewModel updateExpandedIndexPaths:expandedIndexPaths];
        }

        [self.tableView deleteRowsAtIndexPaths:absoluteIndexPaths withRowAnimation:animation];
    } completion:^(BOOL finished) {
		//required to be called after all animations complete or the view flases and also crashes on add if reloadData is not called.
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
		});
	}];
}

- (void)addParentRowAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation
{
    [self addParentRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
}

- (void)addParentRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
    [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:15 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        for (NSIndexPath *indexPath in indexPaths)
        {
            NSArray *expandedIndexPaths = [[self.tableViewModel expandedIndexPaths] arrayByMappingBlock:^id(NSIndexPath *index) {
                NSInteger row = (index.row >= indexPath.row) ? index.row + 1 : index.row;
                return [NSIndexPath indexPathForRow:row inSection:indexPath.section];
            }];

            [self.tableViewModel updateExpandedIndexPaths:expandedIndexPaths];
        }
		
		NSMutableArray *absoluteIndexPaths = [NSMutableArray new];
		for (NSIndexPath *index in indexPaths)
		{
			if ((NSUInteger)index.row < self.tableViewModel.dataSource.count)
				[absoluteIndexPaths addObject:index];
		}
		
        [self.tableView insertRowsAtIndexPaths:absoluteIndexPaths withRowAnimation:animation];

    } completion:^(BOOL finished) {
		[self.tableView reloadData];
	}];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [[self tableViewModel] parentForAbsoluteIndexPath:indexPath];
    NSIndexPath *relativeIndex = [[self tableViewModel] relativeIndexPathForAbsoluteIndexPath:indexPath];

    if (parentIndexPath)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        if ([self.tableViewModel respondsToSelector:@selector(selectChild:belowIndexPath:)])
        {
            [[self tableViewModel] selectChild:relativeIndex belowIndexPath:parentIndexPath];
        }
    }
    else
    {
        if ([self.tableViewModel respondsToSelector:@selector(shouldDeselectRowAtIndexPath:)])
        {
            if ([self.tableViewModel shouldDeselectRowAtIndexPath:relativeIndex])
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }

        if ([self.tableViewModel respondsToSelector:@selector(selectItemAtIndexPath:)])
        {
            [[self tableViewModel] selectItemAtIndexPath:relativeIndex];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self respondsToSelector:@selector(heightForCellWithType:)])
    {
        return [self heightForCellWithType:[[self tableViewModel] cellTypeForAbsoluteIndexPath:indexPath]];
    }
    else
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
