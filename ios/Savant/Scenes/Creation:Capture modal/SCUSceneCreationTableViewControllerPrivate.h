//
//  SCUSceneCreationTableViewControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationTableViewController.h"
#import "SCUSceneCreationViewController.h"
#import "SCUSceneCreationDataSource.h"

@import SDK;

@interface SCUSceneCreationTableViewController ()

@property SCUSceneCreationDataSource *model;

- (void)dismissViewController;
- (void)popViewController;
- (void)popViewControllerCanceled;
- (void)popToRootViewController;
@property (nonatomic, getter = isEnviromentalService, readonly) BOOL enviromentalService;

@end