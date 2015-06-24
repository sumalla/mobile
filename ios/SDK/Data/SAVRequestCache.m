//
//  SAVRequestCache.m
//  SavantControl
//
//  Created by Nathan Trapp on 10/17/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import <SDK/SAVRequestCache.h>
#import "Savant.h"
@import Extensions;

@interface SAVRequestCache () <SystemStatusDelegate>

@property (nonatomic) NSMutableArray *transportCommandsPaired;

@property (nonatomic) NSMutableDictionary *commandsToService;
@property (nonatomic) NSMutableDictionary *customCommandsToService;
@property (nonatomic) NSMutableDictionary *channelCommandsToService;
@property (nonatomic) NSMutableDictionary *pageCommandsToService;
@property (nonatomic) NSMutableDictionary *numberPadCommandsToService;
@property (nonatomic) NSMutableDictionary *navigationCommandsToService;
@property (nonatomic) NSMutableDictionary *dynamicCommandsToService;
@property (nonatomic) NSMutableDictionary *volumeCommandsToService;
@property (nonatomic) NSMutableDictionary *powerCommandsToService;
@property (nonatomic) NSMutableDictionary *favoriteCommandsToService;

@property (nonatomic) NSMutableDictionary *transportCommandsToService;
@property (nonatomic) NSMutableDictionary *transportGenericCommandsToService;
@property (nonatomic) NSMutableDictionary *transportBackCommandsToService;
@property (nonatomic) NSMutableDictionary *transportForwardCommandsToService;

@property (nonatomic) NSOrderedSet *allTransportBackCommands;
@property (nonatomic) NSOrderedSet *allTransportForwardCommands;
@property (nonatomic) NSOrderedSet *allGenericTransportCommands;
@property (nonatomic) NSOrderedSet *allPosibleNumberPadCommands;
@property (nonatomic) NSOrderedSet *allPosibleChannelCommands;
@property (nonatomic) NSSet *allPosiblePageCommands;
@property (nonatomic) NSSet *allPosibleNavigationCommands;
@property (nonatomic) NSSet *allPosiblePowerCommands;
@property (nonatomic) NSSet *allPosibleVolumeCommands;
@property (nonatomic) NSSet *allPosibleFavoriteCommands;
@property (nonatomic) NSDictionary *transportCommandPairings;

@end

@implementation SAVRequestCache

+ (instancetype)sharedInstance
{
    static SAVRequestCache *commands = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commands = [[[self class] alloc] init];
    });

    return commands;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self resetCache];
        [self setupPosibleServiceCommands];

        [[Savant control] addSystemStatusObserver:self];
    }
    return self;
}

- (void)resetCache
{
    self.transportCommandsPaired = [NSMutableArray array];
    self.commandsToService = [NSMutableDictionary dictionary];
    self.customCommandsToService = [NSMutableDictionary dictionary];
    self.channelCommandsToService = [NSMutableDictionary dictionary];
    self.pageCommandsToService = [NSMutableDictionary dictionary];
    self.numberPadCommandsToService = [NSMutableDictionary dictionary];
    self.navigationCommandsToService = [NSMutableDictionary dictionary];
    self.dynamicCommandsToService = [NSMutableDictionary dictionary];
    self.volumeCommandsToService = [NSMutableDictionary dictionary];
    self.powerCommandsToService = [NSMutableDictionary dictionary];
    self.favoriteCommandsToService = [NSMutableDictionary dictionary];

    self.transportCommandsToService = [NSMutableDictionary dictionary];
    self.transportGenericCommandsToService = [NSMutableDictionary dictionary];
    self.transportBackCommandsToService = [NSMutableDictionary dictionary];
    self.transportForwardCommandsToService = [NSMutableDictionary dictionary];
}

- (void)connectionIsReady
{
    [self resetCache];
}

- (void)setupPosibleServiceCommands
{
    self.allTransportBackCommands = [NSOrderedSet orderedSetWithArray:@[@"SkipDown", @"ScanDown", @"Rewind", @"FastPlayReverse", @"Replay"]];

    self.allTransportForwardCommands = [NSOrderedSet orderedSetWithArray:@[@"Advance", @"30SecondSkipForward", @"FastPlayForward", @"FastForward", @"ScanUp", @"SkipUp"]];

    self.allGenericTransportCommands = [NSOrderedSet orderedSetWithArray:@[@"Play", @"Pause", @"Stop", @"Record", @"LiveTV", @"LastChannel", @"Slow", @"Eject"]];

    self.transportCommandPairings = @{@[@"SkipDown"]: @[@"SkipUp"], @[@"ScanDown", @"Rewind", @"FastPlayReverse"]: @[@"ScanUp", @"FastForward", @"FastPlayForward"], @[@"Replay"]: @[@"Advance", @"30SecondSkipForward"]};

    self.allPosibleNumberPadCommands = [NSOrderedSet orderedSetWithArray:@[@"NumberOne", @"NumberTwo", @"NumberThree",
                                                             @"NumberFour", @"NumberFive", @"NumberSix",
                                                             @"NumberSeven", @"NumberEight", @"NumberNine",
                                                             @"Dash", @"NumberZero", @"Enter", @"NumberPoint",
                                                             @"NumberEnter", @"NumberPlusTen", @"NumberAsterix", @"NumberPound"]];

    self.allPosibleChannelCommands = [NSOrderedSet orderedSetWithArray:@[@"ChannelDigitalDown", @"ChannelDigitalUp",
                                                           @"ChannelDigitalSelect", @"ChannelAnalogDown",
                                                           @"ChannelAnalogUp", @"ChannelAnalogSelect",
                                                           @"ChannelNameSelect",
                                                           @"ChannelOne", @"ChannelTwo", @"ChannelThree", @"ChannelFour", @"ChannelFive", @"ChannelSix", @"ChannelSeven", @"ChannelEight", @"ChannelNine", @"ChannelTen", @"ChannelEleven", @"ChannelTwelve", @"ChannelThirteen", @"ChannelFourteen", @"ChannelFifteen", @"ChannelSixteen"
                                                           ]];

    self.allPosiblePageCommands = [NSSet setWithArray:@[@"OSDPageDown", @"OSDPageUp", @"PageDown", @"PageUp"]];

    self.allPosibleNavigationCommands = [NSSet setWithArray:@[@"OSDCursorDown", @"OSDCursorLeft",
                                                              @"OSDCursorRight", @"OSDCursorUp",
                                                              @"OSDSelect", @"Enter"]];

    self.allPosibleVolumeCommands = [NSSet setWithArray:@[@"VolumeDown", @"VolumeUp", @"MuteOn",
                                                          @"MuteOff", @"SetVolume",  @"BalanceRight",
                                                          @"BalanceLeft", @"SetBalance", @"SetTrim"]];

    self.allPosiblePowerCommands = [NSSet setWithArray:@[@"PowerOff", @"PowerOn", @"PowerOnTransitionOnly"]];

    self.allPosibleFavoriteCommands = [NSSet setWithArray:@[@"ChannelAnalogSelect", @"SetChannel", @"SetRadioFrequency"]];
}

- (NSArray *)customCommandsForService:(SAVService *)service
{
    SAVService *genericService = [[SAVService alloc] initWithZone:service.zoneName
                                                        component:nil
                                                 logicalComponent:nil
                                                        variantId:nil
                                                        serviceId:@"SVC_GEN_GENERIC"];

    if (!self.customCommandsToService[genericService.serviceString])
    {
        NSSet *commands = [NSSet setWithArray:[[[Savant data] requests:genericService onlyVisible:YES] arrayByMappingBlock:^id(SAVServiceRequest *request) {
            return request.request;
        }]];

        if (commands)
        {
            self.customCommandsToService[genericService.serviceString] = [commands allObjects];
        }
    }

    return self.customCommandsToService[genericService.serviceString];
}

- (NSArray *)commandsForService:(SAVService *)service
{
    if (!self.commandsToService[service.serviceString])
    {
        NSSet *commands = [NSSet setWithArray:[[[Savant data] requestsFilteredByService:service] arrayByMappingBlock:^id(SAVServiceRequest *request) {
            return request.request;
        }]];

        if (commands)
        {
            self.commandsToService[service.serviceString] = [commands allObjects];
        }
    }

    return self.commandsToService[service.serviceString];
}

- (NSArray *)channelCommandsForService:(SAVService *)service
{
    if (!self.channelCommandsToService[service.serviceString])
    {
        self.channelCommandsToService[service.serviceString] = [self validCommands:self.allPosibleChannelCommands forService:service];
    }

    return self.channelCommandsToService[service.serviceString];
}

- (NSArray *)pageCommandsForService:(SAVService *)service
{
    if (!self.pageCommandsToService[service.serviceString])
    {
        self.pageCommandsToService[service.serviceString] = [self validCommands:self.allPosiblePageCommands forService:service];
    }

    return self.pageCommandsToService[service.serviceString];
}

- (NSArray *)numberPadCommandsForService:(SAVService *)service
{
    if (!self.numberPadCommandsToService[service.serviceString])
    {
        self.numberPadCommandsToService[service.serviceString] = [self validCommands:self.allPosibleNumberPadCommands forService:service];
    }

    return self.numberPadCommandsToService[service.serviceString];
}

- (NSArray *)navigationCommandsForService:(SAVService *)service
{
    if (!self.navigationCommandsToService[service.serviceString])
    {
        self.navigationCommandsToService[service.serviceString] = [self validCommands:self.allPosibleNavigationCommands forService:service];
    }

    return self.navigationCommandsToService[service.serviceString];
}

- (NSArray *)dynamicCommandsForService:(SAVService *)service
{
    if (!self.dynamicCommandsToService[service.serviceString])
    {
        NSMutableArray *dynamicCommands = [NSMutableArray arrayWithArray:[self commandsForService:service]];

        [dynamicCommands removeObjectsInArray:[self transportCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self numberPadCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self channelCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self pageCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self navigationCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self volumeCommandsForService:service]];
        [dynamicCommands removeObjectsInArray:[self powerCommandsForService:service]];
        [dynamicCommands removeObject:@"Exit"];

        self.dynamicCommandsToService[service.serviceString] = [dynamicCommands copy];
    }

    return self.dynamicCommandsToService[service.serviceString];
}

- (NSArray *)volumeCommandsForService:(SAVService *)service
{
    if (!self.volumeCommandsToService[service.serviceString])
    {
        self.volumeCommandsToService[service.serviceString] = [[self commandsForService:service] filteredArrayUsingBlock:^BOOL(NSString *requestString) {
            return [self.allPosibleVolumeCommands containsObject:requestString] ||
            ([requestString rangeOfString:@"Mute"].length > 0);
        }];
    }

    return self.volumeCommandsToService[service.serviceString];
}

- (NSArray *)powerCommandsForService:(SAVService *)service
{
    if (!self.powerCommandsToService[service.serviceString])
    {
        self.powerCommandsToService[service.serviceString] = [[self commandsForService:service] filteredArrayUsingBlock:^BOOL(NSString *requestString) {
            return ([self.allPosiblePowerCommands containsObject:requestString] ||
                    [requestString hasSuffix:@"_PowerToggle"]);
        }];
    }

    return self.powerCommandsToService[service.serviceString];
}

- (NSArray *)transportCommandsForService:(SAVService *)service
{
    if (!self.transportCommandsToService[service.serviceString])
    {
        NSMutableArray *transportCommands = [NSMutableArray array];

        [transportCommands addObjectsFromArray:[self transportForwardCommandsForService:service]];
        [transportCommands addObjectsFromArray:[self transportBackCommandsForService:service]];
        [transportCommands addObjectsFromArray:[self transportGenericCommandsForService:service]];

        self.transportCommandsToService[service.serviceString] = [transportCommands copy];
    }

    return self.transportCommandsToService[service.serviceString];
}

- (NSArray *)transportBackCommandsForService:(SAVService *)service
{
    if (!self.transportBackCommandsToService[service.serviceString])
    {
        [self pairBackForwardCommandsForService:service];
    }

    return self.transportBackCommandsToService[service.serviceString];
}

- (NSArray *)transportForwardCommandsForService:(SAVService *)service
{
    if (!self.transportForwardCommandsToService[service.serviceString])
    {
        [self pairBackForwardCommandsForService:service];
    }

    return self.transportForwardCommandsToService[service.serviceString];
}

- (void)pairBackForwardCommandsForService:(SAVService *)service
{
    if ([self.transportCommandsPaired containsObject:service.serviceString])
    {
        return;
    }

    [self.transportCommandsPaired addObject:service.serviceString];

    NSMutableArray *backCommands = [[self validCommands:self.allTransportBackCommands forService:service] mutableCopy];

    NSMutableArray *forwardCommands = [[self validCommands:self.allTransportForwardCommands forService:service] mutableCopy];

    for (NSArray *back in self.transportCommandPairings)
    {
        NSArray *forward = self.transportCommandPairings[back];

        NSString *backCommand = nil;
        NSString *forwardCommand = nil;

        for (NSString *command in back)
        {
            if ([backCommands containsObject:command])
            {
                backCommand = command;
                break;
            }
        }

        for (NSString *command in forward)
        {
            if ([forwardCommands containsObject:command])
            {
                forwardCommand = command;
                break;
            }
        }

        if (backCommand && forwardCommand)
        {
            [backCommands removeObject:backCommand];
            [backCommands insertObject:backCommand atIndex:0];

            [forwardCommands removeObject:forwardCommand];
            [forwardCommands addObject:forwardCommand];
        }
        else if (backCommand)
        {
            if ([UIDevice isPad])
            {
                [backCommands removeObject:backCommand];
                [backCommands addObject:backCommand];
            }
            else
            {
                [backCommands removeObject:backCommand];
                [backCommands insertObject:backCommand atIndex:0];
            }

        }
        else if (forwardCommand)
        {
            if ([UIDevice isPad])
            {
                [forwardCommands removeObject:forwardCommand];
                [forwardCommands insertObject:forwardCommand atIndex:0];
            }
            else
            {
                [forwardCommands removeObject:forwardCommand];
                [forwardCommands addObject:forwardCommand];
            }
        }
    }

    self.transportBackCommandsToService[service.serviceString] = [backCommands copy];
    self.transportForwardCommandsToService[service.serviceString] = [forwardCommands copy];
}

- (NSArray *)favoriteCommandsForService:(SAVService *)service
{
    if (!self.favoriteCommandsToService[service.serviceString])
    {
        self.favoriteCommandsToService[service.serviceString] = [self validCommands:self.allPosibleFavoriteCommands forService:service];
    }

    return self.favoriteCommandsToService[service.serviceString];
}

- (NSArray *)transportGenericCommandsForService:(SAVService *)service
{
    if (!self.transportGenericCommandsToService[service.serviceString])
    {
        self.transportGenericCommandsToService[service.serviceString] = [self validCommands:self.allGenericTransportCommands forService:service];
    }

    return self.transportGenericCommandsToService[service.serviceString];
}

#pragma mark - Available Commands

- (NSArray *)validCommands:(id)set forService:(SAVService *)service
{
    id commands = [set mutableCopy];
    
    [commands intersectOrderedSet:[NSOrderedSet orderedSetWithArray:[self commandsForService:service]]];
    
    return [commands allObjects];
}

@end
