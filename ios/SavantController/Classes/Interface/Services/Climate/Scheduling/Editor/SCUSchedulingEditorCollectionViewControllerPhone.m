//
//  SCUSchedulingEditorPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditorCollectionViewControllerPhone.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUSchedulingExpandableCell.h"
#import "SCUSchedulingEditingViewController.h"

@interface SCUSchedulingEditorCollectionViewControllerPhone () <SCUSchedulingCellDelegate>

@end

@implementation SCUSchedulingEditorCollectionViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.alwaysBounceVertical = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self collectionView:self.collectionView didSelectItemAtIndexPath:self.selectedIndex];
}

- (void)configureLayout:(UICollectionViewLayout *)l withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *layout = (SCUCollectionViewFlowLayout *)l;

    layout.itemSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 53);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;

    [layout invalidateLayout];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];

    if (![self.model.selectedIndexPaths containsObject:indexPath])
    {
        NSArray *previousIndexPaths = self.model.selectedIndexPaths;
        self.model.selectedIndexPaths = @[indexPath];

        [self.collectionView sav_reloadItemsAtIndexPaths:[previousIndexPaths arrayByAddingObject:indexPath] animated:YES];
    }
    else
    {
        self.model.selectedIndexPaths = @[];
        [self.collectionView sav_reloadItemsAtIndexPaths:@[indexPath] animated:YES];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize defaultSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 43);

    NSDictionary *modelObject = [self.model modelObjectForIndexPath:indexPath];

    if (modelObject[SCUDefaultCollectionViewCellKeyModelObject])
    {
        defaultSize.height += [[self editingViewControllerForIndexPath:indexPath] estimatedHeight] + 10;
    }

    return defaultSize;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUSchedulingExpandableCell class] forCellType:0];
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell withType:type indexPath:indexPath];

    SCUSchedulingCell *c = (SCUSchedulingCell *)cell;
    c.delegate = self;
}

#pragma mark - Scheduling Cell Delegate

- (SCUSchedulingEditingViewController *)editingViewControllerForCell:(SCUSchedulingCell *)cell
{
    return [self editingViewControllerForIndexPath:[self.collectionView indexPathForCell:cell]];
}

- (void)reloadDataForCell:(SCUSchedulingCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath)
    {
        [self.collectionView sav_reloadItemsAtIndexPaths:@[indexPath] animated:YES];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

@end
