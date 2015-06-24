//
//  SCUPagingHorizontalFlowLayout.m
//  SavantController
//
//  Created by Cameron Pulsford on 2/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUPagingHorizontalFlowLayout.h"
@import Extensions;

@interface SCUPagingHorizontalFlowLayout ()

@property (nonatomic) CGSize itemSize;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) NSArray *layoutAttributes;
@property (nonatomic) CGRect lastFrame;

@end

@implementation SCUPagingHorizontalFlowLayout

- (void)invalidateLayout
{
    CGRect currentFrame = self.collectionView.frame;

    if (CGRectEqualToRect(currentFrame, self.lastFrame))
    {
        return;
    }

    self.lastFrame = currentFrame;
    [super invalidateLayout];
}

- (void)prepareLayout
{
    [super prepareLayout];

    self.collectionView.pagingEnabled = YES;

    CGRect frame = self.collectionView.frame;

    CGFloat totalWidth = CGRectGetWidth(frame);
    totalWidth -= self.interSpace * (self.numberOfColums - 1);
    totalWidth -= self.pageInset * 2;

    CGFloat width = totalWidth / self.numberOfColums;
    CGFloat height = CGRectGetHeight(frame) - (self.collectionView.contentInset.top + self.collectionView.contentInset.bottom);

    self.itemSize = CGSizeMake(width, height);
    CGFloat totalContentWidth = 0;

    if (self.collectionView.numberOfSections == 1)
    {
        NSMutableArray *layoutAttributes = [NSMutableArray array];

        NSUInteger numberOfItems = (NSUInteger)[self.collectionView numberOfItemsInSection:0];

        CGFloat runningX = 0;
        NSUInteger numberOfPages = 0;

        for (NSUInteger i = 0; i < numberOfItems; i++)
        {
            NSUInteger mod = i % self.numberOfColums;

            if (mod == 0)
            {
                numberOfPages++;
                runningX += self.pageInset;
            }
            else
            {
                runningX += self.interSpace;
            }

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

            CGRect frame = CGRectZero;
            frame.size = self.itemSize;
            frame.origin.y = self.collectionView.contentInset.top;
            frame.origin.x = runningX;
            attributes.frame = frame;
            [layoutAttributes addObject:attributes];

            runningX += self.itemSize.width;

            if (mod == self.numberOfColums - 1)
            {
                runningX += self.pageInset;
            }
        }

        self.layoutAttributes = layoutAttributes;

        totalContentWidth = CGRectGetWidth(self.collectionView.frame) * numberOfPages;
    }

    self.contentSize = CGSizeMake(totalContentWidth, self.itemSize.height);
}

- (CGSize)collectionViewContentSize
{
    return self.contentSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutAttributes[indexPath.row];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return [self.layoutAttributes filteredArrayUsingBlock:^BOOL(UICollectionViewLayoutAttributes *attribute) {
        return CGRectIntersectsRect(rect, attribute.frame);
    }];
}

@end
