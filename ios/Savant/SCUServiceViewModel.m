//
//  SCUServiceViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"
@import SDK;

NSTimeInterval const SCUServiceModelDefaultHoldInterval = 0.25;

@interface SCUServiceViewModel ()

@property (weak) NSTimer *holdTimer;
@property (nonatomic) NSString *stateScope;
@property (nonatomic) SAVService *envService;

@end

@implementation SCUServiceViewModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];
    if (self)
    {
        self.shouldPowerOn = YES;

        if (service)
        {
            if ([service.serviceId hasPrefix:@"SVC_ENV"])
            {
                self.envService = service;
            }
            else
            {
                self.serviceGroup = [[SAVServiceGroup alloc] init];
                [self.serviceGroup addService:service];
            }
        }

        if (self.service.component && self.service.logicalComponent)
        {
            self.stateScope = [NSString stringWithFormat:@"%@.%@", self.service.component, self.service.logicalComponent];
        }
    }
    return self;
}

- (void)sendCommand:(NSString *)command
{
    //-------------------------------------------------------------------
    // Any commands that are not power or volume should only be sent
    // to the group once.
    //-------------------------------------------------------------------
    if (([self.powerCommands containsObject:command] ||
        [self.volumeCommands containsObject:command]) &&
        ![command isEqualToString:@"PowerOn"])
    {
        for (SAVService *service in self.serviceGroup.activeServices)
        {
            SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:service];
            serviceRequest.request = command;

            [self sendServiceRequest:serviceRequest];
        }
    }
    else
    {
        SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.service];
        serviceRequest.request = command;

        [self sendServiceRequest:serviceRequest];
    }
}

- (void)sendCommand:(NSString *)command withArguments:(NSDictionary *)arguments
{
    //-------------------------------------------------------------------
    // Any commands that are not power or volume should only be sent
    // to the group once.
    //-------------------------------------------------------------------
    if ([self.powerCommands containsObject:command] ||
        [self.volumeCommands containsObject:command])
    {
        for (SAVService *service in self.serviceGroup.services)
        {
            SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:service];
            serviceRequest.request = command;
            serviceRequest.requestArguments = arguments;

            [self sendServiceRequest:serviceRequest];
        }
    }
    else
    {
        SAVServiceRequest *serviceRequest = [[SAVServiceRequest alloc] initWithService:self.service];
        serviceRequest.request = command;
        serviceRequest.requestArguments = arguments;

        [self sendServiceRequest:serviceRequest];
    }
}

- (void)sendServiceRequest:(SAVServiceRequest *)serviceRequest
{
    if (serviceRequest)
    {
        [[Savant control] sendMessage:serviceRequest];
    }
}

- (void)sendServiceRequests:(NSArray *)serviceRequests
{
    [[Savant control] sendMessages:serviceRequests];
}

- (void)sendHoldCommand:(NSString *)command withInterval:(NSTimeInterval)interval
{
    [self.holdTimer invalidate];

    SAVWeakSelf;
    self.holdTimer = [NSTimer sav_scheduledTimerWithTimeInterval:interval repeats:YES block:^{
        [wSelf sendCommand:command];
    }];
}

- (void)endHoldCommandWithCommand:(NSString *)command
{
    [self.holdTimer invalidate];

    if ([command length])
    {
        [self sendCommand:command];
    }
}

- (SAVService *)service
{
    return self.envService ? : (self.isServicesFirst ? [self.serviceGroup.activeServices firstObject] : [self.serviceGroup.services firstObject]);
}

- (NSArray *)serviceCommands
{
    return self.service.commands;
}

- (NSArray *)numberPadCommands
{
    return self.service.numberPadCommands;
}

- (NSArray *)transportCommands
{
    return self.service.transportCommands;
}

- (NSArray *)transportGenericCommands
{
    return self.service.transportGenericCommands;
}

- (NSArray *)transportBackCommands
{
    return self.service.transportBackCommands;
}

- (NSArray *)transportForwardCommands
{
    return self.service.transportForwardCommands;
}

- (NSDictionary *)dynamicCommands
{
    return [[Savant data] orderingForService:self.service];
}

- (NSArray *)favoriteCommands
{
    return self.service.favoriteCommands;
}

- (NSArray *)favorites
{
    return [[Savant data] favoritesForService:self.service];
}

- (void)setFavorites:(NSArray *)favoritesArray
{
    [[Savant data] saveFavorites:favoritesArray forService:self.service];
}

- (void)setOrderOfCommands:(NSDictionary *)orderedAndHiddenCommandsDict
{
    [[Savant data] saveOrdering:orderedAndHiddenCommandsDict forService:self.service];
}

- (NSArray *)channelCommands
{
    return self.service.channelCommands;
}

- (NSArray *)pageCommands
{
    return self.service.pageCommands;
}

- (NSArray *)navigationCommands
{
    return self.service.navigationCommands;
}

- (NSArray *)volumeCommands
{
    return self.service.volumeCommands;
}

- (NSArray *)powerCommands
{
    return self.service.powerCommands;
}

#pragma mark - SCUViewModel methods

- (void)viewWillAppear
{
    if ([self shouldPowerOn] && [self.service.serviceId hasPrefix:@"SVC_AV"] &&
        ![[[Savant states] activeServiceForRoom:(NSString * __nonnull)self.service.zoneName] isEqualToService:self.service])
    {
        [self sendCommand:@"PowerOn"];
    }
}

- (void)viewWillDisappear
{
    [self.holdTimer invalidate];
}

#pragma mark - SCUStateReceiver Protocol

- (NSArray *)statesToRegister
{
    return nil;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    ;
}

@end
