//
//  SCUModelCollectionViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"
#import "SCUDefaultCollectionViewCell.h"
#import "SCUCollectionViewFlowLayout.h"

@interface SCUModelCollectionViewController : UICollectionViewController <UICollectionViewDelegate, UICollectionViewDataSource>

#pragma mark - Methods to subclass

@property (nonatomic, readonly, strong) UICollectionViewLayout *preferredCollectionViewLayout;

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation;

@property (nonatomic, readonly, strong) id<SCUDataSourceModel> collectionViewModel;

@property (nonatomic, readonly) SCUCollectionViewFlowLayout *collectionViewLayout;

@end

@interface SCUModelCollectionViewController (Optional)

- (void)registerCells;

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath;
- (void)configureSupplementaryCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath;

@end
