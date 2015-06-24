//
//  SCUEditableButtonsCollectionViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUEditableButtonsCollectionViewController.h"
#import "SCUReorderableTileLayout.h"
#import "SCUEditableButtonsCollectionViewModelPrivate.h"
#import "SCUAddTrashcanCollectionViewCell.h"
#import "SCUDefaultEditableCollectionViewCell.h"

@interface SCUEditableButtonsCollectionViewController () <SCUEditableButtonsCollectionViewModelDataDelegate>

@property (nonatomic) SCUEditableButtonsCollectionViewModel *dataModel;

@end

@implementation SCUEditableButtonsCollectionViewController

- (instancetype)initWithModel:(SCUEditableButtonsCollectionViewModel *)model
{
    self = [super initWithService:model.serviceModel.service];

    if (self)
    {
        self.model = model.serviceModel;
        self.dataModel = model;
        self.dataModel.dataDelegate = self;
    }

    return self;
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    return [[SCUReorderableTileLayout alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tileLayout.delegate = self.dataModel;
    self.tileLayout.editingType = SCUReorderableTileLayoutEditingTypeMomentary;
    self.collectionView.delaysContentTouches = NO;
}

- (SCUReorderableTileLayout *)tileLayout
{
    return (SCUReorderableTileLayout *)self.collectionView.collectionViewLayout;
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.dataModel;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[self normalCellClass] forCellType:SCUEditableButtonCollectionViewCellTypeNormal];
    [self.collectionView sav_registerClass:[SCUAddTrashcanCollectionViewCell class] forCellType:SCUEditableButtonCollectionViewCellTypePlusAndTrashcan];
}

- (Class)normalCellClass
{
    return [SCUDefaultEditableCollectionViewCell class];
}

#pragma mark - SCUEditableButtonsCollectionViewModelDataDelegate

- (void)reloadData
{
    [[self tileLayout] invalidateLayoutAndUpdateModel];
}

- (void)reloadIndexPaths:(NSArray *)indexPaths
{
    if ([indexPaths count])
    {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

#pragma mark - SCUTabBarControllerContentView methods

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"favorites"];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (![self tileLayout].allCellsAre1x1)
    {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            ;
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self reloadData];
        }];
    }
}

@end
