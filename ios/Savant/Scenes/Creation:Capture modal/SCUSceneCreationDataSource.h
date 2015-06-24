//
//  SCUSceneCreationModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

@class SAVService, SAVScene;

@interface SCUSceneCreationDataSource : SCUExpandableDataSourceModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service;

@property (readonly) SAVService *service;
@property SAVScene *scene;

@property (readonly) NSArray *dataSource;

@end

@interface SCUSceneCreationDataSource (Optional)

- (void)doneEditing;

@end
