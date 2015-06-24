//
//  SCUEditableButtonsCollectionViewModel.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEditableButtonsCollectionViewModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUEditableButtonsCollectionViewModelPrivate.h"
#import "SCUAddTrashcanCollectionViewCell.h"
#import "SCUDefaultEditableCollectionViewCell.h"

@interface SCUEditableButtonsCollectionViewModel ()

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) NSIndexPath *editingIndexPath;
@property (nonatomic) NSIndexPath *movingIndexPath;
@property (nonatomic, getter = isViewOnScreen) BOOL viewOnScreen;

@property (nonatomic) NSIndexPath *originalIndexPath;
@property (nonatomic) NSIndexPath *swappedIndexPath;

@end

static NSString *SCUEditableButtonsCellTypeKey = @"SCUEditableButtonsCellTypeKey";

@implementation SCUEditableButtonsCollectionViewModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];

    if (self)
    {
        self.serviceModel = [[SCUServiceViewModel alloc] initWithService:service];
        self.plusButtonEnabled = YES;
        self.appendPlusButton = YES;
    }

    return self;
}

- (void)reloadData
{
    [self.dataDelegate reloadData];
}

#pragma mark - Private

- (void)loadButtons
{
    [self doesNotRecognizeSelector:_cmd];
}

- (NSDictionary *)modelObjectForIndexPath:(NSIndexPath *)indexPath isInEditMode:(BOOL)isInEditMode isMoving:(BOOL)isMoving
{
    NSDictionary *modelObject = [self _modelObjectForIndexPath:indexPath];

    if (isInEditMode)
    {
        modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUDefaultEditableCollectionViewCellIsInEditModeKey];
    }

    if (isMoving)
    {
        modelObject = [modelObject dictionaryByAddingObject:@YES forKey:SCUDefaultEditableCollectionViewCellIsMovingKey];
    }

    return modelObject;
}

- (void)itemAtIndexPathTapped:(NSIndexPath *)indexPath
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)addTapped
{
    [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self doesNotRecognizeSelector:_cmd];
    return YES;
}

- (void)didDeleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)itemAtIndexPath:(NSIndexPath *)indexPath movedToIndexPath:(NSIndexPath *)newIndexPath
{
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - SCUDataSourceModel methods

- (void)viewDidAppear
{
    self.viewOnScreen = YES;
}

- (void)viewDidDisappear
{
    self.viewOnScreen = NO;
}

- (void)loadDataIfNecessary
{
    if (!self.modelObjects)
    {
        self.modelObjects = @[];
    }

    [self loadButtons];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [[self _modelObjectForIndexPath:indexPath][SCUEditableButtonsCellTypeKey] unsignedIntegerValue];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    if ([self cellAtIndexPathIsNormal:indexPath])
    {
        return [self modelObjectForIndexPath:indexPath isInEditMode:[self.editingIndexPath isEqual:indexPath] isMoving:[self.movingIndexPath isEqual:indexPath]];
    }
    else
    {
        return @{SCUAddTrashcanCollectionViewCellShowsAdd: @(self.movingIndexPath || self.editingIndexPath ? NO : YES),
                 SCUAddTrashcanCollectionViewCellIsEnabledKey: @(self.movingIndexPath || self.editingIndexPath ? YES : self.isPlusButtonEnabled)};
    }
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self cellAtIndexPathIsNormal:indexPath])
    {
        [self itemAtIndexPathTapped:indexPath];
    }
    else
    {
        [self addTapped];
    }
}

#pragma mark - SCUReorderableTileLayoutDelegate

- (void)layout:(SCUReorderableTileLayout *)layout moveIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *dataSource = [self.dataSource mutableCopy];
    id modelObject = dataSource[fromIndexPath.row];
    [dataSource removeObjectAtIndex:fromIndexPath.row];
    [dataSource insertObject:modelObject atIndex:toIndexPath.row];
    self.dataSource = dataSource;

    if (!self.originalIndexPath)
    {
        self.originalIndexPath = fromIndexPath;
    }

    self.swappedIndexPath = toIndexPath;
}

- (void)layout:(SCUReorderableTileLayout *)layout updateModelWithIndexPathOrdering:(NSArray *)indexPathOrdering
{
    NSMutableArray *newDataSource = [NSMutableArray array];

    for (NSIndexPath *indexPath in indexPathOrdering)
    {
        id modelObject = [self _modelObjectForIndexPath:indexPath];
        [newDataSource addObject:modelObject];
    }

    self.modelObjects = [newDataSource copy];
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canEditItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellAtIndexPathIsNormal:indexPath];
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self layout:layout canEditItemAtIndexPath:indexPath];
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canReplaceItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self layout:layout canEditItemAtIndexPath:indexPath];
}

- (SCUReoderableTileLayoutReleasedAction)layout:(SCUReorderableTileLayout *)layout movingIndexPath:(NSIndexPath *)movingIndexPath didReleaseOverIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath && ![self cellAtIndexPathIsNormal:indexPath])
    {
        if ([self deleteItemAtIndexPath:movingIndexPath])
        {
            NSMutableArray *dataSource = [self.dataSource mutableCopy];
            [dataSource removeObjectAtIndex:movingIndexPath.row];
            self.dataSource = dataSource;
            self.swappedIndexPath = nil;
            self.originalIndexPath = nil;

            [self didDeleteItemAtIndexPath:movingIndexPath];

            return SCUReoderableTileLayoutReleasedActionDelete;
        }
    }

    return SCUReoderableTileLayoutReleasedActionNone;
}

- (void)layoutDidEndEditingMode:(SCUReorderableTileLayout *)layout
{
    if (self.swappedIndexPath && self.originalIndexPath)
    {
        if ([self respondsToSelector:@selector(itemAtIndexPath:movedToIndexPath:)])
        {
            [self itemAtIndexPath:self.originalIndexPath movedToIndexPath:self.swappedIndexPath];
        }

        self.originalIndexPath = nil;
        self.swappedIndexPath = nil;
    }
}

- (void)layout:(SCUReorderableTileLayout *)layout setEditingIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *oldEditingIndexPath = self.movingIndexPath;
    self.editingIndexPath = indexPath;

    if (indexPath && !oldEditingIndexPath)
    {
        [self.dataDelegate reloadIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource count] - 1 inSection:0]]];
    }
}

- (void)layout:(SCUReorderableTileLayout *)layout setMovingIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *oldMovingIndexPath = self.movingIndexPath;
    self.movingIndexPath = indexPath;

    if (indexPath && !oldMovingIndexPath)
    {
        [self.dataDelegate reloadIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource count] - 1 inSection:0]]];
    }
}

#pragma mark -

- (void)setPlusButtonEnabled:(BOOL)plusButtonEnabled
{
    if (_plusButtonEnabled != plusButtonEnabled)
    {
        _plusButtonEnabled = plusButtonEnabled;

        if (self.isViewOnScreen)
        {
            [self.dataDelegate reloadIndexPaths:@[[NSIndexPath indexPathForItem:[self.dataSource count] - 1 inSection:0]]];
        }
    }
}

- (void)setModelObjects:(NSArray *)modelObjects
{
    _modelObjects = modelObjects;

    if (self.appendPlusButton)
    {
        NSMutableArray *mModelObjects = [modelObjects mutableCopy];
        [mModelObjects addObject:@{SCUEditableButtonsCellTypeKey: @(SCUEditableButtonCollectionViewCellTypePlusAndTrashcan)}];
        self.dataSource = mModelObjects;
    }
    else
    {
        self.dataSource = modelObjects;
    }
}

- (BOOL)cellAtIndexPathIsNormal:(NSIndexPath *)indexPath
{
    return [self cellTypeForIndexPath:indexPath] != SCUEditableButtonCollectionViewCellTypePlusAndTrashcan;
}

@end
