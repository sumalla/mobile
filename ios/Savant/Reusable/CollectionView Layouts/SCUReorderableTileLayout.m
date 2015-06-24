//
//  SCUResizableReorderableTileLayout.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUReorderableTileLayout.h"
#import "SCUReorderableTileLayoutSpanPrivate.h"
@import Extensions;

#pragma mark - Internal layout stuff

@interface SCUReorderableTileLayout () <UIGestureRecognizerDelegate>

@property (nonatomic) CGFloat width;
@property (nonatomic) CGSize baseSize;
@property (nonatomic) CGSize currentSize;

@property (nonatomic) NSArray *layoutAttributes;

@property (nonatomic) SAVKVORegistration *collectionViewSetupRegistration;
@property (nonatomic) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) NSArray *gestureRecognizers;

@property (nonatomic) UIView *movingView;
@property (nonatomic) CGPoint centerDifference;
@property (nonatomic) BOOL updateModelOnInvalidation;
@property (nonatomic, weak) NSTimer *reorderTimer;
@property (nonatomic) CGPoint currentTouchLocation;
@property (nonatomic) CGPoint currentRelativeTouchLocation;
@property (nonatomic) CGPoint currentTouchVelocity;
@property (nonatomic) NSIndexPath *movingIndexPath;
@property (nonatomic) NSIndexPath *ignoredIndexPath;
@property (nonatomic) NSIndexPath *lastReplacingIndexPath;
@property (nonatomic, getter = isEditing) BOOL editing;

@property (nonatomic) CADisplayLink *scrollingDisplayLink;
@property (nonatomic, getter = isScrolling) BOOL scrolling;

@property (nonatomic) NSInteger lastNumberOf1x1Items;
@property (nonatomic) NSInteger lastNumberOf1x1Rows;
@property (nonatomic) CGSize lastBaseSize;

@end

#pragma mark - Layout implementation

@implementation SCUReorderableTileLayout

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.lastBaseSize = CGSizeZero;
        self.numberOfVisibleColumns = 2;
        self.numberOfVisibleRows = NSNotFound;
        self.contentInsets = UIEdgeInsetsZero;
        self.editingType = SCUReorderableTileLayoutEditingTypeContinuous;

        SAVWeakSelf;
        self.collectionViewSetupRegistration = [[SAVKVORegistration alloc] initWithObserver:self
                                                                                     target:self
                                                                                   selector:@selector(collectionView)
                                                                                    handler:^(NSDictionary *changeDictionary) {
                                                                                        if (wSelf.collectionView)
                                                                                        {
                                                                                            [wSelf setupCollectionView];
                                                                                        }
                                                                                    }];
    }

    return self;
}

- (void)invalidateLayoutAndUpdateModel
{
    self.updateModelOnInvalidation = YES;
    [self.collectionView reloadData];
}

- (void)endEditing
{
    [self setEditMode:NO];
    [self setIndexPathIsEditing:nil];
    [self setIndexPathIsMoving:nil];
    [self endEditingMode];
    [self.collectionView reloadData];
}

#pragma mark - Layout calculations

- (void)prepareLayout
{
    [super prepareLayout];
    [self updateAttributesFromModel];
}

- (void)updateAttributesFromModel
{
    [self caclulateBaseProperties];
    [self calculateSlots];
}

- (void)caclulateBaseProperties
{
    self.width = CGRectGetWidth(self.collectionView.bounds);

    CGFloat totalHorizontalPadding = (self.interItemSpacing * (self.numberOfVisibleColumns - 1)) + (self.contentInsets.left + self.contentInsets.right);

    CGFloat itemWidth = (self.width - totalHorizontalPadding) / self.numberOfVisibleColumns;

    if (self.numberOfVisibleRows == NSNotFound)
    {
        self.baseSize = CGSizeMake(itemWidth, itemWidth);
    }
    else
    {
        CGFloat height = CGRectGetHeight(self.collectionView.bounds);
        CGFloat totalVerticalPadding = (self.interItemSpacing * (self.numberOfVisibleRows - 1)) + (self.contentInsets.top + self.contentInsets.bottom);
        CGFloat itemHeight = (height - totalVerticalPadding) / self.numberOfVisibleRows;
        self.baseSize = CGSizeMake(floor(itemWidth), floor(itemHeight));
    }
}

- (void)calculateSlots
{
    if (![self.delegate respondsToSelector:@selector(layout:spanForIndexPath:)])
    {
        self.allCellsAre1x1 = YES;
    }

    NSUInteger numberOfRows = 0;

    if (self.allCellsAre1x1)
    {
        numberOfRows = [self calculate1x1Slots];
    }
    else
    {
        numberOfRows = [self calculateArbitrarySlots];
    }

    CGFloat height = (numberOfRows * self.baseSize.height) + ((numberOfRows + 1) * self.interItemSpacing) + (self.contentInsets.top + self.contentInsets.bottom);
    self.currentSize = CGSizeMake(self.width, height);
}

- (NSUInteger)calculate1x1Slots
{
    NSMutableArray *layoutAttributes = [NSMutableArray array];

    if (![self.collectionView numberOfSections])
    {
        return 0;
    }

    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];

    if (numberOfItems == self.lastNumberOf1x1Items && CGSizeEqualToSize(self.lastBaseSize, self.baseSize))
    {
        return self.lastNumberOf1x1Rows;
    }

    self.lastBaseSize = self.baseSize;
    self.lastNumberOf1x1Items = numberOfItems;

    for (NSInteger item = 0; item < numberOfItems; item++)
    {
        SCUReorderableTileLayoutSpan *span = [SCUReorderableTileLayoutSpan spanWithWidth:1 height:1];
        span.row = (item / self.numberOfVisibleColumns);
        span.column = item % self.numberOfVisibleColumns;

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = [span frameWithPadding:self.interItemSpacing baseSize:self.baseSize insets:self.contentInsets];
        [layoutAttributes addObject:attributes];
    }

    self.layoutAttributes = layoutAttributes;

    NSUInteger numberOfRows = numberOfItems / self.numberOfVisibleColumns;

    if ((numberOfItems % self.numberOfVisibleColumns) != 0)
    {
        numberOfRows++;
    }

    self.lastNumberOf1x1Rows = numberOfRows;

    return numberOfRows;
}

- (NSUInteger)calculateArbitrarySlots
{
    NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];

    NSMutableDictionary *layoutAttributes = [NSMutableDictionary dictionary];
    NSMutableArray *occupiedSlots = [NSMutableArray array];
    NSMutableSet *filledRows = [NSMutableSet set];

    for (NSUInteger i = 0; i < numberOfItems; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        SCUReorderableTileLayoutSpan *span = [self spanForIndexPath:indexPath];
        [span normalizeWithNumberOfColumns:self.numberOfVisibleColumns];

        BOOL foundSpot = NO;
        NSUInteger row = 0;
        NSUInteger column = 0;

        while (!foundSpot)
        {
            //-------------------------------------------------------------------
            // This row is already full, skip it.
            //-------------------------------------------------------------------
            if ([filledRows containsObject:@(row)])
            {
                row++;
                continue;
            }

            //-------------------------------------------------------------------
            // We are ahead of the occupied slots array so add a new array to it.
            //-------------------------------------------------------------------
            if (row >= [occupiedSlots count])
            {
                [occupiedSlots addObject:[[NSArray arrayOfLength:self.numberOfVisibleColumns withObject:@NO] mutableCopy]];
            }

            BOOL rowFull = YES;
            NSArray *spots = occupiedSlots[row];

            for (column = 0; column < self.numberOfVisibleColumns; column++)
            {
                //-------------------------------------------------------------------
                // There is a spot, check if the tile will fit.
                //-------------------------------------------------------------------
                if (![spots[column] boolValue] && column + span.width <= self.numberOfVisibleColumns)
                {
                    BOOL wontFit = NO;

                    for (NSUInteger jj = row; jj < row + span.height; jj++)
                    {
                        //-------------------------------------------------------------------
                        // Go down by the Y span.
                        //-------------------------------------------------------------------
                        if (jj < [occupiedSlots count])
                        {
                            NSArray *spotsforFit = occupiedSlots[jj];

                            //-------------------------------------------------------------------
                            // Check the X direction.
                            //-------------------------------------------------------------------
                            for (NSUInteger ii = column; ii < column + span.width; ii++)
                            {
                                if ([spotsforFit[ii] boolValue])
                                {
                                    wontFit = YES;
                                    break;
                                }
                            }

                            if (wontFit)
                            {
                                //-------------------------------------------------------------------
                                // Found an occupied slot, bail out.
                                //-------------------------------------------------------------------
                                break;
                            }
                        }
                        else
                        {
                            [occupiedSlots addObject:[[NSArray arrayOfLength:self.numberOfVisibleColumns withObject:@NO] mutableCopy]];
                        }
                    }

                    if (!wontFit)
                    {
                        //-------------------------------------------------------------------
                        // Found a spot. Create the correct attributes and mark spots as
                        // occupied.
                        //-------------------------------------------------------------------
                        foundSpot = YES;
                        span.row = row;
                        span.column = column;

                        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                        attributes.frame = [span frameWithPadding:self.interItemSpacing baseSize:self.baseSize insets:self.contentInsets];
                        layoutAttributes[span] = attributes;

                        for (NSUInteger jj = row; jj < row + span.height; jj++)
                        {
                            NSMutableArray *coveredSlots = occupiedSlots[jj];

                            for (NSUInteger ii = column; ii < column + span.width; ii++)
                            {
                                coveredSlots[ii] = @YES;
                            }
                        }

                        break;
                    }
                }
            }

            //-------------------------------------------------------------------
            // Check if the row is full.
            //-------------------------------------------------------------------
            for (column = 0; column < self.numberOfVisibleColumns; column++)
            {
                if (![spots[column] boolValue])
                {
                    rowFull = NO;
                    break;
                }
            }

            if (rowFull)
            {
                [filledRows addObject:@(row)];
            }

            //-------------------------------------------------------------------
            // Move to the next row.
            //-------------------------------------------------------------------
            row++;
        }
    }

    NSMutableArray *sortedIndexPaths = [NSMutableArray array];

    self.layoutAttributes = [[layoutAttributes sav_valuesForSortedStringKeys] arrayByMappingIndexBlock:^id(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
        [sortedIndexPaths addObject:attributes.indexPath];
        //-------------------------------------------------------------------
        // Set the correct index path now that things have been sorted by slot.
        //-------------------------------------------------------------------
        attributes.indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
        return attributes;
    }];

    if (self.updateModelOnInvalidation && [self.delegate respondsToSelector:@selector(layout:updateModelWithIndexPathOrdering:)])
    {
        [self.delegate layout:self updateModelWithIndexPathOrdering:sortedIndexPaths];
    }

    self.updateModelOnInvalidation = NO;

    return [occupiedSlots count];
}

#pragma mark - Layout overrides

- (CGSize)collectionViewContentSize
{
    return self.currentSize;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *layoutAttributesForRect = [NSMutableArray array];

    for (UICollectionViewLayoutAttributes *attribute in self.layoutAttributes)
    {
        if (CGRectIntersectsRect(rect, attribute.frame))
        {
            [layoutAttributesForRect addObject:attribute];
        }
    }

    return layoutAttributesForRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.layoutAttributes[indexPath.row];
}

#pragma mark - Gesture handling

- (void)setupCollectionView
{
    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.collectionView addGestureRecognizer:self.longPressRecognizer];
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.longPressRecognizer];
    self.longPressRecognizer.delegate = self;

    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panRecognizer.maximumNumberOfTouches = 1;
    self.panRecognizer.delegate = self;
    [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.panRecognizer];
    [self.collectionView addGestureRecognizer:self.panRecognizer];

    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tapRecognizer.enabled = NO;
    [self.collectionView addGestureRecognizer:self.tapRecognizer];

    self.gestureRecognizers = @[self.longPressRecognizer, self.panRecognizer];

    self.movingView = [[UIImageView alloc] initWithFrame:CGRectZero];

    self.scrollingDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    [self.scrollingDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.scrollingDisplayLink.paused = YES;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (self.isEditing && recognizer.state == UIGestureRecognizerStateBegan)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        return;
    }

    //-------------------------------------------------------------------
    // Find the cell that was tapped, and if there was one, enable the pan
    // gesture.
    //-------------------------------------------------------------------
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *indexPath = [self layoutAttributesForPoint:[recognizer locationInView:self.collectionView]].indexPath;

            if (indexPath && [self canEditItemAtIndexPath:indexPath])
            {
                [self setEditMode:YES];
                self.movingIndexPath = indexPath;
                [self enterEditingMode];
                [self setIndexPathIsEditing:indexPath];
                [self.collectionView reloadData];
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
            if (self.editingType == SCUReorderableTileLayoutEditingTypeMomentary && self.panRecognizer.state == UIGestureRecognizerStateFailed)
            {
                //-------------------------------------------------------------------
                // Edit mode was entered, but the person never moved their finger
                //-------------------------------------------------------------------
                [self endEditing];
            }
            break;
        default:
            break;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.collectionView];
    self.currentTouchLocation = [recognizer locationInView:self.collectionView];
    self.currentRelativeTouchLocation = [self.collectionView convertPoint:self.currentTouchLocation toView:self.collectionView.superview];
    self.currentTouchVelocity = [recognizer velocityInView:self.collectionView];

    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.scrollingDisplayLink.paused = NO;
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForPoint:location];
            NSIndexPath *indexPath = attributes.indexPath;

            UIView *potentialMovingView = [self movingViewFromCell:[self.collectionView cellForItemAtIndexPath:attributes.indexPath] frame:attributes.frame];

            BOOL shouldContinue = YES;
            BOOL shouldDelay = NO;

            if (![self.movingIndexPath isEqual:indexPath])
            {
                //-------------------------------------------------------------------
                // This is hacky, but once in edit mode, it lets you swipe on something
                // to have that item enter edit mode.
                //-------------------------------------------------------------------
                [self handleTap:recognizer];

                if (![self.movingIndexPath isEqual:indexPath])
                {
                    recognizer.enabled = NO;
                    recognizer.enabled = YES;
                    shouldContinue = NO;
                }
                else
                {
                    shouldDelay = YES;
                }
            }

            if (shouldContinue)
            {
                dispatch_block_t block = ^{
                    //-------------------------------------------------------------------
                    // Position the moving view and set its image.
                    //-------------------------------------------------------------------
                    self.movingView = potentialMovingView;
                    [self.collectionView addSubview:self.movingView];
                    [self.collectionView bringSubviewToFront:self.movingView];
                    [self setIndexPathIsMoving:self.movingIndexPath];
                    [self.collectionView sav_reloadItemsAtIndexPaths:@[self.movingIndexPath] animated:NO];

                    //-------------------------------------------------------------------
                    // Calculate the difference between the touch point and the center of
                    // the moving view.
                    //-------------------------------------------------------------------
                    CGPoint centerDifference = CGPointZero;
                    centerDifference.x = (self.movingView.center.x - location.x);
                    centerDifference.y = (self.movingView.center.y - location.y);
                    self.centerDifference = centerDifference;

                    //-------------------------------------------------------------------
                    // Start the re-order timer. Only check a couple of times a second
                    // for a collision.
                    //-------------------------------------------------------------------
                    self.reorderTimer = [NSTimer sav_scheduledTimerWithTimeInterval:.4 repeats:YES block:^{
                        [self tryToReorder];
                    }];
                };

                if (shouldDelay)
                {
                    dispatch_async_main(block);
                }
                else
                {
                    block();
                }
            }

            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            location.x += self.centerDifference.x;
            location.y += self.centerDifference.y;
            self.movingView.center = location;
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        {
            [self.reorderTimer invalidate];
            self.scrollingDisplayLink.paused = YES;

            [self setIndexPathIsMoving:nil];

            if (self.editingType == SCUReorderableTileLayoutEditingTypeMomentary)
            {
                [self setIndexPathIsEditing:nil];
            }

            __block BOOL deletedItem = NO;

            dispatch_block_t completion = ^{

                [self.movingView removeFromSuperview];
                self.movingView = nil;

                [self setIndexPathIsMoving:nil];

                if (self.editingType == SCUReorderableTileLayoutEditingTypeMomentary)
                {
                    [self setIndexPathIsEditing:nil];
                    [self endEditing];
                }
                else
                {
                    [self.collectionView reloadData];
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                });
            };

            if (self.movingIndexPath && [self.delegate respondsToSelector:@selector(layout:movingIndexPath:didReleaseOverIndexPath:)])
            {
                NSIndexPath *droppedIndexPath = [self layoutAttributesForPoint:[recognizer locationInView:self.collectionView]].indexPath;

                [self.collectionView performBatchUpdates:^{
                    SCUReoderableTileLayoutReleasedAction action = [self.delegate layout:self movingIndexPath:self.movingIndexPath didReleaseOverIndexPath:droppedIndexPath];

                    if (action == SCUReoderableTileLayoutReleasedActionDelete)
                    {
                        [self.movingView removeFromSuperview];
                        self.movingView = nil;
                        deletedItem = YES;
                        [self.collectionView deleteItemsAtIndexPaths:@[self.movingIndexPath]];
                    }
                } completion:^(BOOL finished) {
                    if (deletedItem)
                    {
                        completion();
                    }
                }];
            }

            if (!deletedItem)
            {
                self.panRecognizer.enabled = NO;
                
                [UIView animateWithDuration:.35 animations:^{
                    self.movingView.frame = [self layoutAttributesForItemAtIndexPath:self.movingIndexPath].frame;
                } completion:^(BOOL finished) {
                    self.panRecognizer.enabled = YES;
                    [self.movingView removeFromSuperview];
                    self.movingView = nil;
                    completion();
                }];
            }

            break;
        }
        default:
            break;
    }
}

- (void)handleTap:(UIGestureRecognizer *)recognizer
{
    NSIndexPath *oldIndexPath = self.movingIndexPath;
    NSIndexPath *tappedIndexPath = [self layoutAttributesForPoint:[recognizer locationInView:self.collectionView]].indexPath;

    if ([oldIndexPath isEqual:tappedIndexPath])
    {
        return;
    }

    if (tappedIndexPath && [self canEditItemAtIndexPath:tappedIndexPath])
    {
        self.ignoredIndexPath = nil;
        self.movingIndexPath = tappedIndexPath;
        [self setIndexPathIsEditing:tappedIndexPath];
        [self.collectionView reloadData];
    }
    else if (!tappedIndexPath)
    {
        [self endEditing];
    }
}

- (void)handleScroll:(CADisplayLink *)scroll
{
    if (!self.movingView)
    {
        return;
    }

    CGFloat height = CGRectGetHeight(self.collectionView.bounds);
    CGFloat currentY = self.currentRelativeTouchLocation.y;
    CGFloat delta = 0;
    BOOL negate = NO;

    if (currentY < 60)
    {
        delta = 60 - currentY;
        negate = YES;
    }
    else
    {
        CGFloat tempDelta = height - currentY;

        if (tempDelta < 60)
        {
            delta = 60 - tempDelta;
        }
    }

    BOOL scrolling = NO;

    if (delta)
    {
        if (delta > 20)
        {
            delta = 20;
        }

        if (negate)
        {
            delta *= -1;
        }

        CGPoint currentOffset = self.collectionView.contentOffset;
        currentOffset.y += delta;

        if (!((currentOffset.y < 0) || (currentOffset.y > self.currentSize.height - height)))
        {
            self.collectionView.contentOffset = currentOffset;
            CGPoint currentCenter = self.movingView.center;
            currentCenter.y += delta;
            self.movingView.center = currentCenter;
            scrolling = YES;
        }
    }

    self.scrolling = scrolling;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = YES;

    if (gestureRecognizer == self.panRecognizer)
    {
        shouldBegin = self.movingIndexPath ? YES : NO;
    }

    return shouldBegin;
}

#pragma mark -

- (UICollectionViewLayoutAttributes *)layoutAttributesForPoint:(CGPoint)point
{
    //-------------------------------------------------------------------
    // If we save the slot locations, this could be O(1) instead of O(N).
    //-------------------------------------------------------------------
    UICollectionViewLayoutAttributes *attributes = nil;

    for (UICollectionViewLayoutAttributes *attrs in self.layoutAttributes)
    {
        if (CGRectContainsPoint(attrs.frame, point))
        {
            attributes = attrs;
            break;
        }
    }

    return attributes;
}

- (NSIndexPath *)indexPathForViewContainingPoint:(CGPoint)point ignoredIndexPaths:(NSArray *)indexPaths
{
    __block NSIndexPath *targetIndexPath = nil;

    [self.layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
        if (![indexPaths containsObject:attributes.indexPath] && CGRectContainsPoint(attributes.frame, point))
        {
            targetIndexPath = [NSIndexPath indexPathForItem:idx inSection:0];
            *stop = YES;
        }
    }];

    return targetIndexPath;
}

- (void)tryToReorder
{
    if (self.isScrolling)
    {
        return;
    }

    NSArray *indexPaths = nil;

    if (self.movingIndexPath && self.ignoredIndexPath)
    {
        indexPaths = @[self.movingIndexPath, self.ignoredIndexPath];
    }
    else if (self.movingIndexPath)
    {
        indexPaths = @[self.movingIndexPath];
    }

    //-------------------------------------------------------------------
    // Calculate if the current touch location intersects with a cell.
    // Don't include the "moving cell" or the "ignored cell". The "ignored
    // cell" is the cell the ends up under the touch location after a swap.
    // (The cell might not always move to the touch location.)
    //-------------------------------------------------------------------
    NSIndexPath *replacingIndexPath = [self indexPathForViewContainingPoint:self.currentTouchLocation ignoredIndexPaths:indexPaths];

    if (![self canReplaceItemAtIndexPath:replacingIndexPath])
    {
        replacingIndexPath = nil;
    }

    if (replacingIndexPath)
    {
        if (![indexPaths containsObject:replacingIndexPath])
        {
            NSIndexPath *initialIndexPath = self.movingIndexPath;

            //-------------------------------------------------------------------
            // Update the attributes and model.
            //-------------------------------------------------------------------
            NSArray *originalDataSource = [self dataSource];

            [self.delegate layout:self moveIndexPath:initialIndexPath toIndexPath:replacingIndexPath];

            if (!self.allCellsAre1x1)
            {
                self.updateModelOnInvalidation = YES;
                [self updateAttributesFromModel];
            }

            if (self.allCellsAre1x1 || ![originalDataSource isEqualToArray:[self dataSource]])
            {
                self.ignoredIndexPath = nil;
                self.movingIndexPath = replacingIndexPath;

                NSIndexPath *newMovingIndexPath = nil;

                if (self.allCellsAre1x1)
                {
                    newMovingIndexPath = replacingIndexPath;
                }
                else
                {
                    id initialModelItem = originalDataSource[initialIndexPath.row];
                    newMovingIndexPath = [NSIndexPath indexPathForItem:[[self dataSource] indexOfObject:initialModelItem] inSection:0];
                }

                [self setIndexPathIsEditing:newMovingIndexPath];
                [self setIndexPathIsMoving:newMovingIndexPath];
                self.movingIndexPath = newMovingIndexPath;

                //-------------------------------------------------------------------
                // Set the ignored index path because the moving cell might not have
                // ended up where the touch location is. This prevents the layout from
                // switching wildly when the cell does not end up at the current touch
                // location.
                //-------------------------------------------------------------------
                self.ignoredIndexPath = [self indexPathForViewContainingPoint:self.currentTouchLocation ignoredIndexPaths:nil];

                [self.collectionView performBatchUpdates:^{
                    [self.collectionView moveItemAtIndexPath:initialIndexPath toIndexPath:newMovingIndexPath];
                } completion:^(BOOL finished) {
                    [self setIndexPathIsEditing:newMovingIndexPath];
                    [self setIndexPathIsMoving:newMovingIndexPath];

                    if (self.allCellsAre1x1)
                    {
                        [self.collectionView reloadData];
                    }
                    else
                    {
                        [self.collectionView reloadData];
                    }
                }];
            }
        }
    }
    else if (self.ignoredIndexPath)
    {
        //-------------------------------------------------------------------
        // There wasn't a valid replacement location. Recalculate the absolute
        // replacingIndexPath. If it does not equal the ignoredIndexPath,
        // that means we can clear the ignoredIndexPath because the touch
        // location has moved away from the ignoredIndexPath.
        //-------------------------------------------------------------------
        replacingIndexPath = [self indexPathForViewContainingPoint:self.currentTouchLocation ignoredIndexPaths:nil];

        if (![replacingIndexPath isEqual:self.ignoredIndexPath])
        {
            self.ignoredIndexPath = nil;
        }
    }

    self.lastReplacingIndexPath = replacingIndexPath;
}

#pragma mark - Edit mode

- (void)setEditMode:(BOOL)enabled
{
    self.editing = enabled;
    [self.movingView removeFromSuperview];
    self.movingView = nil;
    self.centerDifference = CGPointZero;
    [self.reorderTimer invalidate];
    self.reorderTimer = nil;
    self.currentTouchLocation = CGPointZero;
    self.currentRelativeTouchLocation = CGPointZero;
    self.currentTouchVelocity = CGPointZero;
    self.movingIndexPath = nil;
    self.ignoredIndexPath = nil;
    self.lastReplacingIndexPath = nil;
    self.tapRecognizer.enabled = enabled;
}

#pragma mark - Delegate methods

- (SCUReorderableTileLayoutSpan *)spanForIndexPath:(NSIndexPath *)indexPath
{
    SCUReorderableTileLayoutSpan *span = nil;

    if ([self.delegate respondsToSelector:@selector(layout:spanForIndexPath:)])
    {
        span = [[self.delegate layout:self spanForIndexPath:indexPath] copy];
    }
    else
    {
        span = [SCUReorderableTileLayoutSpan spanWithWidth:1 height:1];
    }

    return span;
}

- (BOOL)canEditItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canEditItem = YES;

    if ([self.delegate respondsToSelector:@selector(layout:canEditItemAtIndexPath:)])
    {
        canEditItem = [self.delegate layout:self canEditItemAtIndexPath:indexPath];
    }

    return canEditItem;
}

- (void)enterEditingMode
{
    if ([self.delegate respondsToSelector:@selector(layoutDidEnterEditingMode:)])
    {
        [self.delegate layoutDidEnterEditingMode:self];
    }
}

- (void)endEditingMode
{
    if ([self.delegate respondsToSelector:@selector(layoutDidEndEditingMode:)])
    {
        [self.delegate layoutDidEndEditingMode:self];
    }
}

- (void)setIndexPathIsEditing:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(layout:setEditingIndexPath:)])
    {
        [self.delegate layout:self setEditingIndexPath:indexPath];
    }
}

- (BOOL)canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canMoveItem = YES;

    if ([self.delegate respondsToSelector:@selector(layout:canMoveItemAtIndexPath:)])
    {
        canMoveItem = [self.delegate layout:self canMoveItemAtIndexPath:indexPath];
    }

    return canMoveItem;
}

- (BOOL)canReplaceItemAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canReplaceItem = YES;
    
    if ([self.delegate respondsToSelector:@selector(layout:canReplaceItemAtIndexPath:)])
    {
        canReplaceItem = [self.delegate layout:self canReplaceItemAtIndexPath:indexPath];
    }
    
    return canReplaceItem;
}

- (void)setIndexPathIsMoving:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(layout:setMovingIndexPath:)])
    {
        [self.delegate layout:self setMovingIndexPath:indexPath];
    }
}

- (UIView *)movingViewFromCell:(UICollectionViewCell *)cell frame:(CGRect)frame
{
    if (self.movingImageCallback)
    {
        return self.movingImageCallback(cell, frame);
    }
    else
    {
        UIImage *image = [cell sav_rasterizedImage];
        UIImageView *view = [[UIImageView alloc] initWithImage:image];
        view.frame = frame;
        return view;
    }
}

- (NSArray *)dataSource
{
    return [self.delegate respondsToSelector:@selector(dataSource)] ? [self.delegate dataSource] : nil;
}

@end
