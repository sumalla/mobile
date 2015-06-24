//
//  SCUSceneMediaServiceViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 8/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaServiceViewController.h"

@class SCUSceneCreationViewController, SAVScene, SAVSceneService;

@interface SCUSceneMediaServiceViewController : SCUMediaServiceViewController

@property (weak) SCUSceneCreationViewController *creationVC;

- (instancetype)initWithScene:(SAVScene *)scene service:(SAVService *)service sceneService:(SAVSceneService *)sceneService;

@end
