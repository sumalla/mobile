//
//  SCUSecurityCamerasViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityCamerasViewController.h"
#import "SCUSecurityCameraModel.h"
#import "SCUCameraFlowLayout.h"
#import "SCUCameraCollectionViewCell.h"
#import "SCUCameraFullScreenViewController.h"
#import "SCUCameraHeaderCell.h"
#import "SCUCameraAnimator.h"

@interface SCUSecurityCamerasViewController () <SCUSecurityCameraModelDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic) SCUSecurityCameraModel *model;
@property SCUCameraFullScreenViewController *fullScreenView;
@property NSMutableDictionary *animatorsByEntity;

@end

@implementation SCUSecurityCamerasViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUSecurityCameraModel alloc] initWithService:service];
        self.model.delegate = self;
        self.animatorsByEntity = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (![UIDevice isPad])
    {
		[[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    }
}

#pragma mark - Security Camera Model Delegate

- (void)receivedImage:(UIImage *)image ofScale:(SAVCameraEntityScale)scale forIndexPath:(NSIndexPath *)indexPath
{
    if (scale & SAVCameraEntityScale_Preview)
    {
        SCUCameraCollectionViewCell *cell = (SCUCameraCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.imageView.image = image;
    }
}

- (NSArray *)visibleIndexes
{
    return self.collectionView.indexPathsForVisibleItems;
}

#pragma mark - CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];

    SCUCameraFullScreenViewController *fullScreenView = [[DeviceClassFromClass([SCUCameraFullScreenViewController class]) alloc] initWithCameraEntity:[self.model modelObjectForIndexPath:indexPath]];
    fullScreenView.modalPresentationStyle = UIModalPresentationCustom;
    fullScreenView.transitioningDelegate = self;

    CGFloat originalOffset = self.collectionView.contentOffset.y;
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    CGFloat offset = self.collectionView.contentOffset.y;

    if (originalOffset == offset)
    {
        self.fullScreenView = nil;
        [self presentViewController:fullScreenView animated:YES completion:nil];
    }
    else
    {
        self.fullScreenView = fullScreenView;

        [self.collectionView setContentOffset:CGPointMake(0, originalOffset) animated:NO];
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (self.fullScreenView)
    {
        [self presentViewController:self.fullScreenView animated:YES completion:nil];
        self.fullScreenView = nil;
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    SCUCameraFullScreenViewController *fullScreenViewController = (SCUCameraFullScreenViewController *)presented;

    SCUCameraAnimator *animator = [[SCUCameraAnimator alloc] init];
    animator.presenting = YES;
    animator.cellImageView = [(SCUCameraCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[self.model indexPathForEntity:fullScreenViewController.entity]] imageView];

    //-------------------------------------------------------------------
    // Stop the preview streams if we've been on a fullscreen view for 10 seconds
    //-------------------------------------------------------------------
    [self.model performSelector:@selector(viewWillDisappear) withObject:nil afterDelay:10];

    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    SCUCameraFullScreenViewController *fullScreenViewController = (SCUCameraFullScreenViewController *)dismissed;

    SCUCameraAnimator *animator = [[SCUCameraAnimator alloc] init];
    animator.cellImageView = [(SCUCameraCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[self.model indexPathForEntity:fullScreenViewController.entity]] imageView];

    //-------------------------------------------------------------------
    // Resume the preview streams
    //-------------------------------------------------------------------
    [NSObject cancelPreviousPerformRequestsWithTarget:self.model selector:@selector(viewWillDisappear) object:nil];
    [self viewWillAppear:YES];
    [self viewDidAppear:YES];

    return animator;
}

#pragma mark - Methods to subclass

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    return [[SCUCameraFlowLayout alloc] init];
}

- (id <SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUCameraCollectionViewCell class] forCellType:0];
    [self.collectionView sav_registerClass:[SCUCameraHeaderCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader forCellType:0];
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"security-camera"];
}

- (UIColor *)tabBarButtonColor
{
    return [[SCUColors shared] color01];
}

@end
