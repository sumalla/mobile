//
//  SCUResizableReorderableTileLayout.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SCUReorderableTileLayoutSpan.h"

#pragma mark - Layout

typedef UIView* (^SCUReorderableTileLayoutMovingImageCallback)(UICollectionViewCell *cell, CGRect frame);

typedef NS_ENUM(NSUInteger, SCUReorderableTileLayoutEditingType)
{
    SCUReorderableTileLayoutEditingTypeMomentary, /* Begin edit mode by holding on a cell. If you do not move the cell before the press finishes, edit mode is left. */
    SCUReorderableTileLayoutEditingTypeContinuous /* Begin edit mode by holding on a cell. Tap other cells to edit them. Leave manually. This is the default. */
};

typedef NS_ENUM(NSUInteger, SCUReoderableTileLayoutReleasedAction)
{
    SCUReoderableTileLayoutReleasedActionNone,
    SCUReoderableTileLayoutReleasedActionDelete
};

@protocol SCUReorderableTileLayoutDelegate;

/**
 *  For now, this class assumes that its data source has only one section.
 */
@interface SCUReorderableTileLayout : UICollectionViewLayout

/**
 *  An array of the gesture recognizers used by the layout.
 */
@property (nonatomic, readonly) NSArray *gestureRecognizers;

/**
 *  Set/retrieve the delegate.
 */
@property (nonatomic, weak) id<SCUReorderableTileLayoutDelegate> delegate;

/**
 *  Number of 1 width-spanned-tiles that will fit visually horizontally.
 */
@property (nonatomic) NSUInteger numberOfVisibleColumns;

/**
 *  Number of 1 width-spanned-tiles that will fit visually vertically. Defaults to NSNotFound, which will cause all tiles to be squares based on the visible column count.
 */
@property (nonatomic) NSUInteger numberOfVisibleRows;

/**
 *  Set the padding between items.
 */
@property (nonatomic) CGFloat interItemSpacing;

/**
 *  The insets around the content. Defaults to UIEdgeInsetsZero.
 */
@property (nonatomic) UIEdgeInsets contentInsets;

/**
 *  Set a callback here to return a custom "moving" view. The default implementation will return a rasterized image of the given cell. Your view must have the given frame.
 */
@property (nonatomic, copy) SCUReorderableTileLayoutMovingImageCallback movingImageCallback;

/**
 *  Set this to YES to enable performance optimizations when all cells are known sizes. This will be set to YES automatically if the delegate does not respond to the @p layout:spanForIndexPath: method.
 */
@property (nonatomic) BOOL allCellsAre1x1;

/**
 *  YES if the layout is in edit mode; otherwise, NO.
 */
@property (nonatomic, readonly, getter = isEditing) BOOL editing;

/**
 *  Invalidate and recompute the layout and update the model with the new sorted visual order.
 */
- (void)invalidateLayoutAndUpdateModel;

/**
 *  Leave editing mode.
 */
- (void)endEditing;

/**
 *  Set the editing type. Defaults to SCUReorderableTileLayoutEditingTypeContinuous.
 */
@property (nonatomic) SCUReorderableTileLayoutEditingType editingType;

@end

@protocol SCUReorderableTileLayoutDelegate <NSObject>

/**
 *  This is called when two tiles are swapped. Use this method to update your model.
 *
 *  @param layout        The layout.
 *  @param fromIndexPath The original index path.
 *  @param toIndexPath   The new index path.
 */
- (void)layout:(SCUReorderableTileLayout *)layout moveIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 *  Hacky, your data source must be exposed for now if you aren't using 1x1 cells.
 *
 *  @return Your data source.
 */
- (id)dataSource;

@optional

/**
 *  This is called after the layout re-flowed after a reorder. Use this method to update your model.
 *
 *  @param layout            The layout.
 *  @param indexPathOrdering An array of indexPaths from the old system, in the new system.
 */
- (void)layout:(SCUReorderableTileLayout *)layout updateModelWithIndexPathOrdering:(NSArray *)indexPathOrdering;

/**
 *  Return the span for the given index path. If this method is not overriden, a 1x1 size will be assumed.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path.
 *
 *  @return The span for the given index path.
 */
- (SCUReorderableTileLayoutSpan *)layout:(SCUReorderableTileLayout *)layout spanForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Implement this method if you need specific control over what index paths may be edited.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path.
 *
 *  @return YES if this cell can be edited; otherwise, NO.
 */
- (BOOL)layout:(SCUReorderableTileLayout *)layout canEditItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Called when the layout first enters editing mode.
 *
 *  @param layout The layout.
 */
- (void)layoutDidEnterEditingMode:(SCUReorderableTileLayout *)layout;

/**
 *  Called when the layout ends editing mode.
 *
 *  @param layout The layout.
 */
- (void)layoutDidEndEditingMode:(SCUReorderableTileLayout *)layout;

/**
 *  Update your internal editing index path.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path that is being edited.
 */
- (void)layout:(SCUReorderableTileLayout *)layout setEditingIndexPath:(NSIndexPath *)indexPath;

/**
 *  Implement this method if you need specific control over what index paths may be moved.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path.
 *
 *  @return YES if the item can be moved; otherwise NO.
 */
- (BOOL)layout:(SCUReorderableTileLayout *)layout canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Implement this method if you need specific control over what index paths may be replaced by the moving item.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path.
 *
 *  @return YES if the moving index path can be placed at the given index path; otherwise, NO.
 */
- (BOOL)layout:(SCUReorderableTileLayout *)layout canReplaceItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Update your internal moving index path.
 *
 *  @param layout    The layout.
 *  @param indexPath The index path.
 */
- (void)layout:(SCUReorderableTileLayout *)layout setMovingIndexPath:(NSIndexPath *)indexPath;

/**
 *  Implement this method when you wish to know what index path the moving index path was released over. @p indexPath may be nil.
 *
 *  @param layout          The layout.
 *  @param movingIndexPath The moving index path.
 *  @param indexPath       The index path.
 */
- (SCUReoderableTileLayoutReleasedAction)layout:(SCUReorderableTileLayout *)layout movingIndexPath:(NSIndexPath *)movingIndexPath didReleaseOverIndexPath:(NSIndexPath *)indexPath;

@end
