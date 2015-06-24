//
//  SCUSceneClimateServiceViewController.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneClimateServiceViewController.h"
#import "SCUSceneClimateTableViewController.h"

@interface SCUSceneClimateServiceViewController ()

@property (nonatomic) SCUSceneClimateTableModel *climateModel;

@end

@implementation SCUSceneClimateServiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.climateModel = [[SCUSceneClimateTableModel alloc] initWithScene:self.model.scene
                                                                   service:self.model.service
                                                              sceneService:self.model.sceneService];

    SCUSceneClimateTableViewController *climateVC = [[SCUSceneClimateTableViewController alloc] initWithModel:self.climateModel];
    [self sav_addChildViewController:climateVC];
    [self.view addSubview:climateVC.view];
    [self.view sav_addFlushConstraintsForView:climateVC.view];
}

- (void)commit
{
    [self.climateModel commit];
}

- (void)rollback
{
    [self.climateModel rollback];
}

@end

