//
//  SCUCollectionViewFlowLayout.m
//  SavantController
//
//  Created by Jason Wolkovitz on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCollectionViewFlowLayout.h"

@interface SCUCollectionViewFlowLayout()

@property (nonatomic) BOOL animatingBoundsChange;
@property (nonatomic) CGFloat cellWidth, cellHeight;

@end

@implementation SCUCollectionViewFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];

    if (self.maxNumberOfRows > 0 && self.minNumberOfRows > 0)
    {
        self.numberOfRows = MIN(self.maxNumberOfRows,
                                ([self.collectionView numberOfItemsInSection:0] + self.numberOfColumns - 1) / self.numberOfColumns);
        self.numberOfRows = MAX(self.numberOfRows, self.minNumberOfRows);
    }

    if (self.numberOfColumns > 0 && self.numberOfRows > 0)
    {
        CGFloat width = CGRectGetWidth(self.collectionView.bounds);
        width -= (self.collectionView.contentInset.left + self.collectionView.contentInset.right);
        width -= self.spaceBetweenItems * (self.numberOfColumns - 1);
        self.cellWidth = floorf(width / self.numberOfColumns);

        CGFloat height = CGRectGetHeight(self.collectionView.bounds);
        height -= (self.collectionView.contentInset.top + self.collectionView.contentInset.bottom);
        height -= self.spaceBetweenItems * (self.numberOfRows - 1);
        
        self.cellHeight = floorf(height / self.numberOfRows);
        
        self.itemSize = self.squareCells ? CGSizeMake(self.cellWidth, self.cellWidth) : CGSizeMake(self.cellWidth, self.cellHeight);
    }

    if (self.spaceBetweenItems)
    {
        self.minimumInteritemSpacing = self.spaceBetweenItems;
        self.minimumLineSpacing = self.spaceBetweenItems;
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)setSquareCells:(BOOL)squareCells
{
    if (_squareCells != squareCells)
    {
        _squareCells = squareCells;
        [self invalidateLayout];
    }
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    [super prepareForAnimatedBoundsChange:oldBounds];
    self.animatingBoundsChange = YES;
}

- (void)finalizeAnimatedBoundsChange
{
    [super finalizeAnimatedBoundsChange];
    self.animatingBoundsChange = NO;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    if (!self.stickyHeader)
    {
        return [super layoutAttributesForElementsInRect:rect];
    }
    
    NSMutableArray *allItems = [[super layoutAttributesForElementsInRect:rect] mutableCopy];
    
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *lastCells = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *firstCells = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *footers = [[NSMutableDictionary alloc] init];
    
    [allItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *attributes = obj;
        NSIndexPath *indexPath = attributes.indexPath;
        
        if ([[obj representedElementKind] isEqualToString:UICollectionElementKindSectionHeader])
        {
            [headers setObject:obj forKey:@(indexPath.section)];
            
        }
        else if ([[obj representedElementKind] isEqualToString:UICollectionElementKindSectionFooter])
        {
            [footers setObject:obj forKey:@(indexPath.section)];
            
        }
        else
        {
            UICollectionViewLayoutAttributes *currentLastAttribute = [lastCells objectForKey:@(indexPath.section)];
            if ( !currentLastAttribute || indexPath.row > currentLastAttribute.indexPath.row)
            {
                [lastCells setObject:obj forKey:@(indexPath.section)];
            }
            
            // Get the top most cell of that section
            UICollectionViewLayoutAttributes *currentFirstAttribute = [firstCells objectForKey:@(indexPath.section)];
            if ( !currentFirstAttribute || indexPath.row < currentFirstAttribute.indexPath.row)
            {
                [firstCells setObject:obj forKey:@(indexPath.section)];
            }
        }
        
        // For iOS 7.0+, the cell zIndex should be above sticky section header
        attributes.zIndex = 1;
    }];
    
    [lastCells enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        UICollectionViewLayoutAttributes *attributes = obj;
        NSIndexPath *indexPath = attributes.indexPath;
        NSNumber *indexPathKey = @(indexPath.section);
        
        UICollectionViewLayoutAttributes *header = headers[indexPathKey];
        // CollectionView automatically removes headers not in bounds
        if (self.headerReferenceSize.height && !header)
        {
            header = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                          atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
            
            if (header)
            {
                [allItems addObject:header];
            }
        }
        [self updateHeaderAttributes:header lastCellAttributes:lastCells[indexPathKey]];
    }];
    
    return allItems;
}

#pragma mark Helper

- (void)updateHeaderAttributes:(UICollectionViewLayoutAttributes *)attributes lastCellAttributes:(UICollectionViewLayoutAttributes *)lastCellAttributes
{
    if (self.stickyHeader)
    {
        attributes.zIndex = 1024;
        attributes.hidden = NO;
        
        CGFloat sectionMaxY = CGRectGetMaxY(lastCellAttributes.frame) - attributes.frame.size.height;
        CGFloat viewMinY = CGRectGetMinY(self.collectionView.bounds) + self.collectionView.contentInset.top;
        CGFloat largerYPosition = MAX(viewMinY, attributes.frame.origin.y);
        CGFloat finalPosition = MIN(largerYPosition, sectionMaxY);
        CGPoint origin = attributes.frame.origin;
        origin.y = finalPosition;
        
        attributes.frame = (CGRect){
            origin,
            attributes.frame.size
        };
    }
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.animatingBoundsChange)
    {
        // If the view is rotating, appearing items should animate from their current attributes (specify `nil`).
        // Both of these appear to do much the same thing:
        //return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        return nil;
    }
    return [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.animatingBoundsChange)
    {
        // If the view is rotating, disappearing items should animate to their new attributes.
        return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    }
    return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
}

@end
