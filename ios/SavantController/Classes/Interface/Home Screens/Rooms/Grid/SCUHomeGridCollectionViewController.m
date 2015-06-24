//
//  SCUHomeGridCollectionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeGridCollectionViewController.h"
#import "SCUHomeCollectionViewModel.h"
#import "SCUHomeGridCell.h"
#import "SCUHomeGridHeaderCell.h"
#import "SCUCollectionViewPagedLayout.h"
#import "SCUNavigationBar.h"
#import "SCUInterface.h"
#import "SCUHomePageCollectionViewController.h"
#import "SCUCameraFlowLayout.h"
#import "SCUButton.h"
#import "SCUPopoverMenu.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUHomeGridCollectionViewController ()

@property (nonatomic) NSIndexPath *currentIndex;
@property (nonatomic) SCUHomeCollectionViewModel *model;
@property SCUPopoverMenu *roomGroupMenu;
@property (nonatomic) SCUButton *headerButton;

@end

@implementation SCUHomeGridCollectionViewController

- (instancetype)initWithRoom:(SAVRoom *)room delegate:(id<SCUHomeCollectionViewControllerDelegate>)delegate model:(SCUHomeCollectionViewModel *)model
{
    self = [super initWithRoom:room delegate:delegate model:model];
    if (self)
    {
        if (room)
        {
            [self presentFullscreenView:NO];
        }

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

                if ([self.delegate respondsToSelector:@selector(willSwitchToRoomGroup:)])
                {
                    [self.delegate willSwitchToRoomGroup:room.group];
                }

                self.currentIndex = indexPath;

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

    self.collectionView.alwaysBounceVertical = YES;
    self.title = NSLocalizedString(@"Rooms", nil);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self sav_notifyWhenNavigatedBack:^{
        [SCUInterface sharedInstance].currentRoom = nil;
    }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (!self.viewHasLoaded)
    {
        [self scrollToPage:self.currentIndex.section animated:NO];
        self.viewHasLoaded = YES;
    }
}

- (void)presentRoomGroupFilter:(SCUButton *)button
{
    NSMutableArray *roomNames = [NSMutableArray arrayWithArray:self.model.roomGroups];

    [roomNames insertObject:NSLocalizedString(@"All Rooms", nil) atIndex:0];

    NSInteger otherIdx = [roomNames indexOfObject:[NSNull null]];
    if (otherIdx != NSNotFound)
    {
        roomNames[otherIdx] = NSLocalizedString(@"Other", nil);
    }

    self.roomGroupMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:roomNames];
    self.roomGroupMenu.selectedIndex = [roomNames indexOfObject:self.model.selectedRoomGroupName];
    SAVWeakSelf;
    self.roomGroupMenu.callback = ^(NSInteger indexPath){
        if (indexPath != -1)
        {
            if (indexPath == 0)
            {
                wSelf.model.filterRoomGroup = nil;
            }
            else if (indexPath == otherIdx)
            {
                wSelf.model.filterRoomGroup = [NSNull null];
            }
            else
            {
                wSelf.model.filterRoomGroup = roomNames[indexPath];
            }

            wSelf.headerButton.title = [roomNames[indexPath] uppercaseString];
            [wSelf.collectionView reloadData];
        }
    };
    [self.roomGroupMenu showFromView:button.titleLabel animated:YES];
}

#pragma mark - SCUMainNavbarManager

- (SCUMainNavbarItems)mainNavbarItems
{
    return SCUMainNavbarItemsNavigation | SCUMainNavbarItemsEntertainment;
}

#pragma mark - SCUMainToolbar

- (BOOL)mainToolbarIsVisible
{
    return NO;
}

#pragma mark - Methods to subclass

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];

    if (self.model.hasRoomGroups && [UICollectionElementKindSectionHeader isEqualToString:UICollectionElementKindSectionHeader])
    {
        SCUButton *headerButton = [[SCUButton alloc] initWithTitle:[self.model.selectedRoomGroupName uppercaseString]];
        headerButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        headerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        headerButton.titleEdgeInsets = UIEdgeInsetsMake(3 + [UIScreen screenPixel], 15, 0, 0);
        headerButton.color = [[SCUColors shared] color03shade07];
        headerButton.backgroundColor = [[SCUColors shared] color03shade01];
        headerButton.frame = CGRectMake(0, -44, CGRectGetWidth(self.collectionView.bounds), 44);
        headerButton.target = self;
        headerButton.releaseAction = @selector(presentRoomGroupFilter:);
        headerButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIImageView *down = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"white_arrow_down" tintColor:[[SCUColors shared] color03shade07]]];
        down.contentMode = UIViewContentModeScaleAspectFit;
        [headerButton addSubview:down];
        [headerButton sav_pinView:down withOptions:SAVViewPinningOptionsCenterY withSpace:2 + [UIScreen screenPixel]];
        [headerButton sav_pinView:down withOptions:SAVViewPinningOptionsToRight withSpace:22];
        [headerButton sav_setSize:CGSizeMake(10, 10) forView:down isRelative:NO];

        [headerView addSubview:headerButton];
        [headerView sav_addFlushConstraintsForView:headerButton];

        self.headerButton = headerButton;
    }

    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
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

    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *layout = [[SCUCollectionViewFlowLayout alloc] init];
    layout.stickyHeader = YES;
    return layout;
}

- (void)configureLayout:(UICollectionViewLayout *)lt withOrientation:(UIInterfaceOrientation)orientation
{
    SCUCollectionViewFlowLayout *layout = (SCUCollectionViewFlowLayout *)lt;

    layout.sectionInset = UIEdgeInsetsMake(2, 0, 2, 0);
    if (self.model.hasRoomGroups)
    {
        layout.headerReferenceSize = CGSizeMake(self.collectionViewLayout.collectionViewContentSize.width, 40);
    }

    if ([UIDevice isPad])
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            layout.itemSize = CGSizeMake(331, 331 * .9);
        }
        else
        {
            layout.itemSize = CGSizeMake(376, 376 * .8);
        }
    }
    else
    {
        //-------------------------------------------------------------------
        // CBP TODO: This will need to change if we ever support rotation
        // on phone.
        //-------------------------------------------------------------------
        layout.itemSize = CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]), CGRectGetHeight(self.collectionView.bounds) * .42);
    }

    layout.minimumLineSpacing = 15;
    layout.minimumInteritemSpacing = 15;

    [layout invalidateLayout];
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

- (void)updateCurrentIndexAfterDelay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];

    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];

    if (!indexPath)
    {
        return;
    }

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

    self.currentIndex = indexPath;

    if (switchingSections)
    {
        if ([self.delegate respondsToSelector:@selector(didSwitchRoomGroups)])
        {
            [self.delegate didSwitchRoomGroups];
        }
    }
}

- (id<SCUDataSourceModel>)collectionViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.collectionView sav_registerClass:[SCUHomeGridCell class] forCellType:0];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
}

- (void)configureCell:(SCUDefaultCollectionViewCell *)cell withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    [super configureCell:cell withType:type indexPath:indexPath];

    SCUHomeGridCell *c = (SCUHomeGridCell *)cell;
    c.activeService = [self.model activeServiceForIndexPath:indexPath];
    c.lightsAreOn = [self.model lightsAreOnForIndexPath:indexPath];
	c.fansAreOn = [self.model fansAreOnForIndexPath:indexPath];
    c.currentTemperature = [self.model currentTemperatureForIndexPath:indexPath];
    c.hasSecurityAlert = [self.model hasSecurityAlertForIndexPath:indexPath];
    [c endUpdates];
}

- (void)presentFullscreenView:(BOOL)animated
{
    SCUHomePageCollectionViewController *homePage = [[SCUHomePageCollectionViewController alloc] initWithRoom:[SCUInterface sharedInstance].currentRoom delegate:self.model model:self.model];

    [[SCUInterface sharedInstance].currentContentViewController presentViewController:homePage animated:animated];
}

@end
