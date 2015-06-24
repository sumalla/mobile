//
//  SCUHomePageCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomePageCollectionViewController.h"
#import "SCUHomeCollectionViewModel.h"
#import "SCUHomePageCell.h"
#import "SCUCollectionViewFlowLayout.h"
#import "SCUInterface.h"

#import <SAVService.h>
#import <SAVRoom.h>
#import <SAVRoomGroup.h>

@interface SCUHomePageCollectionViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSIndexPath *currentIndex;
@property (nonatomic) SCUHomeCollectionViewModel *model;

@end

@implementation SCUHomePageCollectionViewController

- (instancetype)initWithRoom:(SAVRoom *)room delegate:(id<SCUHomeCollectionViewControllerDelegate>)delegate model:(SCUHomeCollectionViewModel *)model
{
    self = [super initWithRoom:room delegate:delegate model:model];
    if (self)
    {
        // the requested room didn't exist, setup the default after init
        if (!self.currentIndex)
        {
            //-------------------------------------------------------------------
            // CBP TODO: What does a room not being here mean? It will crash, how should
            // it be handled? Putting a check around it for now.
            //-------------------------------------------------------------------
            if ([self.model numberOfItemsInSection:0])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];

                room = [self.model roomForIndexPath:indexPath];

                if ([self.delegate respondsToSelector:@selector(willSwitchToRoom:)])
                {
                    [self.delegate willSwitchToRoom:room];
                }

                if ([self.delegate respondsToSelector:@selector(willSwitchToRoomGroup:)])
                {
                    [self.delegate willSwitchToRoomGroup:room.group];
                }

                self.currentIndex = indexPath;

                if ([self.delegate respondsToSelector:@selector(didSwitchRoom)])
                {
                    [self.delegate didSwitchRoom];
                }

                if ([self.delegate respondsToSelector:@selector(didSwitchRoomGroups)])
                {
                    [self.delegate didSwitchRoomGroups];
                }
            }
        }
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.pagingEnabled = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    self.title = self.model.selectedRoomGroupName;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (!self.viewHasLoaded)
    {
        [self scrollToPage:self.currentIndex.row animated:NO];
        self.viewHasLoaded = YES;
    }
}

#pragma mark - Methods to subclass

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *layout = [[SCUCollectionViewFlowLayout alloc] init];
    
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;

    return layout;
}

- (void)configureLayout:(UICollectionViewLayout *)layout withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *flowLayout = (SCUCollectionViewFlowLayout *)layout;

    dispatch_next_runloop(^{
        flowLayout.itemSize = self.view.bounds.size;

        [self.collectionViewLayout invalidateLayout];

        [self scrollToPage:self.currentIndex.row animated:NO];
    });
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated
{
    CGFloat pageWidth = CGRectGetWidth(self.collectionView.frame);
    CGPoint scrollTo = CGPointMake(pageWidth * page, 0);

    [self.collectionView setContentOffset:scrollTo animated:animated];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:scrollView];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCurrentIndexAfterDelay) object:nil];
    [self performSelector:@selector(updateCurrentIndexAfterDelay) withObject:nil afterDelay:.01];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];


    if (self.viewHasLoaded)
    {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:0];
        CGFloat pageWidth = self.collectionViewLayout.itemSize.width;
        CGFloat currentOffset = scrollView.contentOffset.x;

        NSInteger currentIndex = roundf(currentOffset / pageWidth);
        if (currentIndex >= numberOfItems)
        {
            currentIndex = numberOfItems - 1;
        }
        else if (currentIndex < 0)
        {
            currentIndex = 0;
        }

        CGFloat position = currentOffset - (pageWidth * currentIndex);
        CGFloat percentage = position / pageWidth;
        CGFloat translation = percentage * (pageWidth / 2);

        SCUHomePageCell *currentPage = (SCUHomePageCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex inSection:0]];
        currentPage.clipsToBounds = YES;

        //-------------------------------------------------------------------
        // Move the "main" view.
        //-------------------------------------------------------------------
        if (!currentPage.isDisplayingDefaultImage)
        {
            CGRect frame = currentPage.bounds;
            frame.origin.x = translation;
            currentPage.backgroundView.frame = frame;
        }

        //-------------------------------------------------------------------
        // Move the view that's coming on to screen.
        //-------------------------------------------------------------------
        SCUHomePageCell *nextPage = nil;
        CGFloat nextTranslation = 0;

        if (percentage > 0)
        {
            if (currentIndex < (NSInteger)([self.model numberOfItemsInSection:0] - 1))
            {
                nextPage = (SCUHomePageCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex + 1 inSection:0]];
                nextTranslation = -((pageWidth / 2) - translation);
            }
        }
        else
        {
            if ((currentIndex - 1) >= 0)
            {
                nextPage = (SCUHomePageCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentIndex - 1 inSection:0]];
                nextTranslation = ((pageWidth / 2) + translation);
            }
        }

        if (nextTranslation && nextPage)
        {
            if (!nextPage.isDisplayingDefaultImage)
            {
                CGRect frame = nextPage.bounds;
                frame.origin.x = nextTranslation;
                nextPage.backgroundView.frame = frame;
            }
        }
        else
        {
            CGRect frame = currentPage.bounds;
            frame.origin.x = position;
            currentPage.backgroundView.frame = frame;
            currentPage.clipsToBounds = NO;
        }
    }
}

- (void)updateCurrentIndexAfterDelay
{
    if ([[self.collectionView indexPathsForVisibleItems] count] > 1)
    {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];

    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];

    if (indexPath && self.viewHasLoaded)
    {
        SAVRoom *room = [self.model roomForIndexPath:indexPath];

        BOOL switchingSections = NO;

        if (indexPath.section != self.currentIndex.section)
        {
            switchingSections = YES;
        }

        if (switchingSections)
        {
            if ([self.delegate respondsToSelector:@selector(willSwitchToRoomGroup:)])
            {
                [self.delegate willSwitchToRoomGroup:room.group];
            }
        }

        if ([self.delegate respondsToSelector:@selector(willSwitchToRoom:)])
        {
            [self.delegate willSwitchToRoom:room];
        }

        self.currentIndex = indexPath;

        if (switchingSections)
        {
            if ([self.delegate respondsToSelector:@selector(didSwitchRoomGroups)])
            {
                [self.delegate didSwitchRoomGroups];
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(didSwitchRoom)])
        {
            [self.delegate didSwitchRoom];
        }
    }
}

#pragma mark - Methods to subclass

- (void)presentServiceDrawer:(BOOL)animated
{
    [[SCUInterface sharedInstance].currentDrawerViewController openDrawerFromSide:SCUDrawerSideRight animated:animated completion:nil];
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUHomePageCell class] forCellType:0];
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell withType:type indexPath:indexPath];

    SCUHomePageCell *c = (SCUHomePageCell *)cell;

    c.activeService = [self.model activeServiceForIndexPath:indexPath];
    c.lightsAreOn = [self.model lightsAreOnForIndexPath:indexPath];
	c.fansAreOn = [self.model fansAreOnForIndexPath:indexPath];
    c.currentTemperature = [self.model currentTemperatureForIndexPath:indexPath];
    c.hasSecurityAlert = [self.model hasSecurityAlertForIndexPath:indexPath];
    [c endUpdates];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.bounds.size;
}

#pragma mark - SCUMainToolbar

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

@end
