//
//  SCUNotificationCreationViewController.h
//  SavantController
//
//  Created by Stephen Silber on 1/20/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUNotificationCreationState)
{
    SCUNotificationCreationState_NotificationsList,
    SCUNotificationCreationState_SelectServiceList,
    SCUNotificationCreationState_AddRule,
    SCUNotificationCreationState_EditRule,
    SCUNotificationCreationState_SetRooms,
    SCUNotificationCreationState_SetZones,
    SCUNotificationCreationState_SetTime,
    SCUNotificationCreationState_SetSend,
    SCUNotificationCreationState_SetWhen,
    SCUNotificationCreationState_Save
};

@class SAVNotification, SAVService;
@protocol SCUNotificationCreationViewControllerDelegate;

@interface SCUNotificationCreationViewController : UIViewController <UINavigationControllerDelegate>

- (instancetype)initWithState:(SCUNotificationCreationState)state andNotification:(SAVNotification *)notification;

@property (weak) id <SCUNotificationCreationViewControllerDelegate> delegate;

@property (nonatomic, readonly) SAVNotification *notification;
@property (nonatomic, readonly) SAVNotification *originalNotification;
@property (nonatomic) SAVNotification *editingNotification;
@property (nonatomic) SCUNotificationCreationState activeState;
@property (nonatomic, readonly) NSArray *states;
@property (nonatomic, readonly) BOOL isNotificationDirty;
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic) SAVService *service;

@property (nonatomic, readonly, getter = isFirstView) BOOL firstView;
@property (nonatomic, readonly, getter = isLeftView) BOOL leftView;

- (void)viewControllerDidDismiss:(UIViewController *)viewController;
- (void)viewControllerDidCancel:(UIViewController *)viewController;
- (void)wipeNotification;

@end

@protocol SCUNotificationCreationViewControllerDelegate <NSObject>

- (void)saveNotification:(SAVNotification *)notification;
- (void)viewControllerDismissedAnimated:(BOOL)animated;

@end

@interface SCUNotificationNavController : UINavigationController

@end
