//
//  SCUServiceFirstViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstCollectionViewController.h"
#import "SCUNavigationBar.h"
#import "SCUReorderableTileLayout.h"
#import "SCUServicesFirstDataModel.h"
#import "SCUServicesFirstCollectionViewCell.h"
#import "SCUServicesFirstLargeCollectionViewCell.h"
#import "SCUServicesFirstClimateCollectionViewCell.h"
#import "SCUServicesFirstSecurityCollectionViewCell.h"
#import "SCUInterface.h"

@interface SCUServicesFirstCollectionViewController () <SCUServicesFirstDataModelDelegate>

@property (nonatomic) SCUReorderableTileLayout *layout;
@property (nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation SCUServicesFirstCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Services", nil);
    self.collectionView.alwaysBounceVertical = YES;
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidden = YES;

    SCUServicesFirstDataModel *dataModel = (SCUServicesFirstDataModel *)self.dataModel;
    dataModel.delegate = self;

    SCUReorderableTileLayout *layout = [self tileLayout];

    if ([UIDevice isPhone])
    {
        layout.allCellsAre1x1 = YES;
    }

    self.collectionView.delaysContentTouches = YES;
}

#pragma mark - SCUModelCollectionViewController methods

- (void)configureLayout:(UICollectionViewLayout *)l withOrientation:(UIInterfaceOrientation)orientation
{
    SCUReorderableTileLayout *layout = (SCUReorderableTileLayout *)l;
    layout.interItemSpacing = 4;
    layout.contentInsets = UIEdgeInsetsMake(4, 0, 4, 0);

    if ([UIDevice isPhone])
    {
        layout.numberOfVisibleColumns = 2;
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait(orientation))
        {
            layout.numberOfVisibleColumns = 4;
        }
        else
        {
            layout.numberOfVisibleColumns = 6;
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [layout invalidateLayout];
    });
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.dataModel;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUServicesFirstCollectionViewCell class] forCellType:SCUEditableButtonCollectionViewCellTypeNormal];
    [self.collectionView sav_registerClass:[SCUServicesFirstClimateCollectionViewCell class] forCellType:SCUServicesFirstCollectionViewCellTypeClimate];
    [self.collectionView sav_registerClass:[SCUServicesFirstLargeCollectionViewCell class] forCellType:SCUServicesFirstCollectionViewCellTypeLarge];
    [self.collectionView sav_registerClass:[SCUServicesFirstSecurityCollectionViewCell class] forCellType:SCUServicesFirstCollectionViewCellTypeSecurity];
}

#pragma mark - SCUServicesFirstDataModelDelegate

- (void)setAllItemsAre1x1:(BOOL)allItemsAre1x1
{
    [self tileLayout].allCellsAre1x1 = allItemsAre1x1;
}

- (void)presentViewController:(UIViewController *)viewController
{
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];

    if ([UIDevice isPad])
    {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self presentViewController:navController animated:YES completion:NULL];
}

- (void)reloadIndexPaths:(NSArray *)indexPaths
{
    if (![self tileLayout].isEditing)
    {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (NSArray *)visibleIndexPaths
{
    return [self.collectionView indexPathsForVisibleItems];
}

- (void)setSpinnerVisible:(BOOL)visible
{
    if (visible)
    {
        self.spinner.hidden = NO;
        [self.view.superview addSubview:self.spinner];
        [self.view.superview sav_addCenteredConstraintsForView:self.spinner];
        [self.spinner startAnimating];
    }
    else
    {
        self.spinner.hidden = YES;
        [self.spinner stopAnimating];
        [self.spinner removeFromSuperview];
    }
}

@end
