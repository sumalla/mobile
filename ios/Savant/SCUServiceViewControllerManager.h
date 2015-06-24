//
//  SCUServiceViewControllerManager.h
//  Prototype
//
//  Created by Nathan Trapp on 3/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import Foundation;
@class SAVService, SAVServiceGroup, SCUServiceViewController, SCUSceneServiceViewController, SAVScene;

@interface SCUServiceViewControllerManager : NSObject

+ (SCUServiceViewController *)viewControllerForService:(SAVService *)service;
+ (SCUSceneServiceViewController *)sceneServiceViewControllerForServiceGroup:(SAVServiceGroup *)serviceGroup scene:(SAVScene *)scene;
+ (SCUSceneServiceViewController *)sceneServiceViewControllerForService:(SAVService *)service scene:(SAVScene *)scene;

@end
