//
//  SCUSceneAddServiceModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"

@protocol SCUSceneAddServiceDelegate;
@class SAVServiceGroup;

@interface SCUSceneAddServiceModel : SCUSceneCreationDataSource

@property (weak) id <SCUSceneAddServiceDelegate> delegate;

@end

@protocol SCUSceneAddServiceDelegate <NSObject>

- (void)selectedServiceGroup:(SAVServiceGroup *)service;

@end
