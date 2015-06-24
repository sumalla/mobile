//
//  SAVStateManager.m
//  SavantControl
//
//  Created by Art Jacobson on 2/6/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVStateManagerPrivate.h"
#import "SAVMessages.h"
#import "SAVData.h"
#import "SAVControl.h"
#import "SAVService.h"
#import "Savant.h"
#import "SAVNowPlayingManagerPrivate.h"
@import Extensions;

NSString *const kSAVActiveServiceState = @"ActiveService";
NSString *const kSAVActiveServicesState = @"ActiveServices";
NSString *const kSAVLastActiveServiceState = @"LastActiveService";
NSString *const kSAVCurrentVolumeState = @"CurrentVolume";
NSString *const kSAVIsMutedState = @"IsMuted";
NSString *const kSAVRelativeVolumeOnlyState = @"RelativeVolumeOnly";
NSString *const kSAVRoomLightsAreOn = @"RoomLightsAreOn";
NSString *const kSAVRoomFansAreOn = @"RoomFansAreOn";
NSString *const kSAVRoomCurrentTemperature = @"RoomCurrentTemperature";

static NSString *const kSAVStateManagerKeyStateObservers = @"kSAVStateManagerKeyStateObservers";
static NSString *const kSAVStateManagerKeyActiveServiceObservers = @"kSAVStateManagerKeyActiveServiceObservers";
static NSString *const kSAVStateManagerKeyVolumeObservers = @"kSAVStateManagerKeyVolumeObservers";
static NSString *const kSAVStateManagerKeyRoomStates = @"kSAVStateManagerKeyRoomStates";

@interface SAVStateManager ()

// Global states
@property (nonatomic) NSMutableSet *registeredGlobalStates;
@property (nonatomic) NSArray *globalStateNames;
@property (nonatomic) NSMutableDictionary *roomStates;
@property (nonatomic) NSMutableDictionary *stateCache;
@property (nonatomic) BOOL activeServicesAreDirty;
@property (nonatomic) NSArray *cachedActiveServices;

// Observers
@property (nonatomic) NSHashTable *activeServiceObservers;
@property (nonatomic) NSHashTable *volumeObservers;
@property (nonatomic) NSMapTable *stateObservers;

@property (nonatomic, getter = isAVEnabled) BOOL avEnabled;
@property (nonatomic, getter = isClimateEnabled) BOOL climateEnabled;
@property (nonatomic, getter = isSecurityEnabled) BOOL securityEnabled;
@property (nonatomic, getter = isLightingEnabled) BOOL lightingEnabled;

@end

@implementation SAVStateManager

+ (NSArray *)globalStateNames
{
    static NSArray *stateNames = nil;

    static dispatch_once_t oncePredicate;

    dispatch_once(&oncePredicate, ^{
        stateNames = @[kSAVActiveServiceState,
                       kSAVActiveServicesState,
                       kSAVLastActiveServiceState,
                       kSAVCurrentVolumeState,
                       kSAVIsMutedState,
                       kSAVRelativeVolumeOnlyState,
                       kSAVRoomLightsAreOn,
                       kSAVRoomFansAreOn,
                       kSAVRoomCurrentTemperature];
    });

    return stateNames;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.registeredGlobalStates = [NSMutableSet set];
        self.globalStateNames = @[];
        self.roomStates = [NSMutableDictionary dictionary];
        self.stateCache = [NSMutableDictionary dictionary];
        self.activeServicesAreDirty = YES;
        self.cachedActiveServices = @[];
        self.activeServiceObservers = [NSHashTable weakObjectsHashTable];
        self.volumeObservers = [NSHashTable weakObjectsHashTable];
        self.stateObservers = [NSMapTable weakToStrongObjectsMapTable];
        self.nowPlaying = [[SAVNowPlayingManager alloc] init];
    }
    return self;
}

- (void)reset
{
    self.registeredGlobalStates = [NSMutableSet set];
    self.globalStateNames = @[];
    self.roomStates = [NSMutableDictionary dictionary];
    self.stateCache = [NSMutableDictionary dictionary];
    self.activeServicesAreDirty = YES;
    self.cachedActiveServices = @[];
    self.activeServiceObservers = [NSHashTable weakObjectsHashTable];
    self.volumeObservers = [NSHashTable weakObjectsHashTable];
    self.stateObservers = [NSMapTable weakToStrongObjectsMapTable];
    self.avEnabled = ![[Savant data].serviceBlacklist containsObject:@"SVC_AV"];
    self.lightingEnabled = !([[Savant data].serviceBlacklist containsObject:@"SVC_ENV_LIGHTING"] || [[Savant data].serviceBlacklist containsObject:@"SVC_ENV_SHADE"]);
    self.climateEnabled = ![[Savant data].serviceBlacklist containsObject:@"SVC_ENV_HVAC"];
    self.securityEnabled = ![[Savant data].serviceBlacklist containsObject:@"SVC_ENV_SECURITY"];
    [self.nowPlaying reset];
}

- (void)updateGlobalStates
{
    NSMutableArray *unregisterMessages = [NSMutableArray arrayWithCapacity:[self.registeredGlobalStates count]];
    for (NSString *state in self.registeredGlobalStates)
    {
        [unregisterMessages addObject:[SAVStateUnregister messageWithState:state]];
    }

    [[Savant control] sendMessages:unregisterMessages];

    self.registeredGlobalStates = [NSMutableSet set];

    NSMutableArray *registerMessages = [NSMutableArray array];
    for (NSString *roomId in [Savant data].allRoomIds)
    {
        for (NSString *currentState in [SAVStateManager globalStateNames])
        {
            NSString *state = [roomId stringByAppendingFormat: @".%@", currentState];
            [self.registeredGlobalStates addObject:state];
            [registerMessages addObject:[SAVStateRegister messageWithState:state]];
        }
    }

    self.globalStateNames = [self.registeredGlobalStates allObjects];

    [[Savant control] sendMessages:registerMessages];
}

#pragma mark - State Registration

- (void)registerForStates:(NSArray *)states forObserver:(id<StateDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(StateDelegate)]);

    NSMutableArray *registeredStates = [self.stateObservers objectForKey:observer];

    if (!registeredStates)
    {
        registeredStates = [NSMutableArray array];
    }

    NSMutableArray *statesToRegister = [NSMutableArray array];
    NSMutableArray *immediateStates = [NSMutableArray array];
    NSMutableArray *immediateDISStates = [NSMutableArray array];
    BOOL respondsToStateUpdate = [observer respondsToSelector:@selector(didReceiveStateUpdate:)];
    BOOL respondsToDISUpdate = [observer respondsToSelector:@selector(didReceiveDISFeedback:)];

    for (NSString *state in [NSSet setWithArray:states])
    {
        if ([state hasPrefix:@"dis"])
        {
            [statesToRegister addObject:[SAVDISFeedbackRegister messageWithState:state]];

            SAVDISFeedback *feedback = [self.stateCache objectForKey:state];

            if (feedback && respondsToDISUpdate)
            {
                [immediateDISStates addObject:feedback];
            }
        }
        else
        {
            if (!self.isAVEnabled && [state containsString:@"ActiveService"])
            {
                continue;
            }

            if (!self.isClimateEnabled && [state containsString:@"CurrentTemperature"])
            {
                continue;
            }

            if (!self.isSecurityEnabled && [state containsString:@"SecurityStatus"])
            {
                continue;
            }

            if (!self.isLightingEnabled && [state containsString:@"LightsAreOn"])
            {
                continue;
            }

            if (![self.registeredGlobalStates containsObject:state])
            {
                [statesToRegister addObject:[SAVStateRegister messageWithState:state]];
            }

            SAVStateUpdate *cachedStateUpdate = [self.stateCache objectForKey:state];

            if (cachedStateUpdate && respondsToStateUpdate)
            {
                [immediateStates addObject:state];
            }
        }

        [registeredStates addObject:state];
    }

    dispatch_async_main(^{
        for (NSString *state in immediateStates)
        {
            SAVStateUpdate *update = self.stateCache[state];

            if (update)
            {
                [observer didReceiveStateUpdate:update];
            }
        }

        for (id feedback in immediateDISStates)
        {
            [observer didReceiveDISFeedback:feedback];
        }
    });

    [self.stateObservers setObject:registeredStates forKey:observer];

    if ([statesToRegister count])
    {
        [[Savant control] sendMessages:statesToRegister];
    }
}

- (void)unregisterForStates:(NSArray *)states forObserver:(id<StateDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(StateDelegate)]);

    NSMutableArray *registeredStates = [self.stateObservers objectForKey:observer];
    NSMutableArray *statesToUnregister = [NSMutableArray array];

    for (NSString *state in [NSSet setWithArray:states])
    {
        if ([state hasPrefix:@"dis"])
        {
            [statesToUnregister addObject:[SAVDISFeedbackUnregister messageWithState:state]];
        }
        else
        {
            if (![self.registeredGlobalStates containsObject:state])
            {
                [statesToUnregister addObject:[SAVStateUnregister messageWithState:state]];
            }
        }

        [registeredStates removeObject:state];
    }

    [[Savant control] sendMessages:statesToUnregister];

    if ([registeredStates count])
    {
        [self.stateObservers setObject:registeredStates forKey:observer];
    }
    else
    {
        [self.stateObservers removeObjectForKey:observer];
    }
}

#pragma mark - Active Service Accessors

- (SAVService *)activeServiceForRoom:(NSString *)roomId
{
    if ([self isAVEnabled])
    {
        return self.roomStates[roomId][kSAVActiveServiceState];
    }
    else
    {
        return nil;
    }
}

- (SAVService *)lastActiveServiceForRoom:(NSString *)roomId
{
    if ([self isAVEnabled])
    {
        return self.roomStates[roomId][kSAVLastActiveServiceState];
    }
    else
    {
        return nil;
    }
}

- (NSArray *)activeServiceListForRoom:(NSString *)roomId
{
    if ([self isAVEnabled])
    {
        return [self.roomStates[roomId][kSAVActiveServicesState] copy];
    }
    else
    {
        return @[];
    }
}

- (NSArray *)activeServices
{
    if ([self isAVEnabled])
    {
        if (self.activeServicesAreDirty)
        {
            self.activeServicesAreDirty = NO;

            NSMutableArray *activeServices = [NSMutableArray array];

            for (NSString *roomId in self.roomStates)
            {
                if (self.roomStates[roomId][kSAVActiveServicesState])
                {
                    for (SAVService *service in self.roomStates[roomId][kSAVActiveServicesState])
                    {
                        [activeServices addObject:service];
                    }
                }
            }

            self.cachedActiveServices = [activeServices count] ? [activeServices copy] : nil;
        }
    }

    return self.cachedActiveServices;
}

#pragma mark - Volume Accessors

- (NSNumber *)volumeForRoom:(NSString *)roomId
{
    NSNumber *volume = self.roomStates[roomId][kSAVCurrentVolumeState];
    
    if (!volume)
    {
        volume = @0;
    }
    
    return volume;
}

- (BOOL)muteStatusForRoom:(NSString *)roomId
{
    return [(NSNumber *)self.roomStates[roomId][kSAVIsMutedState] boolValue];
}

- (BOOL)discreteVolumeStatusForRoom:(NSString *)roomId
{
    return ![(NSNumber *)self.roomStates[roomId][kSAVRelativeVolumeOnlyState] boolValue];
}

#pragma mark - StateDelegate

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    [self.stateCache setObject:stateUpdate forKey:stateUpdate.state];

    NSDictionary *obs = [self.stateObservers copy];
    for (id<StateDelegate> curObserver in obs)
    {
        NSArray *registeredStates = [obs objectForKey:curObserver];

        if ([registeredStates containsObject:stateUpdate.state])
        {
            if ([curObserver respondsToSelector:@selector(didReceiveStateUpdate:)])
            {
                [curObserver didReceiveStateUpdate:stateUpdate];
            }
        }
    }

    if ([self.globalStateNames containsObject:stateUpdate.state])
    {
        if (![self handleServiceUpdate:stateUpdate])
        {
            [self handleVolumeUpdate:stateUpdate forObservers:[self.volumeObservers copy]];
        }
    }
}

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    [self.stateCache setObject:feedback forKey:feedback.scope];

    NSDictionary *obs = [self.stateObservers copy];

    for (id<StateDelegate> curObserver in obs)
    {
        NSArray *registeredStates = [obs objectForKey:curObserver];

        if ([registeredStates containsObject:feedback.scope])
        {
            if ([curObserver respondsToSelector:@selector(didReceiveDISFeedback:)])
            {
                [curObserver didReceiveDISFeedback:feedback];
            }
        }
    }
}

#pragma mark - Service Observer

- (void)addActiveServiceObserver:(id<ActiveServiceObserver>)observer
{
    if ([self isAVEnabled])
    {
        NSParameterAssert([observer conformsToProtocol:@protocol(ActiveServiceObserver)]);
        [self.activeServiceObservers addObject:observer];
    }
}

- (void)removeActiveServiceObserver:(id<ActiveServiceObserver>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(ActiveServiceObserver)]);
    [self.activeServiceObservers removeObject:observer];
}

- (BOOL)handleServiceUpdate:(SAVStateUpdate *)stateUpdate
{
    BOOL didUpdate = NO;
    NSString *stateName = stateUpdate.state;

    if ([stateName hasSuffix:kSAVLastActiveServiceState])
    {
        didUpdate = YES;
        self.activeServicesAreDirty = YES;
        NSString *roomId = stateUpdate.scope;
        if (roomId)
        {
            NSString *stateValue = [stateUpdate.value description];

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            if ([stateValue length])
            {
                SAVService *service = [[SAVService alloc] initWithString:stateValue queryService:NO];

                if (service)
                {
                    self.roomStates[roomId][kSAVLastActiveServiceState] = service;
                }
                else
                {
                    [self.roomStates[roomId] removeObjectForKey:kSAVLastActiveServiceState];
                }
            }
            else
            {
                [self.roomStates[roomId] removeObjectForKey:kSAVLastActiveServiceState];
            }
        }
    }
    else if ([stateName hasSuffix:kSAVActiveServiceState])
    {
        didUpdate = YES;
        self.activeServicesAreDirty = YES;
        NSString *roomId = stateUpdate.scope;
        if (roomId)
        {
            NSString *stateValue = [stateUpdate.value description];

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            if ([stateValue length])
            {
                SAVService *service = [[SAVService alloc] initWithString:stateValue queryService:NO];

                if (service)
                {
                    self.roomStates[roomId][kSAVActiveServiceState] = service;
                }
                else
                {
                    [self.roomStates[roomId] removeObjectForKey:kSAVActiveServiceState];
                }
            }
            else
            {
                [self.roomStates[roomId] removeObjectForKey:kSAVActiveServiceState];
            }

            dispatch_async_main(^{
                for (id<ActiveServiceObserver> observer in [self.activeServiceObservers copy])
                {
                    if ([observer respondsToSelector:@selector(room:didUpdateActiveService:)])
                    {
                        [observer room:roomId didUpdateActiveService:self.roomStates[roomId][kSAVActiveServiceState]];
                    }
                }
            });
        }
    }
    else if ([stateName hasSuffix:kSAVActiveServicesState])
    {
        didUpdate = YES;
        self.activeServicesAreDirty = YES;
        NSString *roomId = stateUpdate.scope;
        if (roomId)
        {
            NSString *stateValue = [stateUpdate.value description];
            NSArray *serviceStrings = [stateValue componentsSeparatedByString:@","];
            NSMutableArray *services = [NSMutableArray array];

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            if ([stateValue length])
            {
                for (NSString *currService in serviceStrings)
                {
                    SAVService *service = [[SAVService alloc] initWithString:currService queryService:NO];

                    if (service)
                    {
                        [services addObject:service];
                    }
                }

                self.roomStates[roomId][kSAVActiveServicesState] = services;
            }
            else
            {
                [self.roomStates[roomId] removeObjectForKey:kSAVActiveServicesState];
            }

            dispatch_async_main(^{
                for (id<ActiveServiceObserver> observer in [self.activeServiceObservers copy])
                {
                    if ([observer respondsToSelector:@selector(room:didUpdateActiveServiceList:)])
                    {
                        [observer room:roomId didUpdateActiveServiceList:services];
                    }
                }
            });
        }
    }

    return didUpdate;
}

#pragma mark - Volume Observer

- (void)addVolumeObserver:(id<VolumeObserver>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(VolumeObserver)]);
    [self.volumeObservers addObject:observer];

    for (NSString *state in self.globalStateNames)
    {
        if ([state hasSuffix:kSAVCurrentVolumeState] || [state hasSuffix:kSAVIsMutedState] || [state hasSuffix:kSAVRelativeVolumeOnlyState])
        {
            SAVStateUpdate *stateUpdate = [self.stateCache objectForKey:state];

            if (stateUpdate)
            {
                [self handleVolumeUpdate:stateUpdate forObservers:@[observer]];
            }
        }
    }
}

- (void)removeVolumeObserver:(id<VolumeObserver>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(VolumeObserver)]);
    [self.volumeObservers removeObject:observer];
}

- (void)handleVolumeUpdate:(SAVStateUpdate *)stateUpdate forObservers:(id<NSFastEnumeration>)observers
{
    NSString *stateName = stateUpdate.state;

    if ([stateName hasSuffix:kSAVCurrentVolumeState])
    {
        NSString *roomId = stateUpdate.scope;

        if (roomId)
        {
            NSNumber *volumeState = (NSNumber *)stateUpdate.value;

            if ([stateUpdate.value isKindOfClass:[NSString class]])
            {
                volumeState = [NSNumber numberWithFloat:[stateUpdate.value intValue]];
            }

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            self.roomStates[roomId][kSAVCurrentVolumeState] = volumeState;

            for (id<VolumeObserver> observer in observers)
            {
                if ([observer respondsToSelector:@selector(room:didUpdateVolume:)])
                {
                    [observer room:roomId didUpdateVolume:volumeState];
                }
            }
        }
    }
    else if ([stateName hasSuffix:kSAVIsMutedState])
    {
        NSString *roomId = stateUpdate.scope;

        if (roomId)
        {
            BOOL isMuted = [stateUpdate.value boolValue];

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            self.roomStates[roomId][kSAVIsMutedState] = [NSNumber numberWithBool:isMuted];

            for (id<VolumeObserver> observer in observers)
            {
                if ([observer respondsToSelector:@selector(room:didUpdateMuteStatus:)])
                {
                    [observer room:roomId didUpdateMuteStatus:isMuted];
                }
            }
        }
    }
    else if ([stateName hasSuffix:kSAVRelativeVolumeOnlyState])
    {
        NSString *roomId = stateUpdate.scope;

        if (roomId)
        {
            BOOL discreteVolumeAvailable = ![stateUpdate.value boolValue];

            if (!self.roomStates[roomId])
            {
                self.roomStates[roomId] = [NSMutableDictionary dictionary];
            }

            self.roomStates[roomId][kSAVRelativeVolumeOnlyState] = [NSNumber numberWithBool:!discreteVolumeAvailable];

            for (id<VolumeObserver> observer in observers)
            {
                if ([observer respondsToSelector:@selector(room:didUpdateDiscreteVolumeStatus:)])
                {
                    [observer room:roomId didUpdateDiscreteVolumeStatus:discreteVolumeAvailable];
                }
            }
        }
    }
}

#pragma mark - State restoration

- (id)restorationInfo
{
    return @{kSAVStateManagerKeyStateObservers: [self.stateObservers copy],
             kSAVStateManagerKeyActiveServiceObservers: [self.activeServiceObservers copy],
             kSAVStateManagerKeyVolumeObservers: [self.volumeObservers copy],
             kSAVStateManagerKeyRoomStates: [self.roomStates mutableCopy]};
}

- (void)restoreState:(id)state
{
    NSParameterAssert([state isKindOfClass:[NSDictionary class]]);
    NSDictionary *stateDict = (NSDictionary *)state;
    NSMapTable *stateObservers = stateDict[kSAVStateManagerKeyStateObservers];
    NSHashTable *activeServiceObservers = stateDict[kSAVStateManagerKeyActiveServiceObservers];
    NSHashTable *volumeObservers = stateDict[kSAVStateManagerKeyVolumeObservers];
    self.roomStates = stateDict[kSAVStateManagerKeyRoomStates];

    for (id<StateDelegate> stateObserver in stateObservers)
    {
        NSArray *states = [stateObservers objectForKey:stateObserver];
        [self registerForStates:states forObserver:stateObserver];
    }
    
    for (id<ActiveServiceObserver> observer in activeServiceObservers)
    {
        [self addActiveServiceObserver:observer];
    }
    
    for (id<VolumeObserver> observer in volumeObservers)
    {
        [self addVolumeObserver:observer];
    }
}

@end
