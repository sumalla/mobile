//
//  SCUMediaRequestViewControllerModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"

@class
SAVService,
SCUMediaDataModel,
SCUMediaTabBarModel,
SAVSceneService,
SAVServiceGroup,
SAVScene;

typedef NS_ENUM(NSUInteger, SCUMediaPresentationStyle)
{
    SCUMediaPresentationStyleTable,
    SCUMediaPresentationStyleGrid,
    SCUMediaPresentationStyleTabBar,
    SCUMediaPresentationStyleSubmenu
};

@protocol SCUMediaRequestViewControllerModelDelegate;
@protocol SCUMediaRequestViewControllerSceneDelegate;

@interface SCUMediaRequestViewControllerModel : SCUViewModel

@property (nonatomic, weak) id<SCUMediaRequestViewControllerModelDelegate> delegate;
@property (nonatomic, weak) id<SCUMediaRequestViewControllerSceneDelegate> sceneDelegate;
@property (nonatomic, getter = isNowPlaying) BOOL nowPlaying;

- (instancetype)initWithService:(SAVService *)service;

- (void)sendRequestWithQuery:(NSDictionary *)query;

- (void)sendTabBarRequestWithQuery:(NSDictionary *)query;

- (void)sendSubmenuRequestWithQuery:(NSDictionary *)query indexPath:(NSIndexPath *)indexPath;

- (void)sendBackCommand;

- (void)nextButtonPressed;

- (void)sendQueueDeleteRequestWithQuery:(NSDictionary *)query;

@end

@protocol SCUMediaRequestViewControllerSceneDelegate <NSObject>

- (void)reachedLeaf;

- (void)next;

- (SAVServiceGroup *)serviceGroup;
- (SAVScene *)sceneObject;

@end

@protocol SCUMediaRequestViewControllerModelDelegate <NSObject>

- (void)presentTabBarWithModel:(SCUMediaTabBarModel *)model;

- (void)presentViewControllerWithPresentationStyle:(SCUMediaPresentationStyle)style model:(SCUMediaDataModel *)model title:(NSString *)title;

- (void)presentTabBarLoadingIndicatorWithTitle:(NSString *)title;

- (void)reachedLeaf;

- (void)popNavigationController;

- (void)resetNavigationDelegate;

- (void)navigateToRoot;

@end
