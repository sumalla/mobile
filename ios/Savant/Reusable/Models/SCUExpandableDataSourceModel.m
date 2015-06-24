//
//  SCUExpandableDataSourceModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@interface SCUExpandableDataSourceModel ()

@property (nonatomic)  NSArray *expandedIndexPaths;

@end

@implementation SCUExpandableDataSourceModel

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    if ([self isFlat])
    {
        numberOfRows = [self.dataSource count];
    }
    else
    {
        numberOfRows = [[self arrayForSection:section] count];
    }

    for (NSIndexPath *expandedIndexPath in self.expandedIndexPaths)
    {
        if (expandedIndexPath.section == section)
        {
            numberOfRows += [self numberOfChildrenBelowIndexPath:expandedIndexPath];
        }
    }

    return numberOfRows;
}

#pragma mark - Expandable

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSUInteger)cellTypeForAbsoluteIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [self parentForAbsoluteIndexPath:indexPath];
    NSIndexPath *relativeIndexPath = [self relativeIndexPathForAbsoluteIndexPath:indexPath];

    if (parentIndexPath)
    {
        return [self cellTypeForChild:relativeIndexPath belowIndexPath:parentIndexPath];
    }
    else
    {
        return [self cellTypeForIndexPath:relativeIndexPath];
    }
}

- (id)modelObjectForAbsoluteIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [self parentForAbsoluteIndexPath:indexPath];
    NSIndexPath *relativeIndexPath = [self relativeIndexPathForAbsoluteIndexPath:indexPath];

    if (parentIndexPath)
    {
        return [self modelObjectForChild:relativeIndexPath belowIndexPath:parentIndexPath];
    }
    else
    {
        return [self modelObjectForIndexPath:relativeIndexPath];
    }
}

- (void)updateExpandedIndexPaths:(NSArray *)expandedIndexPaths
{
    self.expandedIndexPaths = expandedIndexPaths;
}

- (BOOL)toggleIndexPath:(NSIndexPath *)relativeIndex
{
    BOOL didExpand = NO;
    NSMutableArray *expandedIndexPaths = [NSMutableArray arrayWithArray:self.expandedIndexPaths];

    if ([expandedIndexPaths containsObject:relativeIndex])
    {
        [expandedIndexPaths removeObject:relativeIndex];
    }
    else
    {
        [expandedIndexPaths addObject:relativeIndex];
        didExpand = YES;
    }

    self.expandedIndexPaths = expandedIndexPaths;

    return didExpand;
}

- (NSInteger)numberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath
{
    return [[self dataSourceBelowIndexPath:indexPath] count];
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (id)modelObjectForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return [self dataSourceBelowIndexPath:indexPath][child.row];
}

#pragma mark - Index Path Conversion

- (NSIndexPath *)absoluteIndexPathForRelativeIndexPath:(NSIndexPath *)indexPath
{
    return [NSIndexPath indexPathForRow:indexPath.row + [self expandedRowsBeforeIndexPath:indexPath] inSection:indexPath.section];
}

- (NSIndexPath *)absoluteIndexPathForRelativeChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return [NSIndexPath indexPathForRow:(indexPath.row + [self expandedRowsBeforeIndexPath:indexPath] + 1 + child.row) inSection:indexPath.section];
}

- (NSIndexPath *)relativeIndexPathForAbsoluteIndexPath:(NSIndexPath *)indexPath
{
    return [self _searchForParentAndRelativeIndexPaths:indexPath][@"relative"];
}

- (NSIndexPath *)parentForAbsoluteIndexPath:(NSIndexPath *)indexPath
{
    return [self _searchForParentAndRelativeIndexPaths:indexPath][@"parent"];
}

- (NSDictionary *)_searchForParentAndRelativeIndexPaths:(NSIndexPath *)indexPath
{
    NSIndexPath *relativeIndexPath = nil;
    NSIndexPath *parentPath = nil;

    NSInteger expandedRowsBefore = 0;
    NSInteger expandedRows = 0;
    NSIndexPath *previousExpandedPath = nil;

    NSInteger numberOfItemsInSection = [self numberOfItemsInSection:indexPath.section];
    for (NSInteger i = 0; i < numberOfItemsInSection; i++)
    {
        NSInteger relativeRow = i - expandedRowsBefore;

        //-------------------------------------------------------------------
        // This is a child cell, continue until the next parent
        //-------------------------------------------------------------------
        if (previousExpandedPath)
        {
            NSInteger childRow = relativeRow - previousExpandedPath.row - 1;

            if (childRow < expandedRows)
            {
                parentPath = previousExpandedPath;
                relativeIndexPath = [NSIndexPath indexPathForRow:relativeRow - previousExpandedPath.row - 1 inSection:indexPath.section];

                if (i == indexPath.row)
                {
                    break;
                }
                
                continue;
            }
        }

        parentPath = nil;
        expandedRowsBefore += expandedRows;
        previousExpandedPath = nil;
        expandedRows = 0;

        relativeIndexPath = [NSIndexPath indexPathForRow:i - expandedRowsBefore inSection:indexPath.section];

        if ([self.expandedIndexPaths containsObject:relativeIndexPath])
        {
            expandedRows = [self numberOfChildrenBelowIndexPath:relativeIndexPath];

            previousExpandedPath = relativeIndexPath;
        }

        if (i == indexPath.row)
        {
            break;
        }
    }

    NSMutableDictionary *results = [NSMutableDictionary dictionary];

    if (relativeIndexPath)
    {
        results[@"relative"] = relativeIndexPath;
    }

    if (parentPath)
    {
        results[@"parent"] = parentPath;
    }
    
    return results;
}

- (NSInteger)expandedRowsBeforeIndexPath:(NSIndexPath *)indexPath
{
    NSInteger expandedRowsBefore = 0;

    for (NSIndexPath *expandedPath in self.expandedIndexPaths)
    {
        if (expandedPath.section == indexPath.section && expandedPath.row < indexPath.row)
        {
            expandedRowsBefore += [self numberOfChildrenBelowIndexPath:expandedPath];
        }
    }
    
    return expandedRowsBefore;
}

@end
