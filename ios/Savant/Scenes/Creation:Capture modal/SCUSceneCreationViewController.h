//
//  SCUSceneCreationViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUSceneCreationState)
{
    SCUSceneCreationState_SelectedServicesList,
    SCUSceneCreationState_Service,
    SCUSceneCreationState_ServiceRoom,
    SCUSceneCreationState_AddServicesList,
    SCUSceneCreationState_RoomsList,
    SCUSceneCreationState_ZonesList,
    SCUSceneCreationState_Save,
    SCUSceneCreationState_PowerOff,
    SCUSceneCreationState_Schedule,
    SCUSceneCreationState_Capture,
    SCUSceneCreationState_FadeTime
};

@class SAVScene, SAVService, SAVMutableService, SAVServiceGroup;
@protocol SCUSceneCreationViewControllerDelegate;

@interface SCUSceneCreationViewController : UIViewController <UINavigationControllerDelegate>

- (instancetype)initWithState:(SCUSceneCreationState)state andScene:(SAVScene *)scene;

@property (weak) id <SCUSceneCreationViewControllerDelegate> delegate;

@property (readonly) SAVScene *scene;
@property (readonly) SAVScene *originalScene;
@property (nonatomic) SCUSceneCreationState activeState;
@property (readonly, nonatomic) NSArray *states;
@property (nonatomic, readonly) BOOL sceneIsDirty;

@property SAVMutableService *editingService;
@property SAVServiceGroup *editingServiceGroup;
@property (nonatomic) SAVScene *editingScene;
@property (readonly, getter = isAdd) BOOL add;
@property (getter = isEnvAdd) BOOL envAdd;
@property (nonatomic, readonly, getter = isFirstView) BOOL firstView;
@property (nonatomic, readonly, getter = isLeftView) BOOL leftView;

- (void)viewControllerDidDismiss:(UIViewController *)viewController;
- (void)viewControllerDidCancel:(UIViewController *)viewController;

@end

@protocol SCUSceneCreationViewControllerDelegate <NSObject>

- (void)saveScene:(SAVScene *)scene;
- (void)viewControllerDismissedAnimated:(BOOL)animated;

@end

@interface SCUScenesNavController : UINavigationController

@end
