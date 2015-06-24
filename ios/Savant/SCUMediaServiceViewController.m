//
//  SCULMQViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaServiceViewController.h"
#import "SCUMediaServiceViewControllerPrivate.h"
#import "SCUNowPlayingInlineViewControllerPhone.h"
#import "SCUNavBarToolbar.h"
#import "SCUMediaContainerViewController.h"
#import "SCUPassthroughViewController.h"
#import "SCUMediaTabBarModel.h"
#import "SCUPassthroughSupplementaryViewController.h"
#import "SCUNowPlayingFullScreenViewControllerPhone.h"
#import "SCUNowPlayingInlineViewControllerPad.h"
#import "SCUNowPlayingFullScreenViewControllerPad.h"

@interface SCUMediaServiceViewController () <SAVNavigationControllerDelegate, SCUMediaRequestViewControllerModelDelegate>

@property (nonatomic) UIViewController *ignorePopViewController;
@property (nonatomic) BOOL hasLoadedRoot;
@property (nonatomic) SCUMediaContainerViewController *loadingViewController;
@property (nonatomic) SCUMediaDataModel *topTableModel;
@property (nonatomic) SCUPassthroughViewController *tabBarInitialViewController;
@property (nonatomic, weak) SCUPassthroughViewController *weakTabBarInitialViewController;
@property (nonatomic) SCUPassthroughViewController *strongTabBarInitialViewController;
@property (nonatomic) UIBarButtonItem *sceneRightBarButtonItem;
@property (nonatomic) SCUMediaContainerViewController *rootViewController;
@property (nonatomic) SCUMediaTabBarModel *currentTabBarModel;
@property (nonatomic, weak) UIViewController *firstViewController;
@property (nonatomic) SCUPassthroughViewController *rootPassthrough;

@end

@implementation SCUMediaServiceViewController

- (void)dealloc
{
    [self setToolbarHidden:YES];

    if (!self.isNowPlaying)
    {
        SCUNavBarToolbar *toolbar = (SCUNavBarToolbar *)self.navController.toolbar;
        [toolbar clearToolbarItems];
    }

    [self.navController removeDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.rootPassthrough = [[SCUPassthroughViewController alloc] init];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.rootPassthrough.edgesForExtendedLayout = UIRectEdgeNone;

    [self sav_addChildViewController:self.rootPassthrough];
    [self.view addSubview:self.rootPassthrough.view];

    self.navController = self.navigationController;

    [[UINavigationBar appearanceWhenContainedIn:[SCUMediaServiceViewController class], nil] setBackgroundColor:[[SCUColors shared] color03shade02]];
    [[UITableView appearanceWhenContainedIn:[SCUMediaServiceViewController class], nil] setSectionIndexColor:[[SCUColors shared] color01]];
    [[UINavigationBar appearanceWhenContainedIn:[SCUMediaServiceViewController class], nil] setTintColor:[[SCUColors shared] color04]];


    if (self.rootPassthrough && !self.scene)
    {
        SCUPassthroughSupplementaryViewController *viewController = [self createNowPlayingViewController];
        if (viewController)
        {
            [self.rootPassthrough setSupplementaryViewController:viewController withPinningOptions:SAVViewPinningOptionsToTop size:[UIDevice isPhone] ? 50 : 90];
        }
    }

    self.mediaModel = [[SCUMediaRequestViewControllerModel alloc] initWithService:self.model.service ? self.model.service : self.service];
    self.mediaModel.nowPlaying = self.isNowPlaying;
    self.mediaModel.delegate = self;

    if (self.isScene)
    {
        self.sceneRightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", nil)
                                                                        style:UIBarButtonItemStyleDone
                                                                       target:self.mediaModel
                                                                       action:@selector(nextButtonPressed)];
        self.sceneRightBarButtonItem.tintColor = [[SCUColors shared] color01];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.mediaModel viewWillAppear];
    [self.navController addDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.mediaModel viewDidAppear];
    self.firstViewController = self.navController.visibleViewController;
}

#pragma mark - SCUMediaRequestViewControllerModelDelegate methods

- (void)presentTabBarWithModel:(SCUMediaTabBarModel *)model
{
    self.currentTabBarModel = model;
    self.navController.hidesBottomBarWhenPushed = NO;

    if ([UIDevice isPad])
    {
        self.navController.toolbar.backgroundColor = [[SCUColors shared] color03shade01];
    }
    else
    {
        self.navController.toolbar.barTintColor = [[SCUColors shared] color03shade01];
    }

    [self setToolbarHidden:NO];
    self.navController.toolbar.items = model.items;
}

- (void)setHeaderView:(UIView *)headerView
{
    [_headerView removeFromSuperview];

    _headerView = headerView;

    [self.navController.view addSubview:headerView];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self updateHeaderView];
}

- (void)updateHeaderView
{
    SCUMediaContainerViewController *mediaContainer = nil;

    UIViewController *topView = self.navController.topViewController;

    if (topView == self)
    {
        topView = self.rootPassthrough;
    }

    if ([topView isKindOfClass:[SCUPassthroughViewController class]])
    {
        SCUPassthroughViewController *passthroughContainer = (SCUPassthroughViewController *)topView;

        if ([passthroughContainer.rootViewController isKindOfClass:[self class]])
        {
            mediaContainer = self.rootViewController;
        }
        else if ([passthroughContainer.rootViewController isKindOfClass:[SCUMediaContainerViewController class]])
        {
            mediaContainer = (SCUMediaContainerViewController *)passthroughContainer.rootViewController;
        }
    }

    if ([mediaContainer.viewController isKindOfClass:[UITableViewController class]])
    {
        [self applyHeaderViewToViewController:(UITableViewController *)mediaContainer.viewController];
    }
}

- (void)applyHeaderViewToViewController:(UITableViewController *)tableViewController
{
    if (self.headerView)
    {
        //-------------------------------------------------------------------
        // Force reset of header view
        //-------------------------------------------------------------------
        tableViewController.tableView.tableHeaderView = nil;
        tableViewController.tableView.tableHeaderView = self.headerView;
    }
    else
    {
        tableViewController.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];
    }
}

- (void)presentViewControllerWithPresentationStyle:(SCUMediaPresentationStyle)style model:(SCUMediaDataModel *)model title:(NSString *)title
{
    SCUMediaContainerViewController *mediaViewController = self.loadingViewController ? self.loadingViewController : [[SCUMediaContainerViewController alloc] init];
    mediaViewController.title = title;
    mediaViewController.delegate = self;

    switch (style)
    {
        case SCUMediaPresentationStyleTable:
        case SCUMediaPresentationStyleSubmenu:
        {
            [mediaViewController loadModel:model withStyle:SCUMediaContainerPresentationStyleTableView];
            break;
        }
        case SCUMediaPresentationStyleGrid:
        {
            [mediaViewController loadModel:model withStyle:SCUMediaContainerPresentationStyleTableView];
            break;
        }
    }

    SCUMediaDataModel *oldModel = self.topTableModel;

    self.topTableModel = model;

    if (self.loadingViewController)
    {
        self.loadingViewController = nil;
        return;
    }

    if (!self.hasLoadedRoot)
    {
        self.hasLoadedRoot = YES;

        self.rootPassthrough.rootViewController = mediaViewController;

        self.rootViewController = mediaViewController;

        [self updateHeaderView];
    }
    else
    {
        if (style == SCUMediaPresentationStyleSubmenu)
        {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mediaViewController];
            mediaViewController.modal = YES;

            if ([UIDevice isPad] && !self.isScene)
            {
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
            }

            mediaViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                                 target:self
                                                                                                                 action:@selector(dismissModal)];

            [self presentViewController:navController animated:YES completion:NULL];
            self.modalNavigationController = navController;

            SAVWeakSelf;
            navController.sav_dismissalBlock = ^{
                wSelf.topTableModel = oldModel;
            };
        }
        else
        {
            UINavigationController *navController = self.modalNavigationController ? self.modalNavigationController : self.navController;

            if (self.modalNavigationController)
            {
                mediaViewController.modal = YES;
            }

            SCUPassthroughViewController *passthroughContainer = [[SCUPassthroughViewController alloc] initWithRootViewController:mediaViewController];

            if (navController == self.navController && !self.isScene)
            {
                SCUNowPlayingViewController *nowPlaying = [self createNowPlayingViewController];

                if (nowPlaying)
                {
                    [passthroughContainer setSupplementaryViewController:nowPlaying withPinningOptions:SAVViewPinningOptionsToTop size:[UIDevice isPhone] ? 50 : 90];
                }
            }

            if (self.isScene)
            {
                passthroughContainer.backgroundColor = [[SCUColors shared] color03shade01];

                if ([UIDevice isPad])
                {
                    passthroughContainer.edgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
                }
            }

            [navController pushViewController:passthroughContainer animated:YES];
        }
    }
}

- (void)presentTabBarLoadingIndicatorWithTitle:(NSString *)title
{
    SCUMediaContainerViewController *mediaViewController = [[SCUMediaContainerViewController alloc] init];
    mediaViewController.title = title;
    mediaViewController.delegate = self;
    self.loadingViewController = mediaViewController;

    if (self.tabBarInitialViewController)
    {
        if (self.navController.topViewController != self.tabBarParent)
        {
            [self.navController popToViewController:self.tabBarParent animated:NO];
        }

        self.tabBarInitialViewController.rootViewController = mediaViewController;
    }
    else
    {
        if (self.hasLoadedRoot)
        {
            self.tabBarInitialViewController = [[SCUPassthroughViewController alloc] initWithRootViewController:mediaViewController];
            if (!self.scene)
            {
                [self.tabBarInitialViewController setSupplementaryViewController:[self createNowPlayingViewController] withPinningOptions:SAVViewPinningOptionsToTop size:[UIDevice isPhone] ? 50 : 90];
            }
            [self.navController pushViewController:self.tabBarInitialViewController animated:YES];
        }
        else
        {
            self.hasLoadedRoot = YES;

            self.rootPassthrough.rootViewController = mediaViewController;
            self.rootViewController = mediaViewController;
            self.tabBarInitialViewController = self.rootPassthrough;

            [self updateHeaderView];
        }
    }
}

- (void)reachedLeaf
{
    [self.topTableModel stopLoadingIndicator];
    self.navigationItem.rightBarButtonItem.enabled = YES;

    if (self.isNowPlaying)
    {
        if ([UIDevice isPad])
        {
            for (SCUPassthroughViewController *viewController in self.navController.viewControllers)
            {
                if ([viewController isKindOfClass:[SCUPassthroughViewController class]])
                {
                    SCUMediaContainerViewController *container = (SCUMediaContainerViewController *)viewController.rootViewController;

                    if ([container isKindOfClass:[SCUMediaContainerViewController class]] && container.nowPlayingViewController)
                    {
                        [self.navController popToViewController:viewController animated:YES];
                        break;
                    }
                }
            }
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    }
}

- (void)popNavigationController
{
    self.ignorePopViewController = [self.navController.viewControllers secondToLastObject];
    [self.navController popViewControllerAnimated:YES];
}

- (void)resetNavigationDelegate
{
    [self.navController addDelegate:self];
}

- (void)navigateToRoot
{
    [self.navController popToViewController:self.firstViewController animated:YES];
    self.hasLoadedRoot = NO;
}

#pragma mark - UINavigationControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    BOOL hideTabBar = YES;

    SCUPassthroughViewController *passthroughContainer = viewController == self ? self.rootPassthrough : (SCUPassthroughViewController *)viewController;

    if ([passthroughContainer isKindOfClass:[SCUPassthroughViewController class]] &&
        ([passthroughContainer.rootViewController isKindOfClass:[SCUMediaContainerViewController class]] ||
         [passthroughContainer.rootViewController isKindOfClass:[self class]]))
    {
        SCUMediaContainerViewController *container = (SCUMediaContainerViewController *)passthroughContainer.rootViewController;

        if ([container isKindOfClass:[SCUMediaContainerViewController class]] && container.nowPlayingViewController)
        {
            hideTabBar = YES;
        }
        else
        {
            hideTabBar = NO;
        }
    }

    if (![navigationController.viewControllers containsObject:self.tabBarParent])
    {
        self.tabBarInitialViewController = nil;
        hideTabBar = YES;
    }

    if (hideTabBar)
    {
        [self setToolbarHidden:YES];

        if (!self.isNowPlaying)
        {
            SCUNavBarToolbar *toolbar = (SCUNavBarToolbar *)self.navController.toolbar;
            [toolbar clearToolbarItems];
        }
    }
    else
    {
        [self setToolbarHidden:NO];
        self.navController.toolbar.items = self.currentTabBarModel.items;
    }

    if (self.isScene)
    {
        viewController.navigationItem.rightBarButtonItem = self.sceneRightBarButtonItem;
        viewController.navigationItem.rightBarButtonItem.enabled = self.headerView ? YES : NO;
    }

    [self updateHeaderView];
}

- (void)navigationController:(UINavigationController *)navigationController willPopToViewController:(UIViewController *)viewController
{
    if (self.ignorePopViewController != viewController)
    {
        if (viewController == self.parentViewController && ![self.service.serviceId containsString:@"SAVANTMEDIAAUDIO_RADIO"])
        {
            ;
        }
        else if (![[navigationController viewControllers] containsObject:self.parentViewController])
        {
            ;
        }
        else
        {
            [self.mediaModel sendBackCommand];
        }
    }

    self.ignorePopViewController = nil;
}

#pragma mark -

- (void)dismissModal
{
    if (self.presentedViewController.sav_dismissalBlock)
    {
        self.presentedViewController.sav_dismissalBlock();
    }

    [self dismissViewControllerAnimated:YES completion:NULL];
    self.modalNavigationController = nil;
}

- (void)setTabBarInitialViewController:(SCUPassthroughViewController *)tabBarInitialViewController
{
    if (tabBarInitialViewController == self.parentViewController)
    {
        self.weakTabBarInitialViewController = tabBarInitialViewController;
        self.strongTabBarInitialViewController = nil;
    }
    else
    {
        self.strongTabBarInitialViewController = tabBarInitialViewController;
        self.weakTabBarInitialViewController = nil;
    }
}

- (SCUPassthroughViewController *)tabBarInitialViewController
{
    return self.weakTabBarInitialViewController ? self.weakTabBarInitialViewController : self.strongTabBarInitialViewController;
}

- (UIViewController *)tabBarParent
{
    if (self.tabBarInitialViewController == self.rootPassthrough)
    {
        return self;
    }
    else
    {
        return self.tabBarInitialViewController;
    }
}

- (void)setToolbarHidden:(BOOL)hidden
{
    [self.navController setToolbarHidden:hidden animated:YES];
}

- (SCUNowPlayingViewController *)createNowPlayingViewController
{
    if (self.isNowPlaying)
    {
        return nil;
    }

    SCUNowPlayingViewController *viewController = nil;

    if ([UIDevice isPhone])
    {
        SCUNowPlayingInlineViewControllerPhone *vc = [[SCUNowPlayingInlineViewControllerPhone alloc] initWithService:self.service serviceGroup:self.serviceGroup];
        __weak UIViewController *presentationController = self.navController.visibleViewController;

        SAVWeakSelf;
        vc.labelTouchedCallback = ^{
            SAVStrongWeakSelf;
            SCUNowPlayingFullScreenViewControllerPhone *fullScreen = [[SCUNowPlayingFullScreenViewControllerPhone alloc] initWithService:sSelf.service serviceGroup:sSelf.serviceGroup];

            SAVWeakVar(fullScreen, wFullScreen);
            fullScreen.sav_dismissalBlock = ^{
                [wFullScreen dismissViewControllerAnimated:YES completion:NULL];
            };

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:fullScreen];
            fullScreen.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"x"]
                                                                                           style:UIBarButtonItemStylePlain
                                                                                          target:fullScreen
                                                                                          action:@selector(sav_dismiss)];
            [presentationController presentViewController:navController animated:YES completion:NULL];
        };
        viewController = vc;
    }
    else
    {
        SCUNowPlayingInlineViewControllerPad *vc = [[SCUNowPlayingInlineViewControllerPad alloc] initWithService:self.service serviceGroup:self.serviceGroup];
        SAVWeakSelf;
        vc.artworkTappedBlock = ^{
            SAVStrongWeakSelf;
            SCUNowPlayingFullScreenViewControllerPad *fullScreen = [[SCUNowPlayingFullScreenViewControllerPad alloc] initWithService:sSelf.service serviceGroup:sSelf.serviceGroup];
            SCUMediaContainerViewController *container = [[SCUMediaContainerViewController alloc] initWithNowPlayingViewController:fullScreen];
            container.delegate = wSelf;
            wSelf.ignorePopViewController = wSelf.navController.topViewController;
            SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:container];
            [wSelf.navController pushViewController:passthrough animated:YES];
        };
        viewController = vc;
    }

    SCUPassthroughViewController *passthrough = (SCUPassthroughViewController *)self.navController.visibleViewController;

    if ([passthrough isKindOfClass:[SCUPassthroughViewController class]])
    {
        viewController.visible = passthrough.isSupplementaryViewVisible;
    }

    return viewController;
}

- (void)dismiss
{
    [[self presentedViewController] dismissViewControllerAnimated:YES completion:NULL];
}

@end
