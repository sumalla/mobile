//
//  SAVPoolDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/2/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVPoolDemoRouter.h"
#import "SAVControlPrivate.h"
#import "rpmSharedLogger.h"
#import "SAVMutableService.h"
#import "SAVPoolEntity.h"
#import "Savant.h"
@import Extensions;

@interface SAVPoolDemoRouter ()

@property NSMutableDictionary *schedules;
@property NSDictionary *globalSettings;

@property NSDictionary *entityForDeviceAndAddress;

@end

@implementation SAVPoolDemoRouter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self buildEntityMap];
    }
    return self;
}

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    BOOL shouldHandle = NO;
    id response = nil;

    if (response)
    {
        shouldHandle = YES;

        if ([response isKindOfClass:[SAVDISResults class]])
        {
            SAVDISResults *results = (SAVDISResults *)response;

           
            results.app = request.app;
            results.request = request.request;
        }
        else if ([response isKindOfClass:[SAVDISFeedback class]])
        {
            SAVDISFeedback *feedback = (SAVDISFeedback *)response;
            feedback.app = request.app;
        }

        [[Savant control].demoServer sendMessage:response];
    }

    return shouldHandle;
}

#pragma mark - Entities

- (void)buildEntityMap
{
    SAVMutableService *poolService = [[SAVMutableService alloc] init];
    poolService.serviceId = @"SVC_ENV_POOLANDSPA";
    poolService.serviceAlias = @"Pool";
    poolService.zoneName = @"Patio";
    poolService.component = @"Pool Control";
    poolService.logicalComponent = @"Pool_and_spa_controller";

    NSArray *entities = [[Savant data] poolEntities:nil zone:nil service:poolService];

    NSMutableDictionary *entityForDeviceAndAddress = [NSMutableDictionary dictionary];
    for (SAVPoolEntity *entity in entities)
    {
        //-------------------------------------------------------------------
        // Ignore entities without states as we can't do anything for them
        //-------------------------------------------------------------------
        if (entity.humiditySPCount > 0 || entity.tempSPCount > 0)
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

- (BOOL)handleServiceRequest:(SAVServiceRequest *)request
{
    BOOL shouldHandle = NO;

    if ([request.serviceId isEqualToString:@"SVC_ENV_POOLANDSPA"])
    {
        NSString *scope = [NSString stringWithFormat:@"%@.%@", request.component, request.logicalComponent];

        if (self.entityForDeviceAndAddress[scope])
        {
            NSMutableArray *addresses = [NSMutableArray array];

            for (NSString *arg in [request.requestArguments sav_sortedStringKeys])
            {
                [addresses addObject:request.requestArguments[arg]];
            }

            if (self.entityForDeviceAndAddress[scope][addresses])
            {
                NSMutableDictionary *states = [NSMutableDictionary dictionary];

                SAVEntityEvent event = [[[[[[self.entityForDeviceAndAddress allValues] lastObject] allValues] lastObject] lastObject] eventForCommand:request.request];
                NSMutableDictionary *stateTypeToValue = [NSMutableDictionary dictionary];

                BOOL changedHeat = NO;
                BOOL changedCool = NO;

                switch (event)
                {
                    case SAVEntityEvent_IncrementPoolHeaterSetpoint:
                        changedCool = YES;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterSetpoint)] = @"increment";
                        break;
                    case SAVEntityEvent_DecrementPoolHeaterSetpoint:
                        changedCool = YES;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterSetpoint)] = @"decrement";
                        break;
                    case SAVEntityEvent_SetPoolHeaterSetpoint:
                        changedCool = YES;
                        if (request.requestArguments[@"PoolHeaterSetpoint"])
                        {
                            stateTypeToValue[@(SAVEntityEvent_SetPoolHeaterSetpoint)] = request.requestArguments[@"PoolHeaterSetpoint"];
                        }
                        break;
                        
                        
                    case SAVEntityEvent_IncrementSpaHeaterSetpoint:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_SpaHeaterSetpoint)] = @"increment";
                        break;
                    case  SAVEntityEvent_DecrementSpaHeaterSetpoint:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_SpaHeaterSetpoint)] = @"decrement";
                        break;
                    case SAVEntityEvent_SetSpaHeaterSetpoint:
                        changedHeat = YES;
                        if (request.requestArguments[@"SpaHeaterSetpoint"])
                        {
                            stateTypeToValue[@(SAVEntityState_SpaHeaterSetpoint)] = request.requestArguments[@"SpaHeaterSetpoint"];
                        }
                        break;
                        
                    case SAVEntityEvent_IncrementPoolHeaterSecondarySetpoint:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterSecondarySetpoint)] = @"increment";
                        break;
                    case SAVEntityEvent_DecrementPoolHeaterSecondarySetpoint:
                        changedHeat = YES;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterSecondarySetpoint)] = @"decrement";
                        break;
                    case SAVEntityEvent_SetPoolHeaterSecondarySetpoint:
                        changedHeat = YES;
                        if (request.requestArguments[@"PoolHeaterSecondarySetpoint"])
                        {
                            stateTypeToValue[@(SAVEntityState_PoolHeaterSecondarySetpoint)] = request.requestArguments[@"PoolHeaterSecondarySetpoint"];
                        }
                        break;
                        
                    case SAVEntityEvent_SetPumpModeOn:
                        stateTypeToValue[@(SAVEntityState_PumpMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_PumpModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_PumpModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsPumpModeOn)] = @"On";
                        break;
                    case SAVEntityEvent_SetPumpModeOff:
                        stateTypeToValue[@(SAVEntityState_PumpMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_PumpModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_PumpModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsPumpModeOn)] = @"Off";
                        break;
                        
                    case SAVEntityEvent_SetPumpSpeedHigh:
                        stateTypeToValue[@(SAVEntityState_PumpSpeed)] = @"High";
                        stateTypeToValue[@(SAVEntityState_PumpSpeedLow)] = @NO;
                        stateTypeToValue[@(SAVEntityState_PumpSpeedHigh)] = @YES;
                        break;
                    case SAVEntityEvent_SetPumpSpeedLow:
                        stateTypeToValue[@(SAVEntityState_PumpSpeed)] = @"Low";
                        stateTypeToValue[@(SAVEntityState_PumpSpeedLow)] = @YES;
                        stateTypeToValue[@(SAVEntityState_PumpSpeedHigh)] = @NO;
                        break;
                        
                    case SAVEntityEvent_EnablePoolHeater:
                        stateTypeToValue[@(SAVEntityState_PoolHeaterMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_PoolHeaterModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsPoolHeaterOn)] = @YES;
                        break;
                    case SAVEntityEvent_DisablePoolHeater:
                        stateTypeToValue[@(SAVEntityState_PoolHeaterMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_PoolHeaterModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_PoolHeaterModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsPoolHeaterOn)] = @NO;
                        break;

                    case SAVEntityEvent_EnableSpaHeater:
                        stateTypeToValue[@(SAVEntityState_SpaHeaterMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_SpaHeaterModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_SpaHeaterModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsSpaHeaterOn)] = @"On";
                        break;
                    case SAVEntityEvent_DisableSpaHeater:
                        stateTypeToValue[@(SAVEntityState_SpaHeaterMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_SpaHeaterModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_SpaHeaterModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsSpaHeaterOn)] = @"Off";
                        break;

                    case SAVEntityEvent_EnableSecondaryPoolHeater:
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsSecondaryPoolHeaterMode)] = @"On";
                        break;
                    case SAVEntityEvent_DisableSecondaryPoolHeater:
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_SecondaryPoolHeaterModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsSecondaryPoolHeaterMode)] = @"Off";
                        break;
                        
                    case SAVEntityEvent_EnableSolarHeater:
                        stateTypeToValue[@(SAVEntityState_SolarHeaterMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_SolarHeaterModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_SolarHeaterModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsSolarHeaterOn)] = @"On";
                        break;
                        
                    case SAVEntityEvent_DisableSolarHeater:
                        stateTypeToValue[@(SAVEntityState_SolarHeaterMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_SolarHeaterModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_SolarHeaterModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsSolarHeaterOn)] = @"Off";
                        break;
                        
                    case SAVEntityEvent_SetSpaModeOn:
                        stateTypeToValue[@(SAVEntityState_SpaMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_SpaModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_SpaModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsSpaModeOn)] = @YES;
                        break;
                    case SAVEntityEvent_SetSpaModeOff:
                        stateTypeToValue[@(SAVEntityState_SpaMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_SpaModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_SpaModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsSpaModeOn)] = @NO;
                        break;
                        
                    case SAVEntityEvent_SetWaterfallModeOn:
                        stateTypeToValue[@(SAVEntityState_WaterfallMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_WaterfallModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_WaterfallModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsWaterfallModeOn)] = @YES;
                        break;
                    case SAVEntityEvent_SetWaterfallModeOff:
                        stateTypeToValue[@(SAVEntityState_WaterfallMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_WaterfallModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_WaterfallModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsWaterfallModeOn)] = @NO;
                        break;
                        
                    case SAVEntityEvent_SetCleaningSystemOn:
                        stateTypeToValue[@(SAVEntityState_CleaningSystemMode)] = @"On";
                        stateTypeToValue[@(SAVEntityState_CleaningSystemModeOff)] = @NO;
                        stateTypeToValue[@(SAVEntityState_CleaningSystemModeOn)] = @YES;
                        stateTypeToValue[@(SAVEntityState_IsCleaningSystemModeOn)] = @YES;
                        break;
                    case SAVEntityEvent_SetCleaningSystemOff:
                        stateTypeToValue[@(SAVEntityState_CleaningSystemMode)] = @"Off";
                        stateTypeToValue[@(SAVEntityState_CleaningSystemModeOff)] = @YES;
                        stateTypeToValue[@(SAVEntityState_CleaningSystemModeOn)] = @NO;
                        stateTypeToValue[@(SAVEntityState_IsCleaningSystemModeOn)] = @NO;
                        break;

                    case SAVEntityEvent_ToggleCleaningSystem:
                    case SAVEntityEvent_TogglePoolHeater:
                    case SAVEntityEvent_TogglePumpMode:
                    case SAVEntityEvent_TogglePumpSpeed:
                    case SAVEntityEvent_ToggleSecondaryPoolHeater:
                    case SAVEntityEvent_ToggleSolarHeater:
                    case SAVEntityEvent_ToggleSpaHeater:
                    case SAVEntityEvent_ToggleSpaMode:
                    case SAVEntityEvent_ToggleWaterfallMode:
                        break;
                    default:
//                        RPMLogErr(@"Unexpected event type for Pool entity %ld", (long)event);
                        break;
                }

                for (NSNumber *state in stateTypeToValue)
                {
                    for (SAVPoolEntity *entity in self.entityForDeviceAndAddress[scope][addresses])
                    {
                        NSString *stateString = [entity stateFromType:[state integerValue]];
                        id stateValue = stateTypeToValue[state];
                        if (stateString)
                        {
                            if ([stateValue isKindOfClass:[NSString class]])
                            {
                                if ([stateValue isEqualToString:@"increment"])
                                {
                                    stateValue = @([[Savant control].demoServer.allStates[stateString] integerValue] + 1);
                                }
                                else if ([stateValue isEqualToString:@"decrement"])
                                {
                                    stateValue = @([[Savant control].demoServer.allStates[stateString] integerValue] - 1);
                                }
                            }

                            states[stateString] = stateValue;
                        }
                    }
                }

                if ([states count])
                {
                    for (SAVPoolEntity *entity in self.entityForDeviceAndAddress[scope][addresses])
                    {
                        // Bounds checks
                        NSString *coolPointState = [entity stateFromType:SAVEntityState_PoolHeaterSetpoint];
                        NSString *heatPointState = [entity stateFromType:SAVEntityState_PoolHeaterSecondarySetpoint];

                        NSInteger heatPoint = 0;
                        if (states[heatPointState])
                        {
                            heatPoint = [states[heatPointState] integerValue];
                        }
                        else
                        {
                            heatPoint = [[Savant control].demoServer.allStates[heatPointState] integerValue];
                        }

                        NSInteger coolPoint = 0;
                        if (states[coolPointState])
                        {
                            coolPoint = [states[coolPointState] integerValue];
                        }
                        else
                        {
                            coolPoint = [[Savant control].demoServer.allStates[coolPointState] integerValue];
                        }

                        if (changedCool && (heatPoint > (coolPoint - 10)))
                        {
                            states[heatPointState] = @(coolPoint - 10);
                        }

                        if (changedHeat && (coolPoint < (heatPoint + 10)))
                        {
                            states[coolPointState] = @(heatPoint + 10);
                        }
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
