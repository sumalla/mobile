//
//  SCUSceneCreationModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSourcePrivate.h"

@implementation SCUSceneCreationDataSource

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.scene = scene;
        self.service = service;
    }
    return self;
}

- (BOOL)isEnviromentalService
{
    return [self.service.serviceId hasPrefix:@"SVC_ENV"];
}

@end
