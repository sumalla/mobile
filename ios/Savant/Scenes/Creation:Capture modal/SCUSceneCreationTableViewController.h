//
//  SCUSceneCreationTableViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelExpandableTableViewController.h"
#import "SCUPassthroughViewController.h"

typedef NS_ENUM(NSInteger, SCUSceneTransitionType)
{
    SCUSceneTransitionTypeDefault,
    SCUSceneTransitionTypeBottom,
    SCUSceneTransitionTypeTop
};

@class SCUSceneCreationDataSource, SAVScene, SAVService, SCUSceneCreationViewController;

@interface SCUSceneCreationTableViewController : SCUModelExpandableTableViewController

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service;

@property (readonly) SCUSceneCreationDataSource *model;
@property (weak) SCUSceneCreationViewController *creationVC;
@property (readonly, nonatomic, getter=passthroughVC) SCUPassthroughViewController *passthroughVC;

@end
