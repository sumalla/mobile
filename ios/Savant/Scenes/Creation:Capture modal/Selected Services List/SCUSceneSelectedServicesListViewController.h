//
//  SCUSceneServicesListViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationTableViewController.h"

@interface SCUSceneSelectedServicesListViewController : SCUSceneCreationTableViewController

- (void)reloadData;

@property (nonatomic) SAVScene *scene;

@end
