//
//  SCUCollectionViewPagedLayout.m
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCollectionViewPagedLayout.h"

@import Extensions;

@interface SCUCollectionViewPagedLayout ()

@property NSMutableDictionary *itemAttributes;

@end

@implementation SCUCollectionViewPagedLayout

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setup];
    }

    return self;
}

- (void)setup
{
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

- (void)prepareLayout
{
    NSMutableDictionary *itemAttributes = [NSMutableDictionary dictionary];

    NSInteger sectionCount = [self.collectionView numberOfSections];
    NSIndexPath *indexPath;

    for (NSInteger section = 0; section < sectionCount; section++)
    {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];

        for (NSInteger item = 0; item < itemCount; item++)
        {
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];

            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = [self frameForItemAtIndexPath:indexPath];

            itemAttributes[indexPath] = attributes;
        }
    }

    self.itemAttributes = itemAttributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return  [[self.itemAttributes allValues] filteredArrayUsingBlock:^BOOL(UICollectionViewLayoutAttributes *attributes) {
        BOOL keep = NO;

        if (CGRectIntersectsRect(rect, attributes.frame))
        {
            keep = YES;
        }

        return keep;
    }];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.itemAttributes)[indexPath];
}

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger page = indexPath.section;
    NSInteger indexRelativeToThisPage = indexPath.item;

    NSInteger column = indexRelativeToThisPage % self.numberOfColumns;
    NSInteger row    = indexRelativeToThisPage / self.numberOfColumns;

    CGFloat originX = floor((self.itemSize.width + self.spaceBetweenItems) * column + page * CGRectGetWidth(self.collectionView.frame) + self.pageInsets.left);
    CGFloat originY = floor((self.itemSize.height + self.spaceBetweenItems) * row + self.pageInsets.top);

    CGRect retVal = CGRectMake(originX, originY, self.itemSize.width, self.itemSize.height);

    return retVal;
}

- (CGSize)collectionViewContentSize
{
    NSInteger numberOfPages = [self.collectionView numberOfSections];
    NSInteger itemsOnPage = [self.collectionView numberOfItemsInSection:self.currentPage];

    CGFloat height = ceil((CGFloat)itemsOnPage / self.numberOfColumns) * self.itemSize.height;

    CGFloat minHeight = CGRectGetHeight(self.collectionView.frame);

    if (height < minHeight)
    {
        height = minHeight;
    }

    CGFloat width = CGRectGetWidth(self.collectionView.frame) * numberOfPages;

    return CGSizeMake(width, height);
}

#pragma mark - Properties

- (NSInteger)currentPage
{
    NSInteger numberOfPages = [self.collectionView numberOfSections];

    NSInteger currentPage = self.collectionView.contentOffset.x / self.collectionView.frame.size.width;

    if (currentPage == numberOfPages)
    {
        currentPage--;
    }

    return currentPage;
}

@end
