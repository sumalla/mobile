//
//  SCUDynamicButtonsCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 9/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDynamicButtonsCollectionViewController.h"
#import "SCUDynamicButtonsCollectionViewModel.h"
#import "SCUAddDynamicButtonViewController.h"
#import "SCUAddDynamicButtonViewModel.h"

@interface SCUDynamicButtonsCollectionViewController () <SCUAddDynamicButtonViewControllerDelegate, SCUDynamicButtonsCollectionViewModelDelegate>

@property SCUDynamicButtonsCollectionViewModel *dataModel;

@end

@implementation SCUDynamicButtonsCollectionViewController

- (instancetype)initWithService:(SAVService *)service
{
    return [super initWithModel:[[SCUDynamicButtonsCollectionViewModel alloc] initWithService:service]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUDynamicButtonsCollectionViewModel *model = (SCUDynamicButtonsCollectionViewModel *)self.dataModel;
    model.delegate = self;
    self.collectionView.backgroundColor = [[SCUColors shared] color03];
    self.collectionView.borderColor = [[SCUColors shared] color03shade02];
    self.collectionView.borderWidth = [UIScreen screenPixel];
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUReorderableTileLayout *tileLayout = [self tileLayout];
    tileLayout.contentInsets = UIEdgeInsetsMake(6, 6, 6, 6);
    tileLayout.interItemSpacing = 2;

    if ([UIDevice isPhone])
    {
        tileLayout.numberOfVisibleColumns = 3;
        tileLayout.numberOfVisibleRows = 3;
    }
    else
    {
        tileLayout.numberOfVisibleColumns = 3;
        tileLayout.numberOfVisibleRows = 4;
    }

    [layout invalidateLayout];
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    cell.selectedBackgroundView = [UIView sav_viewWithColor:[[SCUColors shared] color01]];
    cell.textLabel.highlightedTextColor = [[SCUColors shared] color03];
}

#pragma mark - SCUDynamicButtonsCollectionViewModelDelegate

- (void)presentAddButtonsViewController
{
    SCUAddDynamicButtonViewController *viewController = [[SCUAddDynamicButtonViewController alloc] init];
    viewController.model = [[SCUAddDynamicButtonViewModel alloc] initWithCommands:self.dataModel.hiddenCommands];
    viewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];

    if ([UIDevice isPad])
    {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    [self presentViewController:navController animated:YES completion:NULL];
}

- (void)addButton:(NSDictionary *)button
{
    [self.dataModel addButton:button];
}

#pragma mark - SCUAddDynamicButtonViewControllerDelegate

- (void)finshedAddingObjects
{
    [self.dataModel saveOrdering];
    [self.collectionView reloadData];
}

@end
