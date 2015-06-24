//
//  SCUAddFavoriteChannelCollectionViewController.m
//  SavantController
//
//  Created by Stephen Silber on 10/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddFavoriteChannelCell.h"
#import "SCUAddFavoriteChannelCollectionViewModel.h"
#import "SCUAddFavoriteChannelCollectionViewController.h"

@interface SCUAddFavoriteChannelCollectionViewController () <SCUAddFavoriteModelDelegate>

@property SCUAddFavoriteChannelCollectionViewModel *model;

@end

@implementation SCUAddFavoriteChannelCollectionViewController

#pragma mark - UICollectionViewDelegate methods

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [self init];
    if (self)
    {
        self.commands = commands;
        self.model = [[SCUAddFavoriteChannelCollectionViewModel alloc] initWithCommands:commands];
        self.model.delegate = self;
        self.collectionView.backgroundColor = [[SCUColors shared] color03shade01];
    }
    return self;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCUAddFavoriteChannelCell *cell = (SCUAddFavoriteChannelCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    cell.cellButton.selectedBackgroundColor = [[SCUColors shared] color02];
    if ([self.model isSystemImage:indexPath])
    {
        cell.cellImage.image = [self.model imageForIndexPath:indexPath];
    }
    else if ([kSCUCollectionViewAdditionalActionCommand isEqualToString:[self.model commandForIndexPath:indexPath]])
    {
       cell.cellImage.image = [cell.cellImage.image tintedImageWithColor:[[SCUColors shared] color02]];
    }
    return cell;
}

#pragma mark - Methods to subclass

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *flowLayout = [[SCUCollectionViewFlowLayout alloc] init];
//    flowLayout.spaceBetweenItems = 2;

    return flowLayout;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)layout;

    CGFloat viewWidth = layout.collectionViewContentSize.width;
    NSInteger numberOfColumns = 2;
    flowLayout.minimumLineSpacing = 2;
    flowLayout.minimumInteritemSpacing = 2;

    if ([UIDevice isPad])
    {
        numberOfColumns = 3;
    }

    CGFloat cellWidth = floorf(viewWidth / numberOfColumns);
    cellWidth -= ((numberOfColumns + 2) * 2) + 4;
    flowLayout.itemSize = CGSizeMake(cellWidth, cellWidth);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [flowLayout invalidateLayout];
    });
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUAddFavoriteChannelCell class] forCellType:0];

}

- (void)setSystemImages:(NSArray *)systemImages
{
    self.model.systemImages = systemImages;
}

- (NSArray *)systemImages
{
    return self.model.systemImages;
}

#pragma mark - SCUAddFavoriteModelDelegate

- (void)reloadIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

@end
