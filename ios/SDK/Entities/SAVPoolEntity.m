//
//  SAVPoolEntity.m
//  SavantControl
//
//  Created by Jason Wolkovitz on 10/10/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVPoolEntity.h"
#import "SAVHVACEntity.h"
#import "rpmSharedLogger.h"
#import "SAVServiceRequest.h"
#import "SAVPoolEntityCommands.h"
#import "Savant.h"

@interface SAVPoolEntity ()
{
    NSArray *_states;
}

@end

@implementation SAVPoolEntity

+ (NSString *)addDegreeSuffix:(NSString *)value
{
    return [SAVHVACEntity addDegreeSuffix:value];
}

- (SAVPoolAuxStates)poolStateFromString:(NSString *)value
{
    SAVPoolAuxStates state = SAVPoolAuxStateNone;
    value = [value lowercaseString];
    if ([value isEqualToString:@"on"])
    {
        state = SAVPoolAuxStateOn;
    }
    else if ([value isEqualToString:@"off"])
    {
        state = SAVPoolAuxStateOff;
    }
    else if ([value isEqualToString:@"enabled"])
    {
        state = SAVPoolAuxStateEnabled;
    }
    if ([value isEqualToString:@"true"])
    {
        state = SAVPoolAuxStateOn;
    }
    else if ([value isEqualToString:@"false"])
    {
        state = SAVPoolAuxStateOff;
    }
    else if ([value isEqualToString:@"high"])
    {
        state = SAVPoolAuxStatePumpHigh;
    }
    else if ([value isEqualToString:@"low"])
    {
        state = SAVPoolAuxStatePumpLow;
    }
    if (state == SAVPoolAuxStateNone)
    {
        BOOL boolState = [value boolValue];
        state = boolState ? SAVPoolAuxStateOn : SAVPoolAuxStateOff;
    }
    return state;
}

- (void)addAuxiliaryNumber:(NSString *)number label:(NSString *)label
{
    if (!self.auxiliaryNumberLabels)
    {
        self.auxiliaryNumberLabels = [[NSMutableDictionary alloc] initWithCapacity:8];
    }
    if (!self.auxiliaryNumberOrder)
    {
        self.auxiliaryNumberOrder = [[NSMutableArray alloc] initWithCapacity:8];
    }
    
    [self.auxiliaryNumberLabels setObject:label forKey:number];
    [self.auxiliaryNumberOrder addObject:number];
}

- (SAVEntityEvent)eventForCommand:(NSString *)command
{
    SAVEntityEvent event = SAVEntityEvent_Unknown;

    if ([command isEqualToString:SAVPoolEntityCommandEnablePoolHeater])
    {
        event = SAVEntityEvent_EnablePoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDisablePoolHeater])
    {
        event = SAVEntityEvent_DisablePoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandTogglePoolHeater])
    {
        event = SAVEntityEvent_TogglePoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandIncrementPoolHeaterSetpoint])
    {
        event = SAVEntityEvent_IncrementPoolHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDecrementPoolHeaterSetpoint])
    {
        event = SAVEntityEvent_DecrementPoolHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPoolHeaterSetpoint])
    {
        event = SAVEntityEvent_SetPoolHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDisableSecondaryPoolHeater])
    {
        event = SAVEntityEvent_DisableSecondaryPoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandEnableSecondaryPoolHeater])
    {
        event = SAVEntityEvent_EnableSecondaryPoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleSecondaryPoolHeater])
    {
        event = SAVEntityEvent_ToggleSecondaryPoolHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandIncrementPoolHeaterSecondarySetpoint])
    {
        event = SAVEntityEvent_IncrementPoolHeaterSecondarySetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDecrementPoolHeaterSecondarySetpoint])
    {
        event = SAVEntityEvent_DecrementPoolHeaterSecondarySetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPoolHeaterSecondarySetpoint])
    {
        event = SAVEntityEvent_SetPoolHeaterSecondarySetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDisableSolarHeater])
    {
        event = SAVEntityEvent_DisableSolarHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandEnableSolarHeater])
    {
        event = SAVEntityEvent_EnableSolarHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleSolarHeater])
    {
        event = SAVEntityEvent_ToggleSolarHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDisableSpaHeater])
    {
        event = SAVEntityEvent_DisableSpaHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandEnableSpaHeater])
    {
        event = SAVEntityEvent_EnableSpaHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleSpaHeater])
    {
        event = SAVEntityEvent_ToggleSpaHeater;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandIncrementSpaHeaterSetpoint])
    {
        event = SAVEntityEvent_IncrementSpaHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandDecrementSpaHeaterSetpoint])
    {
        event = SAVEntityEvent_DecrementSpaHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetSpaHeaterSetpoint])
    {
        event = SAVEntityEvent_SetSpaHeaterSetpoint;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPumpModeOn])
    {
        event = SAVEntityEvent_SetPumpModeOn;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPumpModeOff])
    {
        event = SAVEntityEvent_SetPumpModeOff;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandTogglePumpMode])
    {
        event = SAVEntityEvent_TogglePumpMode;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPumpSpeedHigh])
    {
        event = SAVEntityEvent_SetPumpSpeedHigh;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetPumpSpeedLow])
    {
        event = SAVEntityEvent_SetPumpSpeedLow;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandTogglePumpSpeed])
    {
        event = SAVEntityEvent_TogglePumpSpeed;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetWaterfallModeOn])
    {
        event = SAVEntityEvent_SetWaterfallModeOn;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetWaterfallModeOff])
    {
        event = SAVEntityEvent_SetWaterfallModeOff;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleWaterfallMode])
    {
        event = SAVEntityEvent_ToggleWaterfallMode;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetSpaModeOn])
    {
        event = SAVEntityEvent_SetSpaModeOn;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetSpaModeOff])
    {
        event = SAVEntityEvent_SetSpaModeOff;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleSpaMode])
    {
        event = SAVEntityEvent_ToggleSpaMode;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetCleaningSystemOn])
    {
        event = SAVEntityEvent_SetCleaningSystemOn;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandSetCleaningSystemOff])
    {
        event = SAVEntityEvent_SetCleaningSystemOff;
    }
    else if ([command isEqualToString:SAVPoolEntityCommandToggleCleaningSystem])
    {
        event = SAVEntityEvent_ToggleCleaningSystem;
    }

    return event;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    NSMutableDictionary *requestArgs = [NSMutableDictionary dictionaryWithDictionary:serviceRequest.requestArguments];
    serviceRequest.requestArguments = requestArgs;
    NSArray *zoneNameList = [[Savant data] zonesWithService:self.service];
    serviceRequest.zoneName = [zoneNameList firstObject];

    switch (event)
    {
        case SAVEntityEvent_EnablePoolHeater:
            serviceRequest.request = SAVPoolEntityCommandEnablePoolHeater;
            break;
        case SAVEntityEvent_DisablePoolHeater:
            serviceRequest.request = SAVPoolEntityCommandDisablePoolHeater;
            break;
        case SAVEntityEvent_TogglePoolHeater:
            serviceRequest.request = SAVPoolEntityCommandTogglePoolHeater;
            break;
        case SAVEntityEvent_IncrementPoolHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandIncrementPoolHeaterSetpoint;
            break;
        case SAVEntityEvent_DecrementPoolHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandDecrementPoolHeaterSetpoint;
            break;
        case SAVEntityEvent_SetPoolHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandSetPoolHeaterSetpoint;
            if (value)
            {
                requestArgs[@"PoolHeaterSetpoint"] = value;
            }
            break;
        case SAVEntityEvent_DisableSecondaryPoolHeater:
            serviceRequest.request = SAVPoolEntityCommandDisableSecondaryPoolHeater;
            break;
        case SAVEntityEvent_EnableSecondaryPoolHeater:
            serviceRequest.request = SAVPoolEntityCommandEnableSecondaryPoolHeater;
            break;
        case SAVEntityEvent_ToggleSecondaryPoolHeater:
            serviceRequest.request = SAVPoolEntityCommandToggleSecondaryPoolHeater;
            break;
        case SAVEntityEvent_IncrementPoolHeaterSecondarySetpoint:
            serviceRequest.request = SAVPoolEntityCommandIncrementPoolHeaterSecondarySetpoint;
            break;
        case SAVEntityEvent_DecrementPoolHeaterSecondarySetpoint:
            serviceRequest.request = SAVPoolEntityCommandDecrementPoolHeaterSecondarySetpoint;
            break;
        case SAVEntityEvent_SetPoolHeaterSecondarySetpoint:
            serviceRequest.request = SAVPoolEntityCommandSetPoolHeaterSecondarySetpoint;
            if (value)
            {
                requestArgs[@"PoolHeaterSecondarySetpoint"] = value;
            }
            break;
        case SAVEntityEvent_DisableSolarHeater:
            serviceRequest.request = SAVPoolEntityCommandDisableSolarHeater;
            break;
        case SAVEntityEvent_EnableSolarHeater:
            serviceRequest.request = SAVPoolEntityCommandEnableSolarHeater;
            break;
        case SAVEntityEvent_ToggleSolarHeater:
            serviceRequest.request = SAVPoolEntityCommandToggleSolarHeater;
            break;
        case SAVEntityEvent_DisableSpaHeater:
            serviceRequest.request = SAVPoolEntityCommandDisableSpaHeater;
            break;
        case SAVEntityEvent_EnableSpaHeater:
            serviceRequest.request = SAVPoolEntityCommandEnableSpaHeater;
            break;
        case SAVEntityEvent_ToggleSpaHeater:
            serviceRequest.request = SAVPoolEntityCommandToggleSpaHeater;
            break;
        case SAVEntityEvent_IncrementSpaHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandIncrementSpaHeaterSetpoint;
            break;
        case SAVEntityEvent_DecrementSpaHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandDecrementSpaHeaterSetpoint;
            break;
        case SAVEntityEvent_SetSpaHeaterSetpoint:
            serviceRequest.request = SAVPoolEntityCommandSetSpaHeaterSetpoint;
            if (value)
            {
                requestArgs[@"SpaHeaterSetpoint"] = value;
            }
            break;
        case SAVEntityEvent_SetPumpModeOn:
            serviceRequest.request = SAVPoolEntityCommandSetPumpModeOn;
            break;
        case SAVEntityEvent_SetPumpModeOff:
            serviceRequest.request = SAVPoolEntityCommandSetPumpModeOff;
            break;
        case SAVEntityEvent_TogglePumpMode:
            serviceRequest.request = SAVPoolEntityCommandTogglePumpMode;
            break;
        case SAVEntityEvent_SetPumpSpeedHigh:
            serviceRequest.request = SAVPoolEntityCommandSetPumpSpeedHigh;
            break;
        case SAVEntityEvent_SetPumpSpeedLow:
            serviceRequest.request = SAVPoolEntityCommandSetPumpSpeedLow;
            break;
        case SAVEntityEvent_TogglePumpSpeed:
            serviceRequest.request = SAVPoolEntityCommandTogglePumpSpeed;
            break;
        case SAVEntityEvent_SetWaterfallModeOn:
            serviceRequest.request = SAVPoolEntityCommandSetWaterfallModeOn;
            break;
        case SAVEntityEvent_SetWaterfallModeOff:
            serviceRequest.request = SAVPoolEntityCommandSetWaterfallModeOff;
            break;
        case SAVEntityEvent_ToggleWaterfallMode:
            serviceRequest.request = SAVPoolEntityCommandToggleWaterfallMode;
            break;
        case SAVEntityEvent_SetSpaModeOn:
            serviceRequest.request = SAVPoolEntityCommandSetSpaModeOn;
            break;
        case SAVEntityEvent_SetSpaModeOff:
            serviceRequest.request = SAVPoolEntityCommandSetSpaModeOff;
            break;
        case SAVEntityEvent_ToggleSpaMode:
            serviceRequest.request = SAVPoolEntityCommandToggleSpaMode;
            break;
        case SAVEntityEvent_SetCleaningSystemOn:
            serviceRequest.request = SAVPoolEntityCommandSetCleaningSystemOn;
            break;
        case SAVEntityEvent_SetCleaningSystemOff:
            serviceRequest.request = SAVPoolEntityCommandSetCleaningSystemOff;
            break;
        case SAVEntityEvent_ToggleCleaningSystem:
            serviceRequest.request = SAVPoolEntityCommandToggleCleaningSystem;
            break;
        default:
            RPMLogErr(@"Unexpected event type for POOL entity %ld", (long)event);
            break;
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (NSString *)currentTemperatureState
{
    return [NSString stringWithFormat:@"%@.ThermostatCurrentTemperature.%@", self.stateScope, self.stateSuffix];
}

- (NSArray *)states
{
    if (!_states)
    {
        NSMutableArray *mutableStates = [NSMutableArray array];
        
        NSMutableArray *stateNames = [@[
                                        // Heat States
                                        SAVPoolEntityStatePoolHeaterMode,
                                        SAVPoolEntityStatePoolHeaterSetpoint,
                                        SAVPoolEntityStatePoolTemperature,
                                        SAVPoolEntityStateIsPoolHeaterOn,
                                        // Heat secondary
                                        SAVPoolEntityStateSecondaryPoolHeaterMode,
                                        SAVPoolEntityStatePoolHeaterSecondarySetpoint,
                                        SAVPoolEntityStateIsSecondaryPoolHeaterMode,
                                        //solar Heat Commands
                                        SAVPoolEntityStateSolarHeaterMode,
                                        SAVPoolEntityStateSolarHeaterTemperature,
                                        SAVPoolEntityStateIsSolarHeaterOn,
                                        //spa heater
                                        SAVPoolEntityStateSpaHeaterMode,
                                        SAVPoolEntityStateSpaHeaterSetpoint,
                                        SAVPoolEntityStateSpaTemperature,
                                        SAVPoolEntityStateIsSpaHeaterOn,
                                        //other temp states
                                        SAVPoolEntityStateAirTemperature,
                                        SAVPoolEntityStateTemperatureUnits,
                                        
                                        //Pump states
                                        SAVPoolEntityStatePumpMode,
                                        SAVPoolEntityStatePumpSpeed,
                                        SAVPoolEntityStateIsPumpModeOn,
                                        //spa modes
                                        SAVPoolEntityStateSpaMode,
                                        SAVPoolEntityStateIsSpaModeOn,
                                        //water fall
                                        SAVPoolEntityStateCurentWaterfallMode,
                                        SAVPoolEntityStateWaterfallMode,
                                        SAVPoolEntityStateIsWaterfallModeOn,
                                        //non standard
                                        //cleaning
                                        SAVPoolEntityStateCleaningSystemMode,
                                        SAVPoolEntityStateIsCleaningSystemModeOn,
                                        //non standard
                                        //opmode
                                        SAVPoolEntityStateOpmode,
                                        
                                        //Auxiliary
                                        SAVPoolEntityStateCurrentAuxiliaryState,
                                        SAVPoolEntityStateCurrentExtraAuxiliaryState,
                                        SAVPoolEntityStateIsAuxiliaryOn
                                        ] mutableCopy];
        
        for (NSString *auxKey in [self.auxiliaryNumberLabels allKeys])
        {
            NSString *isAuxOnState = [NSString stringWithFormat:@"%@%@%@", SAVPoolEntityStateIsAuxiliaryOnPrefix, auxKey, SAVPoolEntityStateIsAuxiliaryOnSuffix];
            NSString *currentAuxiliaryState = [NSString stringWithFormat:@"%@%@%@", SAVPoolEntityStateAuxiliaryPrefix, auxKey, SAVPoolEntityStateCurrentAuxiliaryStateSuffix];
            [stateNames addObjectsFromArray:@[isAuxOnState, currentAuxiliaryState]];
        }

        for (NSString *stateName in stateNames)
        {
            [mutableStates addObject:[self stateFromStateName:stateName]];
        }
        _states = [mutableStates copy];
    }

    return _states;
}

- (NSString *)stateFromType:(SAVEntityState)type
{
    NSString *state = nil;

    switch (type)
    {
        case SAVEntityState_PoolHeaterMode:
            state = [self stateFromStateName:SAVPoolEntityStatePoolHeaterMode];
            break;
        case SAVEntityState_PoolHeaterSetpoint:
            state = [self stateFromStateName:SAVPoolEntityStatePoolHeaterSetpoint];
            break;
        case SAVEntityState_PoolTemperature:
            state = [self stateFromStateName:SAVPoolEntityStatePoolTemperature];
            break;
        case SAVEntityState_IsPoolHeaterOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsPoolHeaterOn];
            break;
        case SAVEntityState_SecondaryPoolHeaterMode:
            state = [self stateFromStateName:SAVPoolEntityStateSecondaryPoolHeaterMode];
            break;
        case SAVEntityState_PoolHeaterSecondarySetpoint:
            state = [self stateFromStateName:SAVPoolEntityStatePoolHeaterSecondarySetpoint];
            break;
        case SAVEntityState_IsSecondaryPoolHeaterMode:
            state = [self stateFromStateName:SAVPoolEntityStateIsSecondaryPoolHeaterMode];
            break;
        case SAVEntityState_SolarHeaterMode:
            state = [self stateFromStateName:SAVPoolEntityStateSolarHeaterMode];
            break;
        case SAVEntityState_SolarHeaterTemperature:
            state = [self stateFromStateName:SAVPoolEntityStateSolarHeaterTemperature];
            break;
        case SAVEntityState_IsSolarHeaterOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsSolarHeaterOn];
            break;
        case SAVEntityState_SpaHeaterMode:
            state = [self stateFromStateName:SAVPoolEntityStateSpaHeaterMode];
            break;
        case SAVEntityState_SpaHeaterSetpoint:
            state = [self stateFromStateName:SAVPoolEntityStateSpaHeaterSetpoint];
            break;
        case SAVEntityState_SpaTemperature:
            state = [self stateFromStateName:SAVPoolEntityStateSpaTemperature];
            break;
        case SAVEntityState_IsSpaHeaterOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsSpaHeaterOn];
            break;
        case SAVEntityState_AirTemperature:
            state = [self stateFromStateName:SAVPoolEntityStateAirTemperature];
            break;
        case SAVEntityState_TemperatureUnits:
            state = [self stateFromStateName:SAVPoolEntityStateTemperatureUnits];
            break;
        case SAVEntityState_PumpMode:
            state = [self stateFromStateName:SAVPoolEntityStatePumpMode];
            break;
        case SAVEntityState_PumpSpeed:
            state = [self stateFromStateName:SAVPoolEntityStatePumpSpeed];
            break;
        case SAVEntityState_IsPumpModeOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsPumpModeOn];
            break;
        case SAVEntityState_SpaMode:
            state = [self stateFromStateName:SAVPoolEntityStateSpaMode];
            break;
        case SAVEntityState_IsSpaModeOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsSpaModeOn];
            break;
        case SAVEntityState_WaterfallMode:
            state = [self stateFromStateName:SAVPoolEntityStateWaterfallMode];
            break;
        case SAVEntityState_IsWaterfallModeOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsWaterfallModeOn];

            break;
        case SAVEntityState_CleaningSystemMode:
            state = [self stateFromStateName:SAVPoolEntityStateCleaningSystemMode];
            break;
        case SAVEntityState_IsCleaningSystemModeOn:
            state = [self stateFromStateName:SAVPoolEntityStateIsCleaningSystemModeOn];
            break;
        case SAVEntityState_Opmode:
            state = [self stateFromStateName:SAVPoolEntityStateOpmode];
            break;
//        case SAVEntityState_CurrentSchedule:
//            state = [NSString stringWithFormat:@"%@.%@.%@", SAVPoolEntityStateHVACSchedule, self.zoneName, SAVPoolEntityStateAssignedProfile];
//            break;
        default:
            RPMLogErr(@"Unrecognized state type for POOL entity %ld", (long)type);
            break;
    }

    return state;
}

- (SAVEntityState)typeFromState:(NSString *)state
{
    NSString *name = [self nameFromState:state];

    SAVEntityState stateType = SAVEntityState_Unknown;

    if ([name length])
    {
        if ([name isEqualToString:SAVPoolEntityStatePoolHeaterMode])
        {
            stateType = SAVEntityState_PoolHeaterMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStatePoolHeaterSetpoint])
        {
            stateType = SAVEntityState_PoolHeaterSetpoint;
        }
        else if ([name isEqualToString:SAVPoolEntityStatePoolTemperature])
        {
            stateType = SAVEntityState_PoolTemperature;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsPoolHeaterOn])
        {
            stateType = SAVEntityState_IsPoolHeaterOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSecondaryPoolHeaterMode])
        {
            stateType = SAVEntityState_SecondaryPoolHeaterMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStatePoolHeaterSecondarySetpoint])
        {
            stateType = SAVEntityState_PoolHeaterSecondarySetpoint;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsSecondaryPoolHeaterMode])
        {
            stateType = SAVEntityState_IsSecondaryPoolHeaterMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSolarHeaterMode])
        {
            stateType = SAVEntityState_SolarHeaterMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSolarHeaterTemperature])
        {
            stateType = SAVEntityState_SolarHeaterTemperature;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsSolarHeaterOn])
        {
            stateType = SAVEntityState_IsSolarHeaterOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSpaHeaterMode])
        {
            stateType = SAVEntityState_SpaHeaterMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSpaHeaterSetpoint])
        {
            stateType = SAVEntityState_SpaHeaterSetpoint;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSpaTemperature])
        {
            stateType = SAVEntityState_SpaTemperature;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsSpaHeaterOn])
        {
            stateType = SAVEntityState_IsSpaHeaterOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateAirTemperature])
        {
            stateType = SAVEntityState_AirTemperature;
        }
        else if ([name isEqualToString:SAVPoolEntityStateTemperatureUnits])
        {
            stateType = SAVEntityState_TemperatureUnits;
        }
        else if ([name isEqualToString:SAVPoolEntityStatePumpMode])
        {
            stateType = SAVEntityState_PumpMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStatePumpSpeed])
        {
            stateType = SAVEntityState_PumpSpeed;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsPumpModeOn])
        {
            stateType = SAVEntityState_IsPumpModeOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateSpaMode])
        {
            stateType = SAVEntityState_SpaMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsSpaModeOn])
        {
            stateType = SAVEntityState_IsSpaModeOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateCurentWaterfallMode] ||
                 [name isEqualToString:SAVPoolEntityStateWaterfallMode])
        {
            stateType = SAVEntityState_WaterfallMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsWaterfallModeOn])
        {
            stateType = SAVEntityState_IsWaterfallModeOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateCleaningSystemMode])
        {
            stateType = SAVEntityState_CleaningSystemMode;
        }
        else if ([name isEqualToString:SAVPoolEntityStateIsCleaningSystemModeOn])
        {
            stateType = SAVEntityState_IsCleaningSystemModeOn;
        }
        else if ([name isEqualToString:SAVPoolEntityStateOpmode])
        {
            stateType = SAVEntityState_Opmode;
        }
        else if ([name containsString:@"Auxiliary"])
        {
            stateType = [self auxiliaryTypeFromName:name];
        }
    }
    return stateType;
}

- (SAVEntityState)auxiliaryTypeFromName:(NSString *)name
{
    SAVEntityState stateType = SAVEntityState_UnknownAuxiliaryState;
    
    if ([name length])
    {
        if ([name containsString:SAVPoolEntityStateCurrentExtraAuxiliaryState])//don't know what this is for
        {
            stateType = SAVEntityState_CurrentExtraAuxiliaryState;
        }
        else if ([name containsString:SAVPoolEntityStateCurrentAuxiliaryState])
        {
            stateType = SAVEntityState_CurrentAuxiliaryState;
        }
        else if ([name hasPrefix:SAVPoolEntityStateAuxiliaryPrefix])
        {
            if ([name hasSuffix:SAVPoolEntityStateCurrentAuxiliaryStateSuffix])
            {
                stateType = SAVEntityState_CurrentAuxiliaryState;            }
        }
        else if ([name containsString:SAVPoolEntityStateIsAuxiliaryOn])
        {
            stateType = SAVEntityState_AuxiliaryIsAuxiliaryOn;
        }
        else if ([name hasPrefix:SAVPoolEntityStateIsAuxiliaryOnPrefix])
        {
            if ([name hasSuffix:SAVPoolEntityStateIsAuxiliaryOnSuffix])
            {
                stateType = SAVEntityState_AuxiliaryIsAuxiliaryOn;
            }
        }
    }
    return stateType;
}

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    //-------------------------------------------------------------------
    // Only entity type currently
    //-------------------------------------------------------------------
    return SAVEntityType_Pool;
}

- (NSString *)addressKeyPrefix
{
    return @"";
}

- (SAVEntityAddressScheme)addressScheme
{
    return SAVEntityAddressScheme_NoInitial;
}

@end
