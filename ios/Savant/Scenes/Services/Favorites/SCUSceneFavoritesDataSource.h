//
//  SCUSceneFavoritesDataSource.h
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@class SAVSceneService, SAVScene, SAVService;

@protocol SCUSceneFavoritesDelegate;

@interface SCUSceneFavoritesDataSource : SCUDataSourceModel

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService delegate:(id <SCUSceneFavoritesDelegate>)delegate;

@end

@protocol SCUSceneFavoritesDelegate <NSObject>

- (void)reloadData;

@end
