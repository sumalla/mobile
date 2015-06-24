//
//  SCUSceneServiceViewModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

@class
SAVScene,
SAVSceneService;

@interface SCUSceneServiceViewModel : SCUServiceViewModel

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService;

@property (readonly) SAVScene *scene;

@property (readonly) SAVSceneService *sceneService;

@end
