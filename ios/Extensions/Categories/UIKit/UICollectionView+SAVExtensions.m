//
//  UICollectionView+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UICollectionView+SAVExtensions.h"

@implementation UICollectionView (SAVExtensions)

- (void)sav_registerClass:(Class)cellClass forCellType:(NSUInteger)cellType
{
    [self registerClass:cellClass forCellWithReuseIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)cellType]];
}

- (void)sav_registerClass:(Class)cellClass forSupplementaryViewOfKind:(NSString *)elementKind forCellType:(NSUInteger)cellType
{
    [self registerClass:cellClass forSupplementaryViewOfKind:elementKind withReuseIdentifier:[NSString stringWithFormat:@"%@%lu", elementKind, (unsigned long)cellType]];
}

- (void)sav_reloadItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated
{
    [UIView setAnimationsEnabled:animated];

    [self performBatchUpdates:^{
        [self reloadItemsAtIndexPaths:indexPaths];
    } completion:^(BOOL finished) {
        [UIView setAnimationsEnabled:YES];
    }];
}

@end
