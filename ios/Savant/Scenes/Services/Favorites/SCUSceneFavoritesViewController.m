//
//  SCUSceneFavoritesViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneFavoritesViewController.h"
#import "SCUSceneFavoritesDataSource.h"
#import "SCUSceneFavoritesTableViewController.h"
@import SDK;

@interface SCUSceneFavoritesViewController () <SCUSceneFavoritesDelegate>

@property SCUSceneFavoritesDataSource *favoritesModel;
@property (weak) SCUSceneFavoritesTableViewController *favoritesVC;

@end

@implementation SCUSceneFavoritesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.favoritesModel = [[SCUSceneFavoritesDataSource alloc] initWithScene:self.model.scene
                                                                     service:self.model.service
                                                                sceneService:self.model.sceneService
                                                                    delegate:self];

    SCUSceneFavoritesTableViewController *favoritesVC = [[SCUSceneFavoritesTableViewController alloc] initWithModel:self.favoritesModel];
    [self sav_addChildViewController:favoritesVC];
    [self.view addSubview:favoritesVC.view];
    [self.view sav_addFlushConstraintsForView:favoritesVC.view];

    self.favoritesVC = favoritesVC;
}

- (void)reloadData
{
    [self.favoritesVC.tableView reloadData];
}

- (void)commit
{
    [self.model.sceneService commit];
}

- (void)rollback
{
    [self.model.sceneService rollback];
}

@end
