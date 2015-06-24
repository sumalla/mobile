//
//  SCUSceneLightingViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingServiceViewController.h"
#import "SCUSceneLightingTableViewController.h"

@interface SCUSceneLightingServiceViewController ()

@property (nonatomic) SCUSceneLightingTableModel *lightingModel;

@end

@implementation SCUSceneLightingServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.lightingModel = [[SCUSceneLightingTableModel alloc] initWithScene:self.model.scene
                                                                   service:self.model.service
                                                              sceneService:self.model.sceneService];

    SCUSceneLightingTableViewController *lightingVC = [[SCUSceneLightingTableViewController alloc] initWithModel:self.lightingModel];
    [self sav_addChildViewController:lightingVC];
    [self.view addSubview:lightingVC.view];
    [self.view sav_addFlushConstraintsForView:lightingVC.view];
}

- (void)commit
{
    [self.lightingModel commit];
}

- (void)rollback
{
    [self.lightingModel rollback];
}

@end
