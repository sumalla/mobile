//
//  SCURadioServiceViewController.m
//  SavantController
//
//  Created by David Fairweather on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioServiceViewController.h"
#import "SCURadioNavigationViewController.h"
#import "SCUFavoritesCollectionViewController.h"
#import "SCURadioFavoritesModel.h"

@interface SCURadioServiceViewController ()

@end

@implementation SCURadioServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCURadioNavigationViewController class]) alloc] initWithService:self.service];

    self.defaultVC = navigationVC;
    
    if ([((SCURadioNavigationViewController *)navigationVC) showfavorites])
    {
        SCURadioFavoritesModel *favoritesModel = [[SCURadioFavoritesModel alloc] initWithService:self.service];
        SCUFavoritesCollectionViewController *favoritesVC = [[DeviceClassFromClass([SCUFavoritesCollectionViewController class]) alloc] initWithModel:favoritesModel];

        self.viewControllers = @[favoritesVC, navigationVC];
    }
    else
    {
        self.viewControllers = @[navigationVC];
    }
}

@end
