//
//  SCUSceneRoomsListViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 8/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneRoomsListViewController.h"
#import "SCUSceneCreationTableViewControllerPrivate.h"
#import "SCUSceneRoomsListModel.h"

@interface SCUSceneRoomsListViewController () <SCUSceneRoomModelDelegate>

@property SCUSceneRoomsListModel *model;

@end