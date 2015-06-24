//
//  SCUTVServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTVServiceViewController.h"
#import "SCUAVNavigationViewController.h"
#import "SCUAVNumberPadViewController.h"
#import "SCUPassthroughViewController.h"
#import "SCUAVNowPlayingViewController.h"
#import "SCUFavoritesCollectionViewController.h"
#import "SCUTVFavoritesCollectionViewModel.h"
#import "SCUOverflowDummyViewController.h"
#import "SCUOverflowTableViewController.h"

@implementation SCUTVServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUTVFavoritesCollectionViewModel *favoritesModel = [[SCUTVFavoritesCollectionViewModel alloc] initWithService:self.service];
    SCUFavoritesCollectionViewController *favoritesVC = [[DeviceClassFromClass([SCUFavoritesCollectionViewController class]) alloc] initWithModel:favoritesModel];
    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCUAVNavigationViewController class]) alloc] initWithService:self.service];
    SCUOverflowTableViewController *tableViewController = [[SCUOverflowTableViewController alloc] initWithService:self.service];
    SCUOverflowDummyViewController *overlayVC = [[SCUOverflowDummyViewController alloc] initWithService:self.service
                                                                                 andTableViewController:tableViewController];

    self.defaultVC = navigationVC;

    overlayVC.preferredIndex = 1;
    overlayVC.tabController = self;
    
    if ([UIDevice isPad])
    {
        self.viewControllers = @[favoritesVC, navigationVC, overlayVC];
    }
    else
    {
        SCUServiceViewController *numberPadVC = [[DeviceClassFromClass([SCUAVNumberPadViewController class]) alloc] initWithService:self.service];
        self.viewControllers = @[favoritesVC, navigationVC, numberPadVC, overlayVC];
    }
}

@end
