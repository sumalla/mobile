//
//  SCUSceneSaveStockImageViewController.m
//  SavantController
//
//  Created by Stephen Silber on 10/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSaveStockImageCell.h"
#import "SCUSceneSaveStockImageDataSource.h"
#import "SCUSceneSaveStockImageViewController.h"
#import "SCUReorderableTileLayout.h"
#import "SCUToolbarButton.h"
@import SDK;

@interface SCUSceneSaveStockImageViewController () <SCUScenesSaveStockImageDelegate, SCUReorderableTileLayoutDelegate>

@property (nonatomic) SCUSceneSaveStockImageDataSource *model;

@end

@implementation SCUSceneSaveStockImageViewController

- (instancetype)initWithScene:(SAVScene *)scene
{
    self = [super init];
    
    if (self)
    {
        self.model = [[SCUSceneSaveStockImageDataSource alloc] initWithScene:scene];
        self.model.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Select Image", nil);
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.delaysContentTouches = NO;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonTapped:)];
    saveButton.tintColor = [[SCUColors shared] color01];

    [saveButton setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateNormal];
    [saveButton setTitleTextAttributes:@{NSForegroundColorAttributeName : [[SCUColors shared] color03shade08],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:17]} forState:UIControlStateDisabled];

    self.navigationItem.rightBarButtonItem = saveButton;
    self.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
}

- (void)saveButtonTapped:(id)sender
{
    [self.model saveSelectedImage];
    
    if (self.callback)
    {
        self.callback();
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonTapped:(id)sender
{
    if (self.callback)
    {
        self.callback();
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SCUModelCollectionViewController methods

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUReorderableTileLayout *layout = [[SCUReorderableTileLayout alloc] init];
    layout.delegate = self;
    return layout;
}

- (void)configureLayout:(UICollectionViewLayout *)lt withOrientation:(UIInterfaceOrientation)orientation
{
    SCUReorderableTileLayout *layout = (SCUReorderableTileLayout *)lt;
    layout.interItemSpacing = 4;
    layout.contentInsets = UIEdgeInsetsMake(4, 0, 0, 0);

    if ([UIDevice isPad])
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            layout.numberOfVisibleColumns = 3;
        }
        else
        {
            layout.numberOfVisibleColumns = 3;
        }
    }
    else
    {
        layout.numberOfVisibleColumns = 2;
    }
    
    [layout invalidateLayout];
}

- (void)layout:(SCUReorderableTileLayout *)layout moveIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    ;
}

- (id)dataSource
{
    return nil;
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canEditItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)layout:(SCUReorderableTileLayout *)layout canReplaceItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)reloadCellAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUSceneSaveStockImageCell class] forCellType:0];
}

#pragma mark - SCUScenesModelDelegate methods

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
        [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];
    }
}

@end
