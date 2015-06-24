//
//  SCUMediaContainerViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaContainerViewController.h"
#import "SCUMediaTableViewController.h"
#import "SCUMediaCollectionViewController.h"
#import "SCUGradientView.h"
#import "SCUToolbarButton.h"
@import Extensions;

@interface SCUMediaContainerViewController ()

@property (nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, weak) NSTimer *loadingDelayTimer;
@property (nonatomic, getter = isLoaded) BOOL loaded;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic) SCUNowPlayingViewController *nowPlayingViewController;

@end

@implementation SCUMediaContainerViewController

- (instancetype)initWithNowPlayingViewController:(SCUNowPlayingViewController *)nowPlayingViewController
{
    self = [super init];

    if (self)
    {
        self.nowPlayingViewController = nowPlayingViewController;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.nowPlayingViewController)
    {
        [self sav_addChildViewController:self.nowPlayingViewController];
        [self.view sav_addFlushConstraintsForView:self.nowPlayingViewController.view];
        self.title = NSLocalizedString(@"Now Playing", nil);
    }
    else
    {
        self.view.backgroundColor = [[SCUColors shared] color03shade01];
        self.parentViewController.edgesForExtendedLayout = UIRectEdgeNone;

        if (!self.isLoaded)
        {
            self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.loadingIndicator.hidesWhenStopped = YES;

            self.loadingDelayTimer = [NSTimer sav_scheduledBlockWithDelay:.5 block:^{
                [self.view addSubview:self.loadingIndicator];
                [self.view sav_addCenteredConstraintsForView:self.loadingIndicator];
                [self.loadingIndicator startAnimating];
            }];
        }
    }
}

- (void)loadModel:(SCUMediaDataModel *)model withStyle:(SCUMediaContainerPresentationStyle)presentationStyle
{
    self.loaded = YES;
    [self.loadingDelayTimer invalidate];
    [self.loadingIndicator stopAnimating];

    UIViewController *viewController = nil;

    if (presentationStyle == SCUMediaContainerPresentationStyleTableView)
    {
        viewController = [[SCUMediaTableViewController alloc] initWithModel:model];
    }
    else if (presentationStyle == SCUMediaContainerPresentationStyleCollectionView)
    {
        viewController = [[SCUMediaCollectionViewController alloc] initWithModel:model];
    }

    [self sav_addChildViewController:viewController];
    [viewController viewWillAppear:NO];
    [self.view sav_addFlushConstraintsForView:viewController.view];

    self.viewController = viewController;
}

#pragma mark - SCUServiceViewProtocol

- (SAVService *)service
{
    return [self.delegate service];
}

- (SAVServiceGroup *)serviceGroup
{
    return [self.delegate serviceGroup];
}

@end
