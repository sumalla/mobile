//
//  SCUTableViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@implementation SCUDataSourceModel

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    return [self _modelObjectForIndexPath:indexPath];
}

- (id)_modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *modelObject = nil;

    if ([self isFlat])
    {
        modelObject = self.dataSource[indexPath.row];
    }
    else
    {
        modelObject = [self arrayForSection:indexPath.section][indexPath.row];
    }

    return modelObject;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (NSInteger)numberOfSections
{
    NSInteger numberOfSections = 1;

    if (![self isFlat])
    {
        return [self.dataSource count];
    }

    return numberOfSections;
}

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

    return numberOfRows;
}

#pragma mark - 

- (BOOL)isFlat
{
    return YES;
}

- (NSArray *)arrayForSection:(NSInteger)section
{
    return self.dataSource[section];
}

- (void)enumerateModelObjects:(void (^)(NSIndexPath *indexPath))enumerator
{
    NSParameterAssert(enumerator);

    if ([self isFlat])
    {
        [self.dataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            enumerator([NSIndexPath indexPathForItem:idx inSection:0]);
        }];
    }
    else
    {
        NSInteger numberOfSections = [self numberOfSections];

        for (NSInteger section = 0; section < numberOfSections; section++)
        {
            //-------------------------------------------------------------------
            // Doing it this way (instead of using numberOfItemsInSection) works
            // better with expandable data sources.
            //-------------------------------------------------------------------
            NSInteger numberOfItems = [[self arrayForSection:section] count];

            for (NSInteger item = 0; item < numberOfItems; item++)
            {
                enumerator([NSIndexPath indexPathForItem:item inSection:section]);
            }
        }
    }
}

- (BOOL)isIndexPathValid:(NSIndexPath *)indexPath
{
    BOOL valid = NO;

    if (indexPath.section < [self numberOfSections])
    {
        if (indexPath.row < [self numberOfItemsInSection:indexPath.section])
        {
            valid = YES;
        }
    }

    return valid;
}

@end
