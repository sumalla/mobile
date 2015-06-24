//
//  SCUSatelliteRadioServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioServiceViewController.h"
#import "SCUSatelliteRadioNavigationViewController.h"
#import "SCUFavoritesCollectionViewController.h"
#import "SCUSatelliteRadioFavoritesModel.h"

@implementation SCUSatelliteRadioServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    SCUSatelliteRadioFavoritesModel *favoritesModel = [[SCUSatelliteRadioFavoritesModel alloc] initWithService:self.service];
    SCUFavoritesCollectionViewController *favoritesVC = [[DeviceClassFromClass([SCUFavoritesCollectionViewController class]) alloc] initWithModel:favoritesModel];

    SCUServiceViewController *navigationVC = [[DeviceClassFromClass([SCUSatelliteRadioNavigationViewController class]) alloc] initWithService:self.service];

    self.viewControllers = @[favoritesVC, navigationVC];

    self.activeVC = navigationVC;
}

@end
