//
//  SCUTabBarController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"

@class SCUToolbar;

extern NSString *const SCUSavedTabsPrefix;

@interface SCUTabBarController : SCUModelViewController

@property (nonatomic) NSArray *viewControllers;
@property (nonatomic, weak) UIViewController *activeVC;
@property (nonatomic, weak) UIViewController *defaultVC;
@property (readonly) SCUToolbar *toolbar;

@property (nonatomic) NSInteger toolbarHeight;

/**
 *  If specified, the selected tab will be saved under this key and automatically restored.
 *
 *  @return The key to save the tab state under.
 */
@property (nonatomic, readonly, copy) NSString *savedKey;

@end

@protocol SCUTabBarControllerContentView <NSObject>

@optional
- (NSString *)tabBarTitle;
- (UIImage *)tabBarIcon;
- (UIColor *)tabBarButtonColor;

@end
