//
//  SCUSceneServiceViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"
#import "SCUSceneServiceViewModel.h"
#import "SCUSceneCreationViewController.h"

typedef void (^SCUSceneServiceBarButtonItemModifyBlock)(UIBarButtonItem *rightBarButtonItem);

@class
SAVService,
SAVScene,
SAVSceneService;

@interface SCUSceneServiceViewController : SCUModelViewController

@property (nonatomic) SCUSceneServiceViewModel *model;
@property (weak) SCUSceneCreationViewController *creationVC;
@property (nonatomic, copy) SCUSceneServiceBarButtonItemModifyBlock leftBarButtonModifyBlock;
@property (nonatomic, copy) SCUSceneServiceBarButtonItemModifyBlock rightBarButtonModifyBlock;

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService;

- (void)commit;

- (void)rollback;

- (void)popViewControllerCanceled;

@end
