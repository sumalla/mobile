//
//  SCUSceneZonesListViewControllerPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneZonesListViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneZonesListModel.h"

@interface SCUSceneZonesListViewController () <SCUSceneZoneModelDelegate>

@property SCUSceneZonesListModel *model;

@end