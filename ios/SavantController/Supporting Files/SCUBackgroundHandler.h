//
//  SCUBackgroundHandler.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

@protocol SCUBackgroundHandlerDelegate;

@interface SCUBackgroundHandler : NSObject

+ (instancetype)sharedInstance;

- (void)addDelegate:(id<SCUBackgroundHandlerDelegate>)delegate;

- (void)removeDelegate:(id<SCUBackgroundHandlerDelegate>)delegate;

- (void)start;

- (void)suspend;

- (void)resume;

- (void)willDeactivate;

- (void)becomeActive;

@end

@protocol SCUBackgroundHandlerDelegate <NSObject>

@optional

- (void)backgroundHandlerEnterBackground;

- (void)backgroundHandlerEnterForeground;

- (void)backgroundHandlerWillResignActive;

- (void)backgroundHandlerDidActivate;

@end
