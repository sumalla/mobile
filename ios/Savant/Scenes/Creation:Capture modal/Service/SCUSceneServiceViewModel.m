//
//  SCUSceneServiceViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneServiceViewModel.h"
@import SDK;

@interface SCUSceneServiceViewModel ()

@property SAVScene *scene;

@property SAVSceneService *sceneService;

@end

@implementation SCUSceneServiceViewModel

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService
{
    self = [super initWithService:service];
    if (self)
    {
        self.scene = scene;
        self.sceneService = sceneService;
    }
    return self;
}

@end
