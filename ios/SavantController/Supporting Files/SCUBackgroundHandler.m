//
//  SCUBackgroundHandler.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUBackgroundHandler.h"
#import <SavantControl/SavantControl.h>
#import "SCUInterface.h"
#import "SCUMainViewModel.h"

@interface SCUBackgroundHandler ()

@property (nonatomic, getter = isStarted) BOOL started;
@property (nonatomic, getter = isSuspended) BOOL suspended;
@property (nonatomic, getter = isResuming) BOOL resuming;
@property (nonatomic) BOOL handleBecomeActive;
@property (nonatomic) NSHashTable *delegates;

@end

@implementation SCUBackgroundHandler

+ (instancetype)sharedInstance
{
    static SCUBackgroundHandler *sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.delegates = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)addDelegate:(id<SCUBackgroundHandlerDelegate>)delegate
{
    NSParameterAssert([delegate conformsToProtocol:@protocol(SCUBackgroundHandlerDelegate)]);
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<SCUBackgroundHandlerDelegate>)delegate
{
    NSParameterAssert([delegate conformsToProtocol:@protocol(SCUBackgroundHandlerDelegate)]);
    [self.delegates removeObject:delegate];
}

- (void)start
{
    if (!self.isStarted)
    {
        self.started = YES;
    }
}

- (void)suspend
{
    if (!self.isSuspended)
    {
        self.suspended = YES;

        for (id<SCUBackgroundHandlerDelegate> delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(backgroundHandlerEnterBackground)])
            {
                [delegate backgroundHandlerEnterBackground];
            }
        }

        if ([[SavantControl sharedControl] currentSystem])
        {
            [[SavantControl sharedControl] suspend];
        }
    }
}

- (void)resume
{
    if (self.isSuspended)
    {
        self.suspended = NO;
        self.resuming = YES;
        [[SavantControl sharedControl] resume];

        if (![SCUInterface sharedInstance].isInterfaceLoaded)
        {
            self.handleBecomeActive = YES;
        }

        for (id<SCUBackgroundHandlerDelegate> delegate in self.delegates)
        {
            if ([delegate respondsToSelector:@selector(backgroundHandlerEnterForeground)])
            {
                [delegate backgroundHandlerEnterForeground];
            }
        }
    }
}

- (void)willDeactivate
{
    for (id<SCUBackgroundHandlerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(backgroundHandlerWillResignActive)])
        {
            [delegate backgroundHandlerWillResignActive];
        }
    }
}

- (void)becomeActive
{
    if (self.handleBecomeActive)
    {
        self.handleBecomeActive = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:SCUMainViewPresentSystemSelectorNotification object:nil];
    }

    for (id<SCUBackgroundHandlerDelegate> delegate in self.delegates)
    {
        if ([delegate respondsToSelector:@selector(backgroundHandlerDidActivate)])
        {
            [delegate backgroundHandlerDidActivate];
        }
    }
}

@end
