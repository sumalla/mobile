//
//  SAVHVACEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVHVACEntity.h"
#import "rpmSharedLogger.h"
#import "SAVServiceRequest.h"

//-------------------------------------------------------------------
// Entity Commands
//-------------------------------------------------------------------

// Cool Commands
static NSString *SAVHVACEntityCommandCoolUp   = @"IncreaseCoolPointTemperature";
static NSString *SAVHVACEntityCommandCoolDown = @"DecreaseCoolPointTemperature";
static NSString *SAVHVACEntityCommandCoolSet  = @"SetCoolPointTemperature";

// Heat Commands
static NSString *SAVHVACEntityCommandHeatUp   = @"IncreaseHeatPointTemperature";
static NSString *SAVHVACEntityCommandHeatDown = @"DecreaseHeatPointTemperature";
static NSString *SAVHVACEntityCommandHeatSet  = @"SetHeatPointTemperature";

// Single Set point Temperature Commands
static NSString *SAVHVACEntityCommandSingleTempUp   = @"IncreaseHeatPointTemperature";
static NSString *SAVHVACEntityCommandSingleTempDown = @"DecreaseHeatPointTemperature";
static NSString *SAVHVACEntityCommandSingleTempSet  = @"SetHeatPointTemperature";

// Auto Temperature Commands
static NSString *SAVHVACEntityCommandAutoTempUp = @"IncreaseTemperature";
static NSString *SAVHVACEntityCommandAutoTempDown = @"DecreaseTemperature";
static NSString *SAVHVACEntityCommandAutoTempSet = @"SetTemperature";

// Humidify Commands
static NSString *SAVHVACEntityCommandHumidifyUp   = @"IncreaseHumidifyPoint";
static NSString *SAVHVACEntityCommandHumidifyDown = @"DecreaseHumidifyPoint";
static NSString *SAVHVACEntityCommandHumidifySet  = @"SetHumidifyPoint";

// Dehumidify Commands
static NSString *SAVHVACEntityCommandDehumidifyUp   = @"IncreaseDehumidifyPoint";
static NSString *SAVHVACEntityCommandDehumidifyDown = @"DecreaseDehumidifyPoint";
static NSString *SAVHVACEntityCommandDehumidifySet  = @"SetDehumidifyPoint";

// Single Set point Humidity Commands
static NSString *SAVHVACEntityCommandSingleHumidityUp   = @"IncreaseHumiditySetPoint";
static NSString *SAVHVACEntityCommandSingleHumidityDown = @"DecreaseHumiditySetPoint";
static NSString *SAVHVACEntityCommandSingleHumiditySet  = @"SetHumiditySetPoint";

// Fan Commands
static NSString *SAVHVACEntityCommandFanAuto = @"SetFanModeAuto";
static NSString *SAVHVACEntityCommandFanOn   = @"SetFanModeOn";
static NSString *SAVHVACEntityCommandFanOff  = @"SetFanModeOff";

static NSString *SAVHVACEntityCommandFanSpeedAuto     = @"SetFanSpeedAuto";
static NSString *SAVHVACEntityCommandFanSpeedLow      = @"SetFanSpeedLow";
static NSString *SAVHVACEntityCommandFanSpeedMidLow   = @"SetFanSpeedMidLow";
static NSString *SAVHVACEntityCommandFanSpeedMid      = @"SetFanSpeedMid";
static NSString *SAVHVACEntityCommandFanSpeedMidHigh  = @"SetFanSpeedMidHigh";
static NSString *SAVHVACEntityCommandFanSpeedHigh     = @"SetFanSpeedHigh";

// Mode Commands
static NSString *SAVHVACEntityCommandModeAuto = @"SetHVACModeAuto";
static NSString *SAVHVACEntityCommandModeCool = @"SetHVACModeCool";
static NSString *SAVHVACEntityCommandModeHeat = @"SetHVACModeHeat";
static NSString *SAVHVACEntityCommandModeOff  = @"SetHVACModeOff";

// Humidity Commands
static NSString *SAVHVACEntityCommandHumidityModeAuto         = @"SetHVACModeHumidityAuto";//not a real command YET!!!
static NSString *SAVHVACEntityCommandHumidityModeHumidity     = @"SetHumidityModeOn";
static NSString *SAVHVACEntityCommandHumidityModeHumidify     = @"SetHVACModeHumidify";
static NSString *SAVHVACEntityCommandHumidityModeDehumidify   = @"SetHVACModeDehumidify";//AC Dehumidify too
static NSString *SAVHVACEntityCommandHumidityModeACDehumidify = @"SetHVACModeDehumidify";//Same as Dehumidify for now
static NSString *SAVHVACEntityCommandHumidityModeOff          = @"SetHumidityModeOff";

//-------------------------------------------------------------------
// Entity State Strings
//-------------------------------------------------------------------

// Heat and Cool
static NSString *SAVHVACEntityStateCurrentCoolPoint = @"ThermostatCurrentCoolPoint";
static NSString *SAVHVACEntityStateCurrentHeatPoint = @"ThermostatCurrentHeatPoint";

// Minimum Deadband
static NSString *SAVHVACEntityStateThermostatAutoMinimumDeadBand = @"ThermostatAutoMinimumDeadBand";

// Current Temp
static NSString *SAVHVACEntityStateCurrentTemperature       = @"ThermostatCurrentTemperature";
static NSString *SAVHVACEntityStateCurrentRemoteTemperature = @"ThermostatCurrentRemoteTemperature";

// Current Set Point
static NSString *SAVHVACEntityStateCurrentSetPoint = @"ThermostatCurrentSetPoint";

// Humidify and Dehumidify
static NSString *SAVHVACEntityStateCurrentHumiditySetPoint = @"ThermostatCurrentHumiditySetPoint";
static NSString *SAVHVACEntityStateCurrentHumidifyPoint    = @"ThermostatCurrentHumidifyPoint";
static NSString *SAVHVACEntityStateCurrentDehumidifyPoint  = @"ThermostatCurrentDehumidifyPoint";

// Current Humidity
static NSString *SAVHVACEntityStateCurrentHumidity = @"ThermostatCurrentHumidity";

// Fan Mode
static NSString *SAVHVACEntityStateCurrentFanModeAuto = @"IsThermostatCurrentFanModeAuto";
static NSString *SAVHVACEntityStateCurrentFanModeOn   = @"IsThermostatCurrentFanModeOn";
static NSString *SAVHVACEntityStateCurrentFanModeOff  = @"IsThermostatCurrentFanModeOff";
static NSString *SAVHVACEntityStateFanMode            = @"ThermostatFanMode";

static NSString *SAVHVACEntityStateFanSpeed           = @"ThermostatCurrentFanSpeed";
static NSString *SAVHVACEntityStateFanSpeedOff        = @"IsCurrentFanSpeedOff";
static NSString *SAVHVACEntityStateFanSpeedLow        = @"IsCurrentFanSpeedLow";
static NSString *SAVHVACEntityStateFanSpeedMidLow     = @"IsCurrentFanSpeedMidLow";
static NSString *SAVHVACEntityStateFanSpeedMid        = @"IsCurrentFanSpeedMid";
static NSString *SAVHVACEntityStateFanSpeedMidHigh    = @"IsCurrentFanSpeedMidHigh";
static NSString *SAVHVACEntityStateFanSpeedHigh       = @"IsCurrentFanSpeedHigh";

// HVAC Mode
static NSString *SAVHVACEntityStateIsHVACModeAuto          = @"IsCurrentHVACModeAuto";
static NSString *SAVHVACEntityStateIsHVACModeCool          = @"IsCurrentHVACModeCool";
static NSString *SAVHVACEntityStateIsHVACModeHeat          = @"IsCurrentHVACModeHeat";
static NSString *SAVHVACEntityStateIsHVACModeEmergencyHeat = @"IsCurrentHVACModeEmergencyHeat";
static NSString *SAVHVACEntityStateIsHVACModeOff           = @"IsCurrentHVACModeOff";

static NSString *SAVHVACEntityStateIsDehumidifyModeOn      = @"IsCurrentHVACModeDehumidify";
static NSString *SAVHVACEntityStateIsHumidifyModeOn        = @"IsCurrentHVACModeHumidify";
static NSString *SAVHVACEntityStateIsHumidityModeOn        = @"IsThermostatHumidityModeOn";

static NSString *SAVHVACEntityStateThermostatMode          = @"ThermostatMode";

// Fan Stage on
static NSString *SAVHVACEntityStateIsGRelayEnergized = @"IsGRelayEnergized";

// Staged Heating and Cooling
static NSString *SAVHVACEntityStateIsY1RelayEnergized = @"IsY1RelayEnergized";
static NSString *SAVHVACEntityStateIsW1RelayEnergized = @"IsW1RelayEnergized";
static NSString *SAVHVACEntityStateIsY2RelayEnergized = @"IsY2RelayEnergized";
static NSString *SAVHVACEntityStateIsW2RelayEnergized = @"IsW2RelayEnergized";
static NSString *SAVHVACEntityStateIsW3RelayEnergized = @"IsW3RelayEnergized";

// Schedulings

static NSString *SAVHVACEntityStateHVACSchedule    = @"dis.hvacSchedule";
static NSString *SAVHVACEntityStateAssignedSchedule = @".AssignedSchedule";
static NSString *SAVHVACEntityStateProfiles        = @".Profiles";
static NSString *degreeSymbol = @"\u00B0";

@interface SAVHVACEntity ()
{
    NSArray *_states;
}

@end

@implementation SAVHVACEntity

+ (NSString *)addDegreeSuffix:(NSString *)value
{
    if (!value.length)
    {
        return nil;
    }
    
    value = [self prepNumberStringToAddSuffix:value];
    
    if (![value hasSuffix:degreeSymbol])
    {
        value = [value stringByAppendingString:degreeSymbol];
    }
    
    return value;
}

+ (NSAttributedString *)addDegreeSuffix:(NSString *)value baseFont:(UIFont *)baseFont degreeFont:(UIFont *)degreeFont withDegreeOffset:(float)offset
{
    NSParameterAssert(baseFont);
    NSParameterAssert(degreeFont);

    if (!value.length)
    {
        return nil;
    }

    value = [self prepNumberStringToAddSuffix:value];

    if (![value hasSuffix:degreeSymbol])
    {
        value = [value stringByReplacingOccurrencesOfString:degreeSymbol withString:@""];
    }

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:value attributes:@{NSFontAttributeName: baseFont}];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:degreeSymbol attributes:@{NSBaselineOffsetAttributeName: @(offset),
                                                                                                        NSFontAttributeName: degreeFont}]];
    return [string copy];
}

+ (NSString *)addPercentSuffix:(NSString *)value
{
    if (!value.length)
    {
        return nil;
    }
    
    value = [self prepNumberStringToAddSuffix:value];
    
    if (![value hasSuffix:@"%"])
    {
        value = [value stringByAppendingString:@"%"];
    }
    
    return value;
}

+ (NSString *)prepNumberStringToAddSuffix:(NSString *)value
{
    NSMutableCharacterSet *whiteSpaceAndLetterCharacterSet = [NSMutableCharacterSet whitespaceCharacterSet];
    [whiteSpaceAndLetterCharacterSet formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
    
    //replace letters, spaces
    [[value componentsSeparatedByCharactersInSet:whiteSpaceAndLetterCharacterSet] componentsJoinedByString:@""];
    
    //removes trailing 0 from behind the decimal point and decimal point if there is only 0 behind it
    NSArray *valueArray =  [value componentsSeparatedByString:@"."];
    if ([valueArray count] == 2)
    {
        while ([valueArray[1] hasSuffix:@"0"])
        {
            [valueArray[1] stringByReplacingOccurrencesOfString:@"0" withString:@""];
        }
        if ([valueArray[1] length] > 0)
        {
            value = [NSString stringWithFormat:@"%@.%@", valueArray[0], valueArray[1]];
        }
        else
        {
            value = valueArray[0];
        }
    }
    return value;
}

- (SAVEntityEvent)eventForCommand:(NSString *)command
{
    SAVEntityEvent event = SAVEntityEvent_Unknown;
    
    if ([command isEqualToString:SAVHVACEntityCommandCoolUp])
    {
        event = SAVEntityEvent_CoolUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandCoolDown])
    {
        event = SAVEntityEvent_CoolDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandCoolSet])
    {
        event = SAVEntityEvent_CoolSet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHeatUp])
    {
        event = SAVEntityEvent_HeatUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHeatDown])
    {
        event = SAVEntityEvent_HeatDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHeatSet])
    {
        event = SAVEntityEvent_HeatSet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleTempUp])
    {
        event = SAVEntityEvent_SingleTempUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleTempDown])
    {
        event = SAVEntityEvent_SingleTempDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleTempSet])
    {
        event = SAVEntityEvent_SingleTempSet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidifyUp])
    {
        event = SAVEntityEvent_HumidfyUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidifyDown])
    {
        event = SAVEntityEvent_HumidfyDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidifySet])
    {
        event = SAVEntityEvent_HumidfySet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandDehumidifyUp])
    {
        event = SAVEntityEvent_DehumidfyUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandDehumidifyDown])
    {
        event = SAVEntityEvent_DehumidfyDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandDehumidifySet])
    {
        event = SAVEntityEvent_DehumidfySet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleHumidityUp])
    {
        event = SAVEntityEvent_HumidtyUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleHumidityDown])
    {
        event = SAVEntityEvent_HumidtyDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandSingleHumiditySet])
    {
        event = SAVEntityEvent_HumidtySet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanAuto])
    {
        event = SAVEntityEvent_FanAuto;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanOn])
    {
        event = SAVEntityEvent_FanOn;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanOff])
    {
        event = SAVEntityEvent_FanOff;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedAuto])
    {
        event = SAVEntityEvent_FanSpeedAuto;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedLow])
    {
        event = SAVEntityEvent_FanSpeedLow;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedMidLow])
    {
        event = SAVEntityEvent_FanSpeedMediumLow;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedMid])
    {
        event = SAVEntityEvent_FanSpeedMedium;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedMidHigh])
    {
        event = SAVEntityEvent_FanSpeedMediumHigh;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandFanSpeedHigh])
    {
        event = SAVEntityEvent_FanSpeedHigh;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandModeAuto])
    {
        event = SAVEntityEvent_ModeAuto;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandModeCool])
    {
        event = SAVEntityEvent_ModeCool;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandModeHeat])
    {
        event = SAVEntityEvent_ModeHeat;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandModeOff])
    {
        event = SAVEntityEvent_ModeOff;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandAutoTempUp])
    {
        event = SAVEntityEvent_AutoUp;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandAutoTempDown])
    {
        event = SAVEntityEvent_AutoDown;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandAutoTempSet])
    {
        event = SAVEntityEvent_AutoSet;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeHumidity])
    {
        event = SAVEntityEvent_ModeHumidity;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeAuto])
    {
        event = SAVEntityEvent_ModeHumidityAuto;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeOff])
    {
        event = SAVEntityEvent_ModeHumidityOff;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeHumidify])
    {
        event = SAVEntityEvent_ModeHumidify;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeDehumidify])
    {
        event = SAVEntityEvent_ModeDehumidify;
    }
    else if ([command isEqualToString:SAVHVACEntityCommandHumidityModeACDehumidify])
    {
        event = SAVEntityEvent_ModeACDehumidify;
    }
    
    return event;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    SAVServiceRequest *serviceRequest = self.baseRequest;
    
    NSMutableDictionary *requestArgs = [NSMutableDictionary dictionaryWithDictionary:serviceRequest.requestArguments];
    serviceRequest.requestArguments = requestArgs;
    
    switch (event)
    {
        case SAVEntityEvent_CoolUp:
            serviceRequest.request = SAVHVACEntityCommandCoolUp;
            break;
        case SAVEntityEvent_CoolDown:
            serviceRequest.request = SAVHVACEntityCommandCoolDown;
            break;
        case SAVEntityEvent_CoolSet:
            serviceRequest.request = SAVHVACEntityCommandCoolSet;
            if (value)
            {
                requestArgs[@"CoolPointTemperature"] = value;
            }
            break;
        case SAVEntityEvent_HeatUp:
            serviceRequest.request = SAVHVACEntityCommandHeatUp;
            break;
        case SAVEntityEvent_HeatDown:
            serviceRequest.request = SAVHVACEntityCommandHeatDown;
            break;
        case SAVEntityEvent_HeatSet:
            serviceRequest.request = SAVHVACEntityCommandHeatSet;
            if (value)
            {
                requestArgs[@"HeatPointTemperature"] = value;
            }
            break;
        case SAVEntityEvent_SingleTempUp:
            serviceRequest.request = SAVHVACEntityCommandSingleTempUp;
            break;
        case SAVEntityEvent_SingleTempDown:
            serviceRequest.request = SAVHVACEntityCommandSingleTempDown;
            break;
        case SAVEntityEvent_SingleTempSet:
            serviceRequest.request = SAVHVACEntityCommandSingleTempSet;
            if (value)
            {
                requestArgs[@"HeatPointTemperature"] = value;
            }
            break;
        case SAVEntityEvent_HumidfyUp:
            serviceRequest.request = SAVHVACEntityCommandHumidifyUp;
            break;
        case SAVEntityEvent_HumidfyDown:
            serviceRequest.request = SAVHVACEntityCommandHumidifyDown;
            break;
        case SAVEntityEvent_HumidfySet:
            serviceRequest.request = SAVHVACEntityCommandHumidifySet;
            if (value)
            {
                requestArgs[@"HumidifyPoint"] = value;
            }
            break;
        case SAVEntityEvent_DehumidfyUp:
            serviceRequest.request = SAVHVACEntityCommandDehumidifyUp;
            break;
        case SAVEntityEvent_DehumidfyDown:
            serviceRequest.request = SAVHVACEntityCommandDehumidifyDown;
            break;
        case SAVEntityEvent_DehumidfySet:
            serviceRequest.request = SAVHVACEntityCommandDehumidifySet;
            if (value)
            {
                requestArgs[@"DehumidifyPoint"] = value;
            }
            break;
        case SAVEntityEvent_SingleHumidityUp:
        case SAVEntityEvent_HumidtyUp:
            serviceRequest.request = SAVHVACEntityCommandSingleHumidityUp;
            break;
        case SAVEntityEvent_SingleHumidityDown:
        case SAVEntityEvent_HumidtyDown:
            serviceRequest.request = SAVHVACEntityCommandSingleHumidityDown;
            break;
        case SAVEntityEvent_SingleHumiditySet:
        case SAVEntityEvent_HumidtySet:
            serviceRequest.request = SAVHVACEntityCommandSingleHumiditySet;
            if (value)
            {
                requestArgs[@"HumidityPoint"] = value;
            }
            break;
        case SAVEntityEvent_FanAuto:
            serviceRequest.request = SAVHVACEntityCommandFanAuto;
            break;
        case SAVEntityEvent_FanOn:
            serviceRequest.request = SAVHVACEntityCommandFanOn;
            break;
        case SAVEntityEvent_FanOff:
            serviceRequest.request = SAVHVACEntityCommandFanOff;
            break;
        case SAVEntityEvent_FanSpeedAuto:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedAuto;
            break;
        case SAVEntityEvent_FanSpeedLow:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedLow;
            break;
        case SAVEntityEvent_FanSpeedMediumLow:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedMidLow;
            break;
        case SAVEntityEvent_FanSpeedMedium:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedMid;
            break;
        case SAVEntityEvent_FanSpeedMediumHigh:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedMidHigh;
            break;
        case SAVEntityEvent_FanSpeedHigh:
            serviceRequest.request = SAVHVACEntityCommandFanSpeedHigh;
            break;
        case SAVEntityEvent_ModeAuto:
            serviceRequest.request = SAVHVACEntityCommandModeAuto;
            break;
        case SAVEntityEvent_ModeCool:
            serviceRequest.request = SAVHVACEntityCommandModeCool;
            break;
        case SAVEntityEvent_ModeHeat:
            serviceRequest.request = SAVHVACEntityCommandModeHeat;
            break;
        case SAVEntityEvent_ModeOff:
            serviceRequest.request = SAVHVACEntityCommandModeOff;
            break;
        case SAVEntityEvent_AutoUp:
            serviceRequest.request = SAVHVACEntityCommandAutoTempUp;
            break;
        case SAVEntityEvent_AutoDown:
            serviceRequest.request = SAVHVACEntityCommandAutoTempDown;
            break;
        case SAVEntityEvent_AutoSet:
            serviceRequest.request = SAVHVACEntityCommandAutoTempSet;
            if (value)
            {
                requestArgs[@"Temperature"] = value;
            }
            break;
        case SAVEntityEvent_ModeHumidity:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeHumidity;
            break;
        case SAVEntityEvent_ModeHumidityAuto:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeAuto;
            break;
        case SAVEntityEvent_ModeHumidityOff:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeOff;
            break;
        case SAVEntityEvent_ModeHumidify:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeHumidify;
            break;
        case SAVEntityEvent_ModeDehumidify:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeDehumidify;
            break;
        case SAVEntityEvent_ModeACDehumidify:
            serviceRequest.request = SAVHVACEntityCommandHumidityModeACDehumidify;
            break;
        default:
            RPMLogErr(@"Unexpected event type for HVAC entity %ld", (long)event);
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
        
        NSArray *stateNames = @[
                                // Heat and Cool
                                SAVHVACEntityStateCurrentCoolPoint,
                                SAVHVACEntityStateCurrentHeatPoint,
                                
                                // Current Temp
                                SAVHVACEntityStateCurrentTemperature,
                                SAVHVACEntityStateCurrentRemoteTemperature,
                                
                                // Humidify and Dehumidify
                                SAVHVACEntityStateCurrentHumiditySetPoint,
                                SAVHVACEntityStateCurrentHumidifyPoint,
                                SAVHVACEntityStateCurrentDehumidifyPoint,
                                
                                // Current Humidity
                                SAVHVACEntityStateCurrentHumidity,
                                
                                // Fan Mode
                                SAVHVACEntityStateCurrentFanModeAuto,
                                SAVHVACEntityStateCurrentFanModeOn,
                                SAVHVACEntityStateCurrentFanModeOff,
                                SAVHVACEntityStateFanMode,
                                
                                // Fan Speed
                                SAVHVACEntityStateFanSpeed,
                                SAVHVACEntityStateFanSpeedOff,
                                SAVHVACEntityStateFanSpeedLow,
                                SAVHVACEntityStateFanSpeedMidLow,
                                SAVHVACEntityStateFanSpeedMid,
                                SAVHVACEntityStateFanSpeedMidHigh,
                                SAVHVACEntityStateFanSpeedHigh,
                                
                                // HVAC Mode
                                SAVHVACEntityStateIsHVACModeAuto,
                                SAVHVACEntityStateIsHVACModeCool,
                                SAVHVACEntityStateIsHVACModeHeat,
                                SAVHVACEntityStateIsHVACModeEmergencyHeat,
                                SAVHVACEntityStateIsHVACModeOff,
                                
                                SAVHVACEntityStateIsDehumidifyModeOn,
                                SAVHVACEntityStateIsHumidifyModeOn,
                                SAVHVACEntityStateIsHumidityModeOn,
                                
                                SAVHVACEntityStateThermostatMode,
                                
                                // Fan Stage on
                                SAVHVACEntityStateIsGRelayEnergized,
                                
                                // Staged Heating and Cooling
                                SAVHVACEntityStateIsY1RelayEnergized,
                                SAVHVACEntityStateIsW1RelayEnergized,
                                SAVHVACEntityStateIsY2RelayEnergized,
                                SAVHVACEntityStateIsW2RelayEnergized,
                                SAVHVACEntityStateIsW3RelayEnergized,
                                
                                // Min Deadband
                                SAVHVACEntityStateThermostatAutoMinimumDeadBand,
                                
                                SAVHVACEntityStateCurrentSetPoint];
        
        for (NSString *stateName in stateNames)
        {
            [mutableStates addObject:[self stateFromStateName:stateName]];
        }
        
        // Scheduling
        [mutableStates addObject:[NSString stringWithFormat:@"%@.%@%@", SAVHVACEntityStateHVACSchedule, self.zoneName, SAVHVACEntityStateAssignedSchedule]];
        [mutableStates addObject:[SAVHVACEntityStateHVACSchedule stringByAppendingString:SAVHVACEntityStateProfiles]];
        
        _states = [mutableStates copy];
    }
    
    return _states;
}

- (NSString *)stateFromType:(SAVEntityState)type
{
    NSString *state = nil;
    
    switch (type)
    {
        case SAVEntityState_CoolPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentCoolPoint];
            break;
        case SAVEntityState_HeatPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentHeatPoint];
            break;
        case SAVEntityState_CurrentTemp:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentTemperature];
            break;
        case SAVEntityState_RemoteTemp:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentRemoteTemperature];
            break;
        case SAVEntityState_CurrentHumidity:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentHumidity];
            break;
        case SAVEntityState_HumidityPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentHumiditySetPoint];
            break;
        case SAVEntityState_HumidifyPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentHumidifyPoint];
            break;
        case SAVEntityState_DehumidifyPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentDehumidifyPoint];
            break;
        case SAVEntityState_Fanmode:
            state = [self stateFromStateName:SAVHVACEntityStateFanMode];
            break;
        case SAVEntityState_FanmodeAuto:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentFanModeAuto];
            break;
        case SAVEntityState_FanmodeOn:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentFanModeOn];
            break;
        case SAVEntityState_FanmodeOff:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentFanModeOff];
            break;
        case SAVEntityState_ModeAuto:
            state = [self stateFromStateName:SAVHVACEntityStateIsHVACModeAuto];
            break;
        case SAVEntityState_ModeCool:
            state = [self stateFromStateName:SAVHVACEntityStateIsHVACModeCool];
            break;
        case SAVEntityState_ModeHeat:
            state = [self stateFromStateName:SAVHVACEntityStateIsHVACModeHeat];
            break;
        case SAVEntityState_ModeOff:
            state = [self stateFromStateName:SAVHVACEntityStateIsHVACModeOff];
            break;
        case SAVEntityState_ModeHumidity:
            state = [self stateFromStateName:SAVHVACEntityStateIsHumidityModeOn];
            break;
        case SAVEntityState_ModeHumidify:
            state = [self stateFromStateName:SAVHVACEntityStateIsHumidifyModeOn];
            break;
        case SAVEntityState_ModeDehumidify:
        case SAVEntityState_ModeACDehumidify:
            state = [self stateFromStateName:SAVHVACEntityStateIsDehumidifyModeOn];
            break;
        case SAVEntityState_FanSpeedHigh:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedHigh];
            break;
        case SAVEntityState_FanSpeedMediumHigh:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedMidHigh];
            break;
        case SAVEntityState_FanSpeedMedium:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedMid];
            break;
        case SAVEntityState_FanSpeedMediumLow:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedMidLow];
            break;
        case SAVEntityState_FanSpeedLow:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedLow];
            break;
        case SAVEntityState_FanSpeedAuto:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeedOff];
            break;
        case SAVEntityState_FanSpeed:
            state = [self stateFromStateName:SAVHVACEntityStateFanSpeed];
            break;
        case SAVEntityState_Mode:
            state = [self stateFromStateName:SAVHVACEntityStateThermostatMode];
            break;
        case SAVEntityState_FanOn:
            state = [self stateFromStateName:SAVHVACEntityStateIsGRelayEnergized];
            break;
        case SAVEntityState_Stage1Heating:
            state = [self stateFromStateName:SAVHVACEntityStateIsW1RelayEnergized];
            break;
        case SAVEntityState_Stage1Cooling:
            state = [self stateFromStateName:SAVHVACEntityStateIsY1RelayEnergized];
            break;
        case SAVEntityState_Stage2Heating:
            state = [self stateFromStateName:SAVHVACEntityStateIsW2RelayEnergized];
            break;
        case SAVEntityState_Stage2Cooling:
            state = [self stateFromStateName:SAVHVACEntityStateIsY2RelayEnergized];
            break;
        case SAVEntityState_Stage3Heating:
            state = [self stateFromStateName:SAVHVACEntityStateIsW3RelayEnergized];
            break;
        case SAVEntityState_CurrentSchedule:
            state = [NSString stringWithFormat:@"%@.%@%@", SAVHVACEntityStateHVACSchedule, self.zoneName, SAVHVACEntityStateAssignedSchedule];
            break;
        case SAVEntityState_ScheduleList:
            state = [SAVHVACEntityStateHVACSchedule stringByAppendingString:SAVHVACEntityStateProfiles];
            break;
        case SAVEntityState_AutoMinimumDeadband:
            state = [self stateFromStateName:SAVHVACEntityStateThermostatAutoMinimumDeadBand];
            break;
        case SAVEntityState_AutoSetPoint:
            state = [self stateFromStateName:SAVHVACEntityStateCurrentSetPoint];
            break;
        default:
            RPMLogErr(@"Unrecognized state type for HVAC entity %ld", (long)type);
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
        if ([name isEqualToString:SAVHVACEntityStateCurrentCoolPoint])
        {
            stateType = SAVEntityState_CoolPoint;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentHeatPoint])
        {
            stateType = SAVEntityState_HeatPoint;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentTemperature])
        {
            stateType = SAVEntityState_CurrentTemp;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentRemoteTemperature])
        {
            stateType = SAVEntityState_RemoteTemp;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentHumidity])
        {
            stateType = SAVEntityState_CurrentHumidity;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentHumiditySetPoint])
        {
            stateType = SAVEntityState_HumidityPoint;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentHumidifyPoint])
        {
            stateType = SAVEntityState_HumidifyPoint;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentDehumidifyPoint])
        {
            stateType = SAVEntityState_DehumidifyPoint;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanMode])
        {
            stateType = SAVEntityState_Fanmode;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentFanModeAuto])
        {
            stateType = SAVEntityState_FanmodeAuto;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentFanModeOn])
        {
            stateType = SAVEntityState_FanmodeOn;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentFanModeOff])
        {
            stateType = SAVEntityState_FanmodeOff;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedHigh])
        {
            stateType = SAVEntityState_FanSpeedHigh;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedMidHigh])
        {
            stateType = SAVEntityState_FanSpeedMediumHigh;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedMid])
        {
            stateType = SAVEntityState_FanSpeedMedium;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedMidLow])
        {
            stateType = SAVEntityState_FanSpeedMediumLow;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedLow])
        {
            stateType = SAVEntityState_FanSpeedLow;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeedOff])
        {
            stateType = SAVEntityState_FanSpeedAuto;
        }
        else if ([name isEqualToString:SAVHVACEntityStateFanSpeed])
        {
            stateType = SAVEntityState_FanSpeed;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHVACModeAuto])
        {
            stateType = SAVEntityState_ModeAuto;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHVACModeCool])
        {
            stateType = SAVEntityState_ModeCool;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHVACModeHeat])
        {
            stateType = SAVEntityState_ModeHeat;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHVACModeOff])
        {
            stateType = SAVEntityState_ModeOff;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHumidityModeOn])
        {
            stateType = SAVEntityState_ModeHumidity;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHumidityModeOn])
        {
            stateType = SAVEntityState_ModeHumidity;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsHumidifyModeOn])
        {
            stateType = SAVEntityState_ModeHumidify;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsDehumidifyModeOn])
        {
            stateType = SAVEntityState_ModeDehumidify;//SAVEntityState_ModeACDehumidify
        }
        else if ([name isEqualToString:SAVHVACEntityStateThermostatMode])
        {
            stateType = SAVEntityState_Mode;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsGRelayEnergized])
        {
            stateType = SAVEntityState_FanOn;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsW1RelayEnergized])
        {
            stateType = SAVEntityState_Stage1Heating;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsY1RelayEnergized])
        {
            stateType = SAVEntityState_Stage1Cooling;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsW2RelayEnergized])
        {
            stateType = SAVEntityState_Stage2Heating;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsY2RelayEnergized])
        {
            stateType = SAVEntityState_Stage2Cooling;
        }
        else if ([name isEqualToString:SAVHVACEntityStateIsW3RelayEnergized])
        {
            stateType = SAVEntityState_Stage3Heating;
        }
        else if ([name isEqualToString:SAVHVACEntityStateAssignedSchedule])
        {
            stateType = SAVEntityState_CurrentSchedule;
        }
        else if ([name isEqualToString:SAVHVACEntityStateProfiles])
        {
            stateType = SAVEntityState_ScheduleList;
        }
        else if ([name isEqualToString:SAVHVACEntityStateThermostatAutoMinimumDeadBand])
        {
            stateType = SAVEntityState_AutoMinimumDeadband;
        }
        else if ([name isEqualToString:SAVHVACEntityStateCurrentSetPoint])
        {
            stateType = SAVEntityState_AutoSetPoint;
        }
    }
    
    return stateType;
}

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    //-------------------------------------------------------------------
    // Only entity type currently
    //-------------------------------------------------------------------
    return SAVEntityType_Thermostat;
}

- (NSString *)addressKeyPrefix
{
    return @"ThermostatAddress";
}

- (SAVEntityAddressScheme)addressScheme
{
    return SAVEntityAddressScheme_NoInitial;
}

@end
