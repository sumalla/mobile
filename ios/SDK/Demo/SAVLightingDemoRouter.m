//
//  SAVLightingDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 9/8/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVLightingDemoRouter.h"
#import "SAVControlPrivate.h"
#import "SAVLightEntity.h"
#import "Savant.h"
@import Extensions;

@interface SAVLightingDemoRouter ()

@property NSDictionary *entityForDeviceAndAddress;

@end

@implementation SAVLightingDemoRouter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSArray *entities = [[Savant data] lightEntitiesForRoom:nil];

        NSMutableDictionary *entityForDeviceAndAddress = [NSMutableDictionary dictionary];
        for (SAVLightEntity *entity in entities)
        {
            //-------------------------------------------------------------------
            // Ignore entities without states as we can't do anything for them
            //-------------------------------------------------------------------
            if (entity.stateName)
            {
                NSString *device = [NSString stringWithFormat:@"%@.%@", entity.service.component, entity.service.logicalComponent];
                NSMutableDictionary *deviceDictionary = entityForDeviceAndAddress[device];
                if (!deviceDictionary)
                {
                    deviceDictionary = [NSMutableDictionary dictionary];
                    entityForDeviceAndAddress[device] = deviceDictionary;
                }

                NSMutableArray *entityArray = deviceDictionary[entity.addresses];
                if (!entityArray)
                {
                    entityArray = [NSMutableArray array];
                    deviceDictionary[entity.addresses] = entityArray;
                }
                
                [entityArray addObject:entity];
            }
        }

        self.entityForDeviceAndAddress = entityForDeviceAndAddress;
    }
    return self;
}

- (BOOL)handleServiceRequest:(SAVServiceRequest *)request
{
    BOOL shouldHandle = NO;

    if ([request.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
    {
        if (request.zoneName && [request.request isEqualToString:@"__RoomLightsOff"])
        {
            NSArray *entities = [[Savant data] lightEntitiesForRoom:request.zoneName];
            NSMutableDictionary *states = [NSMutableDictionary dictionary];
            states[[NSString stringWithFormat:@"%@.RoomLightsAreOn", request.zoneName]] = @NO;

            for (SAVLightEntity *entity in entities)
            {
                if (entity.stateName)
                {
                    states[entity.stateName] = @0;
                }
            }

            [[Savant control].demoServer sendStateUpdate:states];
        }
        else
        {
            NSString *scope = [NSString stringWithFormat:@"%@.%@", request.component, request.logicalComponent];

            if (self.entityForDeviceAndAddress[scope])
            {
                NSMutableArray *addresses = [NSMutableArray array];

                for (NSString *arg in [request.requestArguments sav_sortedStringKeys])
                {
                    if ([arg hasPrefix:@"Address"])
                    {
                        [addresses addObject:request.requestArguments[arg]];
                    }
                }

                if (self.entityForDeviceAndAddress[scope][addresses])
                {
                    NSMutableDictionary *states = [NSMutableDictionary dictionary];
                    id dimmerLevel = request.requestArguments[@"DimmerLevel"];

                    for (SAVLightEntity *entity in self.entityForDeviceAndAddress[scope][addresses])
                    {
                        id previousValue = [Savant control].demoServer.allStates[entity.stateName];

                        if (dimmerLevel)
                        {
                            states[entity.stateName] = dimmerLevel;
                        }
                        else
                        {
                            states[entity.stateName] = [previousValue boolValue] ? @0 : @100;
                        }

                        NSInteger value = [states[entity.stateName] integerValue];

                        if (value > 0)
                        {
                            states[[NSString stringWithFormat:@"%@.RoomLightsAreOn", request.zoneName]] = @YES;
                        }
                    }

                    [[Savant control].demoServer sendStateUpdate:states];

                    NSArray *entities = [[Savant data] lightEntitiesForRoom:request.zoneName];

                    BOOL lightsAreOff = YES;

                    for (SAVLightEntity *l in entities)
                    {
                        if (l.stateName && [[Savant control].demoServer.allStates[l.stateName] integerValue] > 0)
                        {
                            lightsAreOff = NO;
                            break;
                        }
                    }

                    if (lightsAreOff)
                    {
                        states[[NSString stringWithFormat:@"%@.RoomLightsAreOn", request.zoneName]] = @NO;
                    }

                    [[Savant control].demoServer sendStateUpdate:states];
                }
            }

        }

        shouldHandle = YES;
    }

    return shouldHandle;
}

@end
