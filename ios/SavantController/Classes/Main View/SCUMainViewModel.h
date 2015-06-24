//
//  SCUMainViewModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"

@class SCUSignInViewModel;
@class SCUUser;

#pragma mark - System selector

extern NSString *const SCUMainViewPresentSystemSelectorNotification;

#pragma mark - Sign in

extern NSString *const SCUMainViewPresentUserSignInNotification;
extern NSString *const SCUMainViewSignInUserKey;
extern NSString *const SCUMainViewSignInForceModalKey;

@protocol SCUMainViewModelDelegate;

@interface SCUMainViewModel : SCUViewModel

@property (nonatomic, weak) id<SCUMainViewModelDelegate> delegate;

- (void)resetConnection;

- (BOOL)loadPreviousConnection;

- (void)authorizeLocalUser:(void (^)(BOOL success, NSError *error))handler;

- (void)startObservingConnectionStatus;

- (void)cleanupFailedLogin;

@end

@protocol SCUMainViewModelDelegate <NSObject>

- (void)setReconnectLoadingIndicatorVisible:(BOOL)visible;

- (void)presentSystemSelector:(NSUInteger)fromLocation;

- (void)resetSystemSelector;

- (BOOL)isSystemSelectorPresented;

- (void)presentUserListWithTitle:(NSString *)title;

- (void)presentSignInWithModel:(SCUSignInViewModel *)model forceModal:(BOOL)forceModal;

- (void)presentInterface;

- (void)presentSplashScreen;

@end
