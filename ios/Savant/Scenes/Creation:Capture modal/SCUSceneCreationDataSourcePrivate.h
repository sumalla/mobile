//
//  SCUSceneCreationDataSourcePrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"
#import "SCUDefaultTableViewCell.h"
@import SDK;

@interface SCUSceneCreationDataSource ()

@property SAVService *service;

@property NSArray *dataSource;

@property (nonatomic, getter = isEnviromentalService, readonly) BOOL enviromentalService;

@end
