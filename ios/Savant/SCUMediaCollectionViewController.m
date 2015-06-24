//
//  SCUMediaCollectionViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaCollectionViewController.h"
#import "SCUMediaCollectionViewFlowLayout.h"
#import "SCUMediaCollectionViewCell.h"
#import "SCUHomeGridHeaderCell.h"

@interface SCUMediaCollectionViewController () <SCUMediaDataModelDelegate>

@property (nonatomic) SCUMediaDataModel *model;

@end

@implementation SCUMediaCollectionViewController

- (instancetype)initWithModel:(SCUMediaDataModel *)mediaModel
{
    self = [super init];

    if (self)
    {
        self.model = mediaModel;
        self.model.delegate = self;
    }

    return self;
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    return [[SCUMediaCollectionViewFlowLayout alloc] init];
}

- (void)configureLayout:(UICollectionViewLayout *)l withOrientation:(UIInterfaceOrientation)orientation
{
    SCUMediaCollectionViewFlowLayout *layout = (SCUMediaCollectionViewFlowLayout *)l;

    if ([UIDevice isPhone])
    {
        layout.numberOfColumns = 2;
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait(orientation))
        {
            layout.numberOfColumns = 4;
        }
        else
        {
            layout.numberOfColumns = 5;
        }
    }

    layout.padding = 2;
    layout.headerReferenceSize = CGSizeMake(0, 40);
    [layout invalidateLayout];
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUMediaCollectionViewCell class] forCellType:0];
    [self.collectionView sav_registerClass:[SCUHomeGridHeaderCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader forCellType:0];
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if ([self.model hasArtworkForIndexPath:indexPath])
    {
        SCUMediaCollectionViewCell *mediaCell = (SCUMediaCollectionViewCell *)cell;
        mediaCell.artwork.image = [self.model artworkForIndexPath:indexPath];
    }
}

#pragma mark - SCUMediaDataModelDelegate methods

- (void)deleteItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath)
    {
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
}

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (void)setArtwork:(UIImage *)artwork forIndexPath:(NSIndexPath *)indexPath
{
    SCUMediaCollectionViewCell *cell = (SCUMediaCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.artwork.image = artwork;
}

@end
