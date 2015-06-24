//
//  SCUVolumeModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVolumeModel.h"
#import "SCUSlingshot.h"
@import SDK;

@interface SCUVolumeModel () <VolumeObserver, ActiveServiceObserver, StateDelegate>

@property BOOL muted;
@property SAVKVORegistration *volumeTracking;
@property SAVCoalescedTimer *volumeUpdateTimer;
@property BOOL disableVolumeUpdate;
@property NSString *muteState;
@property (nonatomic, getter = isRegistered) BOOL registered;
@property (nonatomic, getter = isDiscrete) BOOL discrete;

@end

@implementation SCUVolumeModel

@synthesize serviceGroup = _serviceGroup;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.volumeUpdateTimer = [[SAVCoalescedTimer alloc] init];
        self.volumeUpdateTimer.timeInverval = 3;
    }
    return self;
}

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)serviceGroup
{
    self = [self init];
    if (self)
    {
        self.globalVolume = YES;
        self.serviceGroup = serviceGroup;
    }
    return self;
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [self init];
    if (self)
    {
        self.service = service;
    }
    return self;
}

- (void)sendReleaseCommandFromSlingshot:(SCUSlingshot *)slingshot
{
    SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.isGlobalVolume ? self.serviceGroup.wildCardedService : [self.serviceGroup.services firstObject]];
    serviceRequest.request = @"CancelVolumeFade";
    
    [self sendServiceRequest:serviceRequest];
}

- (void)sendCommandFromSlingshot:(SCUSlingshot *)slingshot withValue:(NSInteger)value
{
    if (value != 0)
    {
        SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.isGlobalVolume ? self.serviceGroup.wildCardedService : [self.serviceGroup.services firstObject]];

        NSDictionary *arguments = @{@"OnlyActiveServices" : @(YES),
                                    @"Magnitude" : @(labs(value)),
                                    @"TimeInterval" : @1,
                                    @"CombinedServiceAndAudioOnly": self.isGlobalVolume ? @YES : @NO};

        NSString *command = value < 0 ? @"VolumeDown" : @"VolumeUp";

        serviceRequest.request = command;
        serviceRequest.requestArguments = arguments;
        [self sendServiceRequest:serviceRequest];
    }
}

- (void)setDelegate:(id<SCUVolumeModelDelegate>)delegate
{
    if (_delegate != delegate)
    {
        _delegate = delegate;

        if (_delegate)
        {
            SAVWeakSelf;
            self.volumeTracking = [[SAVKVORegistration alloc] initWithObserver:self target:self.delegate selector:@selector(isTracking) handler:^(NSDictionary *changeDictionary) {

                SAVStrongWeakSelf;

                if (sSelf.delegate.isTracking)
                {
                    sSelf.disableVolumeUpdate = YES;
                    [sSelf.volumeUpdateTimer removeWorkWithKey:@"volumeUpdate"];
                }
                else
                {
                    [sSelf.volumeUpdateTimer addWorkWithKey:@"volumeUpdate" work:^{
                        wSelf.disableVolumeUpdate = NO;
                        [wSelf.delegate didUpdateVolume:wSelf.currentVolume];
                    }];
                }
            }];
        }
        else
        {
            self.volumeTracking = nil;
        }

        dispatch_next_runloop(^{
            [self updateGlobalRoomVolume];
        });
    }
}

- (void)setService:(SAVService *)service
{
    self.globalVolume = service.zoneName ? NO : YES;
    SAVServiceGroup *serviceGroup = [[SAVServiceGroup alloc] init];
    [serviceGroup addService:service];
    self.serviceGroup = serviceGroup;
}

- (SAVService *)service
{
    return self.globalVolume ? [self.serviceGroup.activeServices firstObject] : [self.serviceGroup.services firstObject];
}

- (void)setGlobalVolume:(BOOL)globalVolume
{
    _globalVolume = globalVolume;

    [self.delegate updateGlobalVolume];
}

- (void)setServiceGroup:(SAVServiceGroup *)serviceGroup
{
    if ([serviceGroup isEqualToServiceGroup:_serviceGroup])
    {
        return;
    }

    if (self.muteState)
    {
        [[Savant states] unregisterForStates:@[self.muteState] forObserver:self];
    }

    [[Savant states] removeVolumeObserver:self];
    [[Savant states] removeActiveServiceObserver:self];

    _serviceGroup = serviceGroup;

    if (self.isGlobalVolume)
    {
        self.muteState = [NSString stringWithFormat:@"%@.%@.isMuted", self.service.component, self.service.connectorId ?: self.service.logicalComponent];

        if (self.muteState)
        {
            [[Savant states] registerForStates:@[self.muteState] forObserver:self];
        }

        [[Savant states] addActiveServiceObserver:self];
    }
    else
    {
        self.muteState = nil;
    }

    [[Savant states] addVolumeObserver:self];
    self.registered = YES;
    [self updateGlobalRoomVolume];
}

- (void)setVolume:(NSNumber *)volume
{
    [self sendCommand:@"SetVolume" withArguments:@{@"VolumeValue": volume}];
}

- (void)updateGlobalRoomVolume
{
    if (self.delegate.showRoomVolume && [self.serviceGroup.activeServices count] > 1)
    {
        [self.delegate hideGlobalRoomVolume];
    }
    else if (!self.delegate.showRoomVolume && [self.serviceGroup.activeServices count] == 1)
    {
        [self.delegate showGlobalRoomVolume];
    }
}

- (void)decreaseVolume
{
    [self sendCommand:@"VolumeDown"];
}

- (void)increaseVolume
{
    [self sendCommand:@"VolumeUp"];
}

- (void)muteOff
{
    [self sendCommand:@"MuteOff"];
}

- (void)muteOn
{
    [self sendCommand:@"MuteOn"];
}

- (void)mute
{
    if (self.muted)
    {
        [self muteOff];
    }
    else
    {
        [self muteOn];
    }
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    [self updateGlobalRoomVolume];

    if (self.isRegistered)
    {
        SAVStateManager *stateManager = [Savant states];
        NSString *room = self.service.zoneName;

        if (room)
        {
            [self room:room didUpdateVolume:[stateManager volumeForRoom:room]];
            [self room:room didUpdateMuteStatus:[stateManager muteStatusForRoom:room]];
            [self room:room didUpdateDiscreteVolumeStatus:[stateManager discreteVolumeStatusForRoom:room]];
        }
    }
    else
    {
        [[Savant states] addVolumeObserver:self];
    }

    self.registered = YES;
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];

    [[Savant states] removeVolumeObserver:self];
    self.registered = NO;
}

- (void)room:(NSString *)roomId didUpdateVolume:(NSNumber *)volume
{
    if ([roomId isEqualToString:self.service.zoneName])
    {
        self.currentVolume = [volume integerValue];

        if (!self.disableVolumeUpdate)
        {
            [self.delegate didUpdateVolume:[volume integerValue]];
        }
    }
}

- (void)room:(NSString *)roomId didUpdateMuteStatus:(BOOL)muted
{
    if ([roomId isEqualToString:self.service.zoneName])
    {
        [self.delegate didUpdateMuteStatus:muted];
        self.muted = muted;
    }
}

- (void)room:(NSString *)roomId didUpdateDiscreteVolumeStatus:(BOOL)discreteVolumeAvailable
{
    if ([roomId isEqualToString:self.service.zoneName])
    {
        [self.delegate didUpdateDiscreteVolumeStatus:discreteVolumeAvailable];
        self.discrete = discreteVolumeAvailable;
    }
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state isEqualToString:self.muteState])
    {
        BOOL muted = [stateUpdate.value boolValue];

        [self.delegate didUpdateMuteStatus:muted];
        self.muted = muted;
    }
}

- (void)room:(NSString *)roomId didUpdateActiveServiceList:(NSArray *)services
{
    [self updateGlobalRoomVolume];
}

@end
