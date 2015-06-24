//
//  SCUClimateHistoryWeekViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryWeekViewController.h"
#import "SCUClimateHistoryWeekCell.h"

@interface SCUClimateHistoryWeekViewController ()

@property (weak) id <SCUDataSourceModel> model;

@end

@implementation SCUClimateHistoryWeekViewController

- (instancetype)initWithModel:(id <SCUDataSourceModel>)model
{
    self = [super init];
    if (self)
    {
        self.model = model;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor clearColor];
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    return [[SCUCollectionViewFlowLayout alloc] init];
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)layout;

    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        flowLayout.numberOfRows = 1;
        flowLayout.numberOfColumns = 7;
        flowLayout.spaceBetweenItems = 5;
    }
    else
    {
        flowLayout.numberOfRows = 7;
        flowLayout.numberOfColumns = 1;

        if ([UIDevice isPad])
        {
            flowLayout.spaceBetweenItems = 5;
        }
        else
        {
            flowLayout.spaceBetweenItems = 1;
        }
    }

    [flowLayout invalidateLayout];
    [self.collectionView reloadData];
}

- (id <SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUClimateHistoryWeekCell class] forCellType:0];
}

@end
