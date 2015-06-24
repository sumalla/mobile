//
//  SCUCollectionViewFullScreenLayout.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCollectionViewFullScreenLayout.h"

@implementation SCUCollectionViewFullScreenLayout

- (void)prepareLayout
{
    [super prepareLayout];

    self.minimumInteritemSpacing = 0.0f;
    self.minimumLineSpacing = 0.0f;
    self.itemSize = self.collectionView.bounds.size;
}

- (void)scrollToPage:(NSUInteger)page animated:(BOOL)animated
{
    CGFloat pageWidth = CGRectGetWidth(self.collectionView.frame);
    CGPoint scrollTo = CGPointMake(pageWidth * page, 0);
    [self.collectionView setContentOffset:scrollTo animated:animated];
}

#pragma mark - Properties

- (NSInteger)currentPage
{
    return self.collectionView.contentOffset.x / self.collectionView.frame.size.width;
}

@end
