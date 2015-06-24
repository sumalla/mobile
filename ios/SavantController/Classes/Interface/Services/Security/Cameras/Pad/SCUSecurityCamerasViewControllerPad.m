//
//  SCUSecurityCamerasViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityCamerasViewControllerPad.h"

@implementation SCUSecurityCamerasViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.pagingEnabled = YES;
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *layout = (SCUCollectionViewFlowLayout *)[super preferredCollectionViewLayout];

    layout.headerReferenceSize = CGSizeMake(.001, .001); // no size, defined in layout
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    return layout;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)layout;

    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        flowLayout.minimumInteritemSpacing = 1000.0f;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.itemSize = CGSizeMake(256, 220);
    }
    else
    {
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.itemSize = CGSizeMake(384, 289);
    }

    [flowLayout invalidateLayout];
}

@end
