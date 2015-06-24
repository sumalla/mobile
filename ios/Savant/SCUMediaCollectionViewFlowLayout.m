//
//  SCUMediaCollectionViewFlowLayout.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaCollectionViewFlowLayout.h"

@implementation SCUMediaCollectionViewFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];

    self.sectionInset = UIEdgeInsetsMake(self.padding, 0, self.padding, 0);
    self.minimumInteritemSpacing = self.padding;
    self.minimumLineSpacing = self.padding;

    CGFloat size = (CGRectGetWidth(self.collectionView.bounds) - ((self.numberOfColumns - 1) * self.padding)) / self.numberOfColumns;
    self.itemSize = CGSizeMake(size, size);
}

@end
