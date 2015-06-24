//
//  SCUEditableButtonsCollectionViewModelPrivate.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEditableButtonsCollectionViewModel.h"
#import "SCUServiceViewModel.h"

@protocol SCUEditableButtonsCollectionViewModelDataDelegate <NSObject>

- (void)reloadData;

- (void)reloadIndexPaths:(NSArray *)indexPaths;

@end

@interface SCUEditableButtonsCollectionViewModel ()

@property (nonatomic) SCUServiceViewModel *serviceModel;

/**
 *  Call this method in response to the loadButtons method being called. You do not need to reloadData after this.
 */
@property (nonatomic) NSArray *modelObjects;

@property (nonatomic, weak) id<SCUEditableButtonsCollectionViewModelDataDelegate> dataDelegate;

@property (nonatomic, getter = isPlusButtonEnabled) BOOL plusButtonEnabled;

/**
 *  Call this method to cause a manual reload of the table data.
 */
- (void)reloadData;

#pragma mark - Methods to subclass

/**
 *  Called when the view loads. Load whatever data you need and set it with the @p modelObjects property.
 */
- (void)loadButtons;

/**
 *  Return the correct model object for the given @p indexPath , @p isInEditMode flag and @p isMoving flag. You do not need to override this method if you are using the SCUDefaultEditableCollectionViewCell cell.
 *
 *  @param indexPath    The index path.
 *  @param isInEditMode YES if the given index path is currently in edit mode; otherwise, NO.
 *  @param isMoving     YES if the cell is moving; otherwise, NO.
 *
 *  @return A model object which will be used to configure a cell.
 */
- (NSDictionary *)modelObjectForIndexPath:(NSIndexPath *)indexPath isInEditMode:(BOOL)isInEditMode isMoving:(BOOL)isMoving;

/**
 *  Called when a normal item is tapped.
 *
 *  @param indexPath The index path that was tapped.
 */
- (void)itemAtIndexPathTapped:(NSIndexPath *)indexPath;

/**
 *  Called when the add button is tapped.
 */
- (void)addTapped;

/**
 *  Called when an item is dragged to the trash can.
 *
 *  @param indexPath The index path that was dragged to the trash can.
 *
 *  @return YES to delete the item; otherwise, NO if you need to keep it.
 */
- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Called after a sucessful delete operation.
 *
 *  @param indexPath deleted index path.
 */
- (void)didDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Called when an item is re-ordered.
 *
 *  @param indexPath    The original index path.
 *  @param newIndexPath The new index path.
 */
- (void)itemAtIndexPath:(NSIndexPath *)indexPath movedToIndexPath:(NSIndexPath *)newIndexPath;

@end
