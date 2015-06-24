//
//  SCUScenesViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUFavoritesCollectionViewController.h"
#import "SCUReorderableTileLayout.h"
#import "SCUFavoritesCollectionViewModel.h"
#import "SCUFavoritesEditableCollectionViewCell.h"
#import "SCUToolbarButton.h"
#import "SCUAddFavoriteViewController.h"
//#import "SCUInterface.h"
#import "SCUServiceViewProtocol.h"

@import SDK;

@interface SCUFavoritesCollectionViewController () <SCUServiceViewProtocol, SCUFavoritesCollectionViewModelDelegate, SCUAddFavoriteViewControllerDelegate>

@property (nonatomic) SCUFavoritesCollectionViewModel *favoritesModel;
@property (nonatomic, getter = isEditing) BOOL editing;

@end

@implementation SCUFavoritesCollectionViewController

@synthesize servicesFirst = _servicesFirst;

- (instancetype)initWithModel:(SCUFavoritesCollectionViewModel *)model
{
    self = [super init];
    if (self)
    {
        self.favoritesModel = model;
        self.favoritesModel.delegate = self;
        self.model = self.favoritesModel.serviceModel;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.model viewWillAppear];
    
//    [SCUInterface sharedInstance].currentService = self.favoritesModel.service;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self tileLayout].delegate = self.favoritesModel;
    [self setTitleForEditingMode:NO];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.delaysContentTouches = NO;
}

- (void)setTitleForEditingMode:(BOOL)editing
{
    if (editing)
    {
        [self sav_updateTitle:NSLocalizedString(@"Edit", nil)];
    }
    else
    {
        [self sav_updateTitle:self.model.service.alias];
    }
}

#pragma mark - SCUMainNavbarManager

- (void)powerOff:(UIBarButtonItem *)sender
{
    [self.model sendCommand:@"PowerOff"];

    [self.navigationController popToRootViewControllerAnimated:YES];
}

//- (SCUMainNavbarItems)mainNavbarItems
//{
//    SCUMainNavbarItems items = SCUMainNavbarItemsDefault;
//
//    if (self.isServicesFirst)
//    {
//        items = SCUMainNavbarItemsEntertainment | SCUMainNavbarItemsRightButtons;
//    }
//
//    if (self.isEditing)
//    {
//        items = SCUMainNavbarItemsLeftButtons | SCUMainNavbarItemsRightButtons | SCUMainNavbarItemsRightSpacing;
//    }
//
//    return items;
//}

- (NSArray *)mainNavbarLeftButtonItems
{
    return @[[UIView new]];
}

- (NSArray *)mainNavbarRightButtonItems
{
    NSArray *rightButtonItems = nil;

    if (self.isEditing)
    {
        SCUToolbarButton *editMode = [[SCUToolbarButton alloc] initWithTitle:NSLocalizedString(@"Done", nil)];
        editMode.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        editMode.color = [[SCUColors shared] color01];
        editMode.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.6];
        editMode.target = self;
        editMode.releaseAction = @selector(leaveEditMode:);
        CGRect frame = editMode.frame;
        //-------------------------------------------------------------------
        // CBP TODO: find text width
        //-------------------------------------------------------------------
        frame.size.width = 70;
        editMode.frame = frame;
        rightButtonItems = @[editMode];
    }
    else
    {
        SCUToolbarButton *powerOff = [[SCUToolbarButton alloc] initWithImage:[UIImage imageNamed:@"Power"]];
        powerOff.target = self;
        powerOff.releaseAction = @selector(powerOff:);
        powerOff.color = [[SCUColors shared] color01];

        rightButtonItems = @[powerOff];
    }

    return rightButtonItems;
}

- (NSNumber *)mainNavbarItemsRightSpacing
{
    return @0;
}

#pragma mark - SCUModelCollectionViewController methods

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUReorderableTileLayout *layout = [[SCUReorderableTileLayout alloc] init];
    layout.allCellsAre1x1 = YES;

    return layout;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUReorderableTileLayout *tileLayout = [self tileLayout];
    tileLayout.interItemSpacing = 2;
    tileLayout.contentInsets = UIEdgeInsetsMake(2, 0, 2, 0);
    
    if ([UIDevice isPhone])
    {
        tileLayout.numberOfVisibleColumns = 2;
    }
    else
    {
        if (UIInterfaceOrientationIsPortrait(orientation))
        {
            tileLayout.numberOfVisibleColumns = 3;
        }
        else
        {
            tileLayout.numberOfVisibleColumns = 4;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tileLayout invalidateLayout];
    });
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.favoritesModel;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUFavoritesEditableCollectionViewCell class] forCellType:0];
}

- (SCUReorderableTileLayout *)tileLayout
{
    return (SCUReorderableTileLayout *)self.collectionView.collectionViewLayout;
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    SCUScenesCollectionViewCell *cell = (SCUScenesCollectionViewCell *)c;
    SAVWeakSelf;

    [cell.deleteSceneButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [wSelf.favoritesModel removeFavoriteAtIndexPath:indexPath];
    }];
}

- (void)editFavorite:(SAVFavorite *)favorite
{
    [self leaveEditMode:nil];

    SCUAddFavoriteViewController *vc = [[SCUAddFavoriteViewController alloc] initWithFavorite:favorite];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];

    if ([UIDevice isPad])
    {
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }

    vc.delegate = self;

    [self presentViewController:navController animated:YES completion:NULL];
}

#pragma mark - SCUFavoritesCollectionViewModelDelegate methods

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)reloadIndexPaths:(NSArray *)indexPaths
{
    if ([indexPaths count])
    {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)reconfigureIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths)
    {
        SCUDefaultCollectionViewCell *cell = (SCUDefaultCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell configureWithInfo:[self.favoritesModel modelObjectForIndexPath:indexPath]];
    }
}

- (void)setEditingMode:(BOOL)editing
{
    self.editing = editing;
    [self setTitleForEditingMode:editing];
    [self updateNavBar];
}

#pragma mark - SCUAddFavoriteViewControllerDelegate

- (void)updateFavorite:(SAVFavorite *)favorite
{
    [self.favoritesModel saveFavorite:favorite];
}

#pragma mark -

- (void)leaveEditMode:(UIBarButtonItem *)sender
{
    [[self tileLayout] endEditing];
}

- (void)updateNavBar
{
//    SCUNavigationBar *navigationBar = (SCUNavigationBar *)self.navigationController.navigationBar;
//    [navigationBar configureWithManager:(UIViewController <SCUMainNavbarManager> *)self.parentViewController];
}

- (void)fetchSystemImages:(SCUFavoriteSystemImageResults)results
{
    [self.favoritesModel fetchSystemImages:results];
}

#pragma mark - SCUMainToolbarManager

//- (BOOL)mainToolbarIsVisible
//{
//    return NO;
//}
//
//- (SCUMainToolbarItems)mainToolbarItems
//{
//    return SCUMainToolbarItemsNone;
//}

#pragma mark - SCUTabBarControllerContentView methods

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"favorites"];
}

#pragma mark - SCUServiceViewProtocol

- (void)setServicesFirst:(BOOL)servicesFirst
{
    _servicesFirst = servicesFirst;

    if (servicesFirst)
    {
        if ([self.model respondsToSelector:@selector(setShouldPowerOn:)])
        {
            self.model.shouldPowerOn = NO;
        }

        if ([self.model respondsToSelector:@selector(setServicesFirst:)])
        {
            self.model.servicesFirst = servicesFirst;
        }
    }
}

- (SAVService *)service
{
    return self.isServicesFirst ? self.model.serviceGroup.wildCardedService : self.model.service;
}

- (SAVServiceGroup *)serviceGroup
{
    return self.model.serviceGroup;
}

@end
