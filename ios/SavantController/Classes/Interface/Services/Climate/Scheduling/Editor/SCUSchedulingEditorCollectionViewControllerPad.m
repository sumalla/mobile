//
//  SCUSchedulingEditorPad.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingEditorCollectionViewControllerPad.h"
#import "SCUSchedulingCell.h"

@interface SCUSchedulingEditorCollectionViewControllerPad ()

@end

@implementation SCUSchedulingEditorCollectionViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 9, 0, 9);
}

- (void)configureLayout:(UICollectionViewLayout *)l withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *layout = (SCUCollectionViewFlowLayout *)l;

    layout.itemSize = CGSizeMake(330, UIInterfaceOrientationIsLandscape(orientation) ? 650 : 905);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing =  9;
    layout.minimumLineSpacing = 9;

    [layout invalidateLayout];
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUSchedulingCell class] forCellType:0];
}

@end
