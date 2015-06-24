//
//  SCUCameraFlowLayout.m
//  SavantController
//
//  Created by Nathan Trapp on 5/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraFlowLayout.h"
#import "SCUReusableSolidColorView.h"
#import "SCUReorderableTileLayoutSpan.h"
#import "SCUReorderableTileLayoutSpanPrivate.h"

@import Extensions;

@interface SCUCameraFlowLayout ()

@property NSArray *layoutAttributes;
@property NSArray *headerLayoutAttributes;

@end

@implementation SCUCameraFlowLayout

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.numberOfRows = 1;
    }
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];

    NSMutableArray *layoutAttributes = [NSMutableArray array];
    NSMutableArray *headerLayoutAttributes = [NSMutableArray array];

    if ([UIDevice isPad])
    {
        NSUInteger numberOfSections = [self.collectionView numberOfSections];

        BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);

        for (NSUInteger section = 0; section < numberOfSections; section++)
        {
            NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
            NSUInteger numberOfColumns = isPortrait ? 2 : 4;
            UIEdgeInsets edgeInsets = isPortrait ? UIEdgeInsetsMake(125, 0, 0, 0) : UIEdgeInsetsMake(185, 0, 0, 0);

            CGRect headerFrame = CGRectZero;

            for (NSUInteger item = 0; item < numberOfItems; item++)
            {
                NSUInteger absoluteItem = item + [self rowsBeforeSection:section];
                NSUInteger row = (absoluteItem / numberOfColumns);

                SCUReorderableTileLayoutSpan *span = [SCUReorderableTileLayoutSpan spanWithWidth:1 height:1];
                span.row = isPortrait ? row % numberOfColumns : 0;
                span.column = isPortrait ? absoluteItem % numberOfColumns : absoluteItem;

                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:absoluteItem inSection:0];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                attributes.indexPath = [NSIndexPath indexPathForItem:item inSection:section];

                CGRect frame = [span frameWithPadding:0 baseSize:self.itemSize insets:edgeInsets];

                if (span.row == 1)
                {
                    frame.origin.y += 150;
                }

                if (isPortrait)
                {
                    if (row > 1)
                    {
                        frame.origin.x += CGRectGetWidth(self.collectionView.frame) * floor(row / numberOfColumns);
                    }
                }

                attributes.frame = frame;
                [layoutAttributes addObject:attributes];

                if (item == 0)
                {
                    headerFrame = attributes.frame;
                }
            }

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
            headerFrame.origin.y -= isPortrait ? 185 : 145;
            headerFrame.origin.x += 15;
            attributes.frame = headerFrame;
            attributes.zIndex = -1;
            [headerLayoutAttributes addObject:attributes];
        }

        self.headerLayoutAttributes = headerLayoutAttributes;
        self.layoutAttributes = layoutAttributes;
    }
}

//-------------------------------------------------------------------
// Layout the attributes for all the currently visible views
//-------------------------------------------------------------------
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [NSMutableArray array];

    if ([UIDevice isPad])
    {
        //-------------------------------------------------------------------
        // Add the cells
        //-------------------------------------------------------------------
        for (UICollectionViewLayoutAttributes *attribute in self.layoutAttributes)
        {
            if (CGRectIntersectsRect(rect, attribute.frame))
            {
                [attributes addObject:attribute];
            }
        }

        //-------------------------------------------------------------------
        // Add the headers
        //-------------------------------------------------------------------
        for (UICollectionViewLayoutAttributes *attribute in self.headerLayoutAttributes)
        {
            if (CGRectIntersectsRect(rect, attribute.frame))
            {
                [attributes addObject:attribute];
            }
        }
    }

    return [UIDevice isPad] ? attributes : [super layoutAttributesForElementsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = indexPath.row + [self rowsBeforeSection:indexPath.section];

    return [UIDevice isPad] ? self.layoutAttributes[index] : [super layoutAttributesForItemAtIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return [UIDevice isPad] ? self.headerLayoutAttributes[indexPath.section] : [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
}

- (NSInteger)rowsBeforeSection:(NSInteger)section
{
    NSInteger offset = 0;

    for (NSInteger sectionNumber = 0; sectionNumber < [self.collectionView numberOfSections]; sectionNumber++)
    {
        if (section == sectionNumber)
        {
            break;
        }
        else
        {
            offset += [self.collectionView numberOfItemsInSection:sectionNumber];
        }
    }

    return offset;
}

- (CGSize)collectionViewContentSize
{
    CGSize contentSize = [super collectionViewContentSize];

    if ([UIDevice isPad])
    {
        contentSize.width = ceil([self.layoutAttributes count] / 4.0) * CGRectGetWidth(self.collectionView.frame);
    }

    return contentSize;
}

@end
