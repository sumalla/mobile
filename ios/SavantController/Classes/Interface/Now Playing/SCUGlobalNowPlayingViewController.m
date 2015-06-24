//
//  SCUNowPlayingViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingViewController.h"
#import "SCUGlobalNowPlayingModel.h"
#import "SCUPassthroughViewController.h"
#import "SCUButton.h"
#import "SCUInterface.h"
#import "SCURoomDistributionViewController.h"
#import "SCUNowPlayingFullScreenViewControllerPhone.h"
#import "SCUNowPlayingFullScreenViewControllerPad.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUAnalytics.h"
#import "SCUGlobalNowPlayingStatusCell.h"
#import "SCUGlobalNowPlayingTransportsCell.h"
#import "SCUGlobalNowPlayingDistributeCell.h"
#import "SCUVolumeTableViewCell.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUVolumeViewController.h"
#import "SCUSlingshot.h"


#import <SavantControl/SavantControl.h>

@interface SCUGlobalNowPlayingViewController () <SCUGlobalNowPlayingModelDelegate>

@property SCUGlobalNowPlayingModel *model;
@property (weak) SCUPassthroughViewController *passthrough;
@property UIActivityIndicatorView *loadingIndicator;
@property NSMutableDictionary *sectionBackgrounds;

@end

@implementation UITableView (SCUCancelAllTouches)

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}

@end

@implementation SCUGlobalNowPlayingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.sectionBackgrounds = [NSMutableDictionary dictionary];

    [SCUAnalytics recordEvent:@"Now Playing Screen"];

    self.model = [[SCUGlobalNowPlayingModel alloc] init];
    self.model.delegate = self;

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"x"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissButtonPressed:)];

    self.title = NSLocalizedString(@"Now Playing", nil);

    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    self.passthrough = (SCUPassthroughViewController *)self.parentViewController;

    [self reloadSectionBackgrounds];
}

- (void)userInteractionDetected:(CGPoint)point
{
    [self.model userInteractionDetected];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self applyEdgeInsetsForOrentiation:[UIDevice deviceOrientation]];

    //-------------------------------------------------------------------
    // Kick states for all visible volume cells when returning from distribution
    //-------------------------------------------------------------------
    for (UITableViewCell *c in [self.tableView visibleCells])
    {
        if ([c isKindOfClass:[SCUVolumeTableViewCell class]])
        {
            SCUVolumeTableViewCell *cell = (SCUVolumeTableViewCell *)c;
            [cell.volumeVC viewWillAppear:NO];
        }
    }
}

- (void)applyEdgeInsetsForOrentiation:(UIInterfaceOrientation)orientation
{
    if ([UIDevice isPad])
    {
        if (UIInterfaceOrientationIsLandscape(orientation))
        {
            self.passthrough.edgeInsets = UIEdgeInsetsMake(0, 158, 0, 158);
        }
        else
        {
            self.passthrough.edgeInsets = UIEdgeInsetsMake(0, 30, 0, 30);
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self animateInterfaceRotationChangeWithCoordinator:coordinator block:^(UIInterfaceOrientation orientation) {
        [self applyEdgeInsetsForOrentiation:orientation];
    }];
}

- (void)dismissButtonPressed:(UIBarButtonItem *)button
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSIndexSet *)visibleSections
{
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];

    for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows])
    {
        [sections addIndex:indexPath.section];
    }

    return [sections copy];
}

#pragma mark - LMQ Now Playing

- (UINavigationController *)nowPlayingViewForServiceGroup:(SAVServiceGroup *)service
{
    UINavigationController *navController = nil;

    if ([service.serviceId containsString:@"LIVEMEDIAQUERY"] ||
        [service.serviceId isEqualToString:@"SVC_AV_DIGITALAUDIO"])
    {
        SCUNowPlayingViewController *nowPlaying = nil;

        if ([UIDevice isPhone])
        {
            nowPlaying = [[SCUNowPlayingFullScreenViewControllerPhone alloc] initWithService:service.wildCardedService serviceGroup:service];
        }
        else
        {
            nowPlaying = [[SCUNowPlayingFullScreenViewControllerPad alloc] initWithService:service.wildCardedService serviceGroup:service];
        }

        if (nowPlaying)
        {
            navController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:nowPlaying];
            nowPlaying.showServicesFirstButton = YES;
            nowPlaying.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"x"]
                                                                                              style:UIBarButtonItemStylePlain
                                                                                             target:self
                                                                                             action:@selector(dismissModal)];
        }
    }

    return navController;
}

- (void)dismissModal
{
    [[self presentedViewController] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table View 

- (CGFloat)heightForCellWithType:(NSUInteger)type
{
    NSUInteger cellHeight = self.tableView.rowHeight;

    switch (type)
    {
        case SCUGlobalNowPlayingCellType_Status:
            cellHeight = [UIDevice isPad] ? 108 : 104;
            break;
        case SCUGlobalNowPlayingCellType_Transports:
        case SCUGlobalNowPlayingCellType_Toggle:
        case SCUGlobalNowPlayingCellType_Volume:
        case SCUGlobalNowPlayingCellType_Distribute:
            cellHeight = 50;
            break;
    }

    return cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    SCUGlobalNowPlayingCellTypes type = [self.model cellTypeForAbsoluteIndexPath:indexPath];

    switch (type)
    {
        case SCUGlobalNowPlayingCellType_Status:
        {
            SAVServiceGroup *serviceGroup = [self.model serviceGroupForSection:indexPath.section];

            UINavigationController *nowPlayingVC = [self nowPlayingViewForServiceGroup:serviceGroup];

            if (nowPlayingVC && [[self.model statusStringForServiceGroup:serviceGroup] length])
            {
                [self presentViewController:nowPlayingVC animated:YES completion:NULL];
            }
            else if ([[SCUInterface sharedInstance] hasViewControllerForSerivce:serviceGroup.wildCardedService])
            {
                [[SCUInterface sharedInstance] presentServicesFirstServiceGroup:serviceGroup animated:NO];
            }

            break;
        }
        case SCUGlobalNowPlayingCellType_Distribute:
        {
            if ([self.navigationController.topViewController isEqual:self.passthrough])
            {
                SAVServiceGroup *serviceGroup = [self.model serviceGroupForSection:indexPath.section];
                SCURoomDistributionViewController *distribution = [[SCURoomDistributionViewController alloc] initWithServiceGroup:serviceGroup];
                SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:distribution];
                passthrough.backgroundColor = [[SCUColors shared] color03shade01];

                [SCUAnalytics recordEvent:@"Distribution Screen" withKey:@"serviceType" value:serviceGroup.serviceId];

                [self.navigationController pushViewController:passthrough animated:YES];
            }

            break;
        }
        case SCUGlobalNowPlayingCellType_Volume:
        case SCUGlobalNowPlayingCellType_Transports:
        case SCUGlobalNowPlayingCellType_Toggle:
            break;
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)cell withType:(NSUInteger)type forChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    SCUColors *colors = [SCUColors shared];
    cell.backgroundColor = [colors color03shade02];
    cell.bottomLineType = child.row % 2 ? SCUDefaultTableViewCellBottomLineTypeFull : SCUDefaultTableViewCellBottomLineTypeNone;
    cell.borderType = SCUDefaultTableViewCellBorderTypeBottomAndSides;
    cell.bottomLineColor = [colors color03shade04];

    if (type == SCUGlobalNowPlayingCellType_Toggle)
    {
        SCUToggleSwitchTableViewCell *toggleCell = (SCUToggleSwitchTableViewCell *)cell;
        SAVWeakSelf;
        toggleCell.toggleSwitch.sav_didChangeHandler = ^(BOOL on){
            if (!on)
            {
                NSDictionary *modelObject = [wSelf.model modelObjectForChild:child belowIndexPath:indexPath];
                SAVService *service = modelObject[SCUDefaultTableViewCellKeyModelObject];
                [wSelf.model powerOffService:service];
            }
        };
    }
    else if (type == SCUGlobalNowPlayingCellType_Volume)
    {
        SCUVolumeTableViewCell *volumeCell = (SCUVolumeTableViewCell *)cell;

        if ([volumeCell isKindOfClass:[SCUVolumeTableViewCell class]])
        {
            SAVWeakSelf;
            volumeCell.sliderInteractionHandler = ^{
                [wSelf.model userInteractionDetected];
            };
        }
    }
}

- (void)configureCell:(SCUDefaultTableViewCell *)c withType:(NSUInteger)type indexPath:(NSIndexPath *)indexPath
{
    if (type == SCUGlobalNowPlayingCellType_Status && [self.model artworkForSection:indexPath.section])
    {
        c.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:.4];
    }
    else
    {
        c.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:.9];
    }

    switch (type)
    {
        case SCUGlobalNowPlayingCellType_Status:
        {
            SCUGlobalNowPlayingStatusCell *cell = (SCUGlobalNowPlayingStatusCell *)c;

            SAVWeakSelf;
            [cell.powerButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
                SAVServiceGroup *serviceGroup = [wSelf.model serviceGroupForSection:indexPath.section];

                for (SAVService *service in serviceGroup.services)
                {
                    SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:service];
                    serviceRequest.request = @"PowerOff";

                    [[SavantControl sharedControl] sendMessage:serviceRequest];
                }
            }];
        }
            break;

        case SCUGlobalNowPlayingCellType_Volume:
        {
            // only use partial line when collapsed
            SCUVolumeTableViewCell *cell = (SCUVolumeTableViewCell *)c;
            SAVWeakSelf;
            cell.volumeVC.volumeSlingshot.interactionCallback = ^{
                [wSelf.model autoExpandRoomVolumeForSection:indexPath.section];
            };

            if ([self.model.expandedIndexPaths containsObject:indexPath])
            {
                break;
            }
        }
        case SCUGlobalNowPlayingCellType_Toggle:
        case SCUGlobalNowPlayingCellType_Transports:
            c.bottomLineType = SCUDefaultTableViewCellBottomLineTypePartial;
            break;
        case SCUGlobalNowPlayingCellType_Distribute:
        {
            SCUGlobalNowPlayingDistributeCell *cell = (SCUGlobalNowPlayingDistributeCell *)c;

            SAVWeakSelf;
            [cell.expandToggle sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
                SAVStrongWeakSelf;
                NSIndexPath *volumeIndexPath = [sSelf.model volumeIndexPathForSection:indexPath.section];

                BOOL expanded = [sSelf.model toggleRoomVolumeForSection:indexPath.section];

                SCUVolumeTableViewCell *volumeCell = (SCUVolumeTableViewCell *)[sSelf.tableView cellForRowAtIndexPath:[sSelf.model absoluteIndexPathForRelativeIndexPath:volumeIndexPath]];

                if (expanded)
                {
                    volumeCell.bottomLineType = SCUDefaultTableViewCellBottomLineTypeFull;
                }
                else
                {
                    volumeCell.bottomLineType = SCUDefaultTableViewCellBottomLineTypePartial;
                }

            }];
        }
            break;
    }
}

- (id<SCUExpandableDataSourceModel>)tableViewModel
{
    return self.model;
}

- (void)registerCells
{
    [self.tableView sav_registerClass:[SCUGlobalNowPlayingStatusCell class] forCellType:SCUGlobalNowPlayingCellType_Status];
    [self.tableView sav_registerClass:[SCUGlobalNowPlayingTransportsCell class] forCellType:SCUGlobalNowPlayingCellType_Transports];
    [self.tableView sav_registerClass:[SCUVolumeTableViewCell class] forCellType:SCUGlobalNowPlayingCellType_Volume];
    [self.tableView sav_registerClass:[SCUGlobalNowPlayingDistributeCell class] forCellType:SCUGlobalNowPlayingCellType_Distribute];
    [self.tableView sav_registerClass:[SCUToggleSwitchTableViewCell class] forCellType:SCUGlobalNowPlayingCellType_Toggle];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self reloadSectionBackgrounds];
}

#pragma mark - Model Delegate

- (void)toggleIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:.25 animations:^{
            [super toggleIndex:indexPath animated:animated];

            [self reloadSectionBackgrounds];
        }];
    }
    else
    {
        [super toggleIndex:indexPath animated:animated];

        [self reloadSectionBackgrounds];
    }
}

- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:.25 animations:^{
            [super collapseIndex:indexPath animated:animated];

            [self reloadSectionBackgrounds];
        }];
    }
    else
    {
        [super collapseIndex:indexPath animated:animated];

        [self reloadSectionBackgrounds];
    }
}

- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:15 options:0 animations:^{
            [super expandIndex:indexPath animated:animated];
            [self reloadSectionBackgrounds];
        } completion:nil];
    }
    else
    {
        [super expandIndex:indexPath animated:animated];

        [self reloadSectionBackgrounds];
    }
}

- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated updateBlock:(dispatch_block_t)update
{
    if (animated)
    {
        [UIView animateWithDuration:.25 animations:^{
            [super updateNumberOfChildrenBelowIndexPath:indexPath animated:animated updateBlock:update];

            [self reloadSectionBackgrounds];
        }];
    }
    else
    {
        [super updateNumberOfChildrenBelowIndexPath:indexPath animated:animated updateBlock:update];

        [self reloadSectionBackgrounds];
    }
}

- (void)reloadSectionBackgrounds
{
    NSIndexSet *visibleSections = [self visibleSections];

    [visibleSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self reloadBackgroundForSection:idx];
    }];

    //-------------------------------------------------------------------
    // Purge unused views
    //-------------------------------------------------------------------
    NSMutableIndexSet *unusedSections = [self allSections];
    [unusedSections removeIndexes:visibleSections];

    [unusedSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIImageView *view = self.sectionBackgrounds[@(idx)];
        [view removeFromSuperview];
        view.image = nil;
    }];
}

- (void)reloadBackgroundForSection:(NSInteger)section
{
    if (section < [self.tableView numberOfSections])
    {
        UIImageView *sectionBackground = self.sectionBackgrounds[@(section)];

        if (!sectionBackground)
        {
            NSMutableIndexSet *unusedSections = [self allSections];
            [unusedSections removeIndexes:[self visibleSections]];

            if ([unusedSections count])
            {
                NSNumber *reuseSection = @([unusedSections firstIndex]);
                sectionBackground = self.sectionBackgrounds[reuseSection];
                [self.sectionBackgrounds removeObjectForKey:reuseSection];
            }
            else
            {
                sectionBackground = [[UIImageView alloc] initWithFrame:CGRectZero];
                sectionBackground.alpha = .2;
                sectionBackground.contentMode = UIViewContentModeScaleAspectFill;
                sectionBackground.clipsToBounds = YES;
            }

            self.sectionBackgrounds[@(section)] = sectionBackground;
        }

        [self.view addSubview:sectionBackground];
        [self.view sendSubviewToBack:sectionBackground];
        sectionBackground.image = [self.model artworkForSection:section];
        sectionBackground.frame = [self rectForSection:section];
    }
}

- (NSMutableIndexSet *)allSections
{
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSet];

    for (NSNumber *section in [self.sectionBackgrounds allKeys])
    {
        [sections addIndex:[section unsignedIntegerValue]];
    }

    return sections;
}

- (CGRect)rectForSection:(NSInteger)section
{
    //-------------------------------------------------------------------
    // Calculate the rect for the parent items so the background image
    // doesn't move when expanding/collapsing
    //-------------------------------------------------------------------

    CGRect rect = [self.tableView rectForHeaderInSection:section];
    rect.origin.y += CGRectGetHeight(rect);
    rect.size.height = 0;

    for (NSInteger i = 0; i < [self.model numberOfItemsInSection:section]; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];

        if (![self.model parentForAbsoluteIndexPath:indexPath])
        {
            rect.size.height += CGRectGetHeight([self.tableView rectForRowAtIndexPath:indexPath]);
        }
    }

    return rect;
}

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath
{
    SCUDefaultTableViewCell *cell = (SCUDefaultTableViewCell *)[self.tableView cellForRowAtIndexPath:[self.model absoluteIndexPathForRelativeIndexPath:indexPath]];
    [cell configureWithInfo:[self.model modelObjectForIndexPath:indexPath]];

    [self reloadBackgroundForSection:indexPath.section];
}

- (void)reloadData
{
    if (self.loadingIndicator)
    {
        [self.loadingIndicator stopAnimating];
        [self.loadingIndicator removeFromSuperview];
        self.loadingIndicator = nil;
    }

    if ([self.model numberOfSections])
    {
        //-------------------------------------------------------------------
        // Animate first tableview reload
        //-------------------------------------------------------------------
        if (![[self.tableView visibleCells] count])
        {
            CATransition *transition = [CATransition animation];
            transition.type = kCATransitionFade;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.fillMode = kCAFillModeForwards;
            transition.duration = 0.2;

            [[self.tableView layer] addAnimation:transition forKey:@"UITableViewReloadDataAnimationKey"];
        }

        [self.tableView reloadData];

        [self reloadSectionBackgrounds];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)showSpinner
{
    if (!self.loadingIndicator)
    {
        self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.loadingIndicator.hidesWhenStopped = YES;

        [self.passthrough.view addSubview:self.loadingIndicator];
        [self.passthrough.view sav_addCenteredConstraintsForView:self.loadingIndicator];

        [self.loadingIndicator startAnimating];
    }
}

@end
