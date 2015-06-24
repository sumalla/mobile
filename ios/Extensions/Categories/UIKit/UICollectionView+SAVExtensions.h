//
//  UICollectionView+SAVExtensions.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UICollectionView (SAVExtensions)

- (void)sav_registerClass:(Class)cellClass forCellType:(NSUInteger)cellType;
- (void)sav_registerClass:(Class)cellClass forSupplementaryViewOfKind:(NSString *)elementKind forCellType:(NSUInteger)cellType;
- (void)sav_reloadItemsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated;

@end
