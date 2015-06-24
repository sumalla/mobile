//
//  SAVSecurityEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVSecurityEntity.h"
#import "SAVService.h"
#import "SAVServiceRequest.h"
#import "rpmSharedLogger.h"

//-------------------------------------------------------------------
// Entity Service Identifiers
//-------------------------------------------------------------------

NSString *const SAVSecurityKeypadServiceID = @"SVC_ENV_SECURITYSYSTEM";
NSString *const SAVSecurityUserServiceID   = @"SVC_ENV_USERLOGIN_SECURITYSYSTEM";

//-------------------------------------------------------------------
// Entity Commands
//-------------------------------------------------------------------

// Number Commands
NSString *const SAVSecurityEntityCommandOne     = @"NumberOne";
NSString *const SAVSecurityEntityCommandTwo     = @"NumberTwo";
NSString *const SAVSecurityEntityCommandThree   = @"NumberThree";
NSString *const SAVSecurityEntityCommandFour    = @"NumberFour";
NSString *const SAVSecurityEntityCommandFive    = @"NumberFive";
NSString *const SAVSecurityEntityCommandSix     = @"NumberSix";
NSString *const SAVSecurityEntityCommandSeven   = @"NumberSeven";
NSString *const SAVSecurityEntityCommandEight   = @"NumberEight";
NSString *const SAVSecurityEntityCommandNine    = @"NumberNine";
NSString *const SAVSecurityEntityCommandZero    = @"NumberZero";
NSString *const SAVSecurityEntityCommandPound   = @"NumberPound";
NSString *const SAVSecurityEntityCommandAsterix = @"NumberAsterix";

// Keypad Commands
NSString *const SAVSecurityEntityCommandPanic         = @"KeypadPanic";
NSString *const SAVSecurityEntityCommandStay          = @"ArmAlarmStay";
NSString *const SAVSecurityEntityCommandAway          = @"ArmAlarmAway";
NSString *const SAVSecurityEntityCommandDisarm        = @"DisarmAlarm";
NSString *const SAVSecurityEntityCommandFire          = @"KeypadFire";
NSString *const SAVSecurityEntityCommandMedical       = @"KeypadMedical";
NSString *const SAVSecurityEntityCommandPolice        = @"KeypadPolice";
NSString *const SAVSecurityEntityCommandLeft          = @"CursorLeft";
NSString *const SAVSecurityEntityCommandRight         = @"CursorRight";
NSString *const SAVSecurityEntityCommandMenu          = @"KeypadMenu";
NSString *const SAVSecurityEntityCommandEndKeypress   = @"EndKeypress";
NSString *const SAVSecurityEntityCommandClearUserCode = @"ClearUserCode";
NSString *const SAVSecurityEntityCommandIncrementUser = @"IncrementUserNumber";
NSString *const SAVSecurityEntityCommandDecrementUser = @"DecrementUserNumber";

//-------------------------------------------------------------------
// Entity State Strings
//-------------------------------------------------------------------

// Sensor States
static NSString *SAVSecurityEntityStateCurrentZoneStatusID = @"ZoneSummary";
static NSString *SAVSecurityEntityStateCurrentZoneStatus   = @"CurrentZoneStatus";
static NSString *SAVSecurityEntityStateIsZoneBypassed      = @"isZoneBypassed";

// Partition States
static NSString *SAVSecurityEntityStateCurrentPartitionStatus       = @"CurrentPartitionStatus";
static NSString *SAVSecurityEntityStateCurrentLCDContentsLine1      = @"CurrentLCDContentsLine1";
static NSString *SAVSecurityEntityStateCurrentLCDContentsLine2      = @"CurrentLCDContentsLine2";
static NSString *SAVSecurityEntityStateCurrentUserAccessCode        = @"CurrentUserAccessCode";
static NSString *SAVSecurityEntityStateCurrentUserNumber            = @"CurrentUserNumber";
static NSString *SAVSecurityEntityStateCurrentPartitionArmingStatus = @"CurrentPartitionArmingStatus";

@implementation SAVSecurityEntity

- (SAVSecurityEntityServiceType)serviceTypeForService:(SAVService *)service
{
    SAVSecurityEntityServiceType serviceType = SAVSecurityEntityServiceType_NotSecurity;

    if ([service.serviceId isEqualToString:SAVSecurityKeypadServiceID])
    {
        serviceType = SAVSecurityEntityServiceType_KeypadSecurity;
    }
    else if ([service.serviceId isEqualToString:SAVSecurityUserServiceID])
    {
        serviceType = SAVSecurityEntityServiceType_UserSecurity;
    }

    return serviceType;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    SAVServiceRequest *serviceRequest = nil;

    switch (self.type)
    {
        case SAVEntityType_Sensor:
            serviceRequest = [self sensorRequestForEvent:event];
            break;
        case SAVEntityType_Partition:
            //--------------------------------------------------
            // Determine if this is a user based system or
            // a keypad emulation system. The commands will be
            // slightly different.
            //--------------------------------------------------
            switch ([self serviceTypeForService:self.service])
        {
            case SAVSecurityEntityServiceType_UserSecurity:
            {
                serviceRequest = [self userSecurityRequestForEvent:event];
                break;
            }
            case SAVSecurityEntityServiceType_KeypadSecurity:
                serviceRequest = [self keypadSecurityRequestForEvent:event];
                break;
            default:
                break;
        }
            break;
        default:
            break;
    }

    return serviceRequest;
}

- (BOOL)isUserSecurity
{
    return ([self serviceTypeForService:self.service] == SAVSecurityEntityServiceType_UserSecurity);
}

- (NSDictionary *)createAddressArguments
{
    NSDictionary *addrArguments = nil;

    switch (self.type)
    {
        case SAVEntityType_Partition:
            if ([self.partition length])
            {
                addrArguments = @{@"PartitionNumber": self.partition};
            }
            break;
        case SAVEntityType_Sensor:
            if ([self.sensor length])
            {
                addrArguments = @{@"ZoneNumber": self.sensor};
            }
            break;
        default:
            break;
    }

    return addrArguments;
}

- (SAVEntityEvent)eventForCommand:(NSString *)command
{
    SAVEntityEvent event = SAVEntityEvent_Unknown;

    if ([command isEqualToString:SAVSecurityEntityCommandOne])
    {
        event = SAVEntityEvent_1;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandTwo])
    {
        event = SAVEntityEvent_2;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandThree])
    {
        event = SAVEntityEvent_3;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandFour])
    {
        event = SAVEntityEvent_4;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandFive])
    {
        event = SAVEntityEvent_5;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandSix])
    {
        event = SAVEntityEvent_6;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandSeven])
    {
        event = SAVEntityEvent_7;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandEight])
    {
        event = SAVEntityEvent_8;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandNine])
    {
        event = SAVEntityEvent_9;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandZero])
    {
        event = SAVEntityEvent_0;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandPound])
    {
        event = SAVEntityEvent_Pound;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandAsterix])
    {
        event = SAVEntityEvent_Star;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandPanic])
    {
        event = SAVEntityEvent_Panic;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandStay])
    {
        event = SAVEntityEvent_Stay;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandAway])
    {
        event = SAVEntityEvent_Away;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandDisarm])
    {
        event = SAVEntityEvent_Disarm;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandFire])
    {
        event = SAVEntityEvent_Fire;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandMedical])
    {
        event = SAVEntityEvent_Medical;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandPolice])
    {
        event = SAVEntityEvent_Police;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandLeft])
    {
        event = SAVEntityEvent_Left;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandRight])
    {
        event = SAVEntityEvent_Right;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandMenu])
    {
        event = SAVEntityEvent_Menu;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandEndKeypress])
    {
        event = SAVEntityEvent_Release;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandClearUserCode])
    {
        event = SAVEntityEvent_Clear;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandIncrementUser])
    {
        event = SAVEntityEvent_UserUp;
    }
    else if ([command isEqualToString:SAVSecurityEntityCommandDecrementUser])
    {
        event = SAVEntityEvent_UserDown;
    }

    return event;
}

- (SAVServiceRequest *)userSecurityRequestForEvent:(SAVEntityEvent)event
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    switch (event)
    {
        case SAVEntityEvent_1:
            serviceRequest.request = SAVSecurityEntityCommandOne;
            break;
        case SAVEntityEvent_2:
            serviceRequest.request = SAVSecurityEntityCommandTwo;
            break;
        case SAVEntityEvent_3:
            serviceRequest.request = SAVSecurityEntityCommandThree;
            break;
        case SAVEntityEvent_4:
            serviceRequest.request = SAVSecurityEntityCommandFour;
            break;
        case SAVEntityEvent_5:
            serviceRequest.request = SAVSecurityEntityCommandFive;
            break;
        case SAVEntityEvent_6:
            serviceRequest.request = SAVSecurityEntityCommandSix;
            break;
        case SAVEntityEvent_7:
            serviceRequest.request = SAVSecurityEntityCommandSeven;
            break;
        case SAVEntityEvent_8:
            serviceRequest.request = SAVSecurityEntityCommandEight;
            break;
        case SAVEntityEvent_9:
            serviceRequest.request = SAVSecurityEntityCommandNine;
            break;
        case SAVEntityEvent_0:
            serviceRequest.request = SAVSecurityEntityCommandZero;
            break;
        case SAVEntityEvent_Clear:
            serviceRequest.request = SAVSecurityEntityCommandClearUserCode;
            break;
        case SAVEntityEvent_Panic:
            serviceRequest.request = SAVSecurityEntityCommandPanic;
            break;
        case SAVEntityEvent_Stay:
            serviceRequest.request = SAVSecurityEntityCommandStay;
            break;
        case SAVEntityEvent_Away:
            serviceRequest.request = SAVSecurityEntityCommandAway;
            break;
        case SAVEntityEvent_Disarm:
            serviceRequest.request = SAVSecurityEntityCommandDisarm;
            break;
        case SAVEntityEvent_Fire:
            serviceRequest.request = SAVSecurityEntityCommandFire;
            break;
        case SAVEntityEvent_Medical:
            serviceRequest.request = SAVSecurityEntityCommandMedical;
            break;
        case SAVEntityEvent_UserUp:
            serviceRequest.request = SAVSecurityEntityCommandIncrementUser;
            break;
        case SAVEntityEvent_UserDown:
            serviceRequest.request = SAVSecurityEntityCommandDecrementUser;
            break;
        case SAVEntityEvent_Release:
            serviceRequest.request = SAVSecurityEntityCommandEndKeypress;
            break;
        default:
            RPMLogErr(@"Unrecognized event %ld for user security", (long)event);
            break;
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (SAVServiceRequest *)keypadSecurityRequestForEvent:(SAVEntityEvent)event
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    switch (event)
    {
        case SAVEntityEvent_1:
            serviceRequest.request = SAVSecurityEntityCommandOne;
            break;
        case SAVEntityEvent_2:
            serviceRequest.request = SAVSecurityEntityCommandTwo;
            break;
        case SAVEntityEvent_3:
            serviceRequest.request = SAVSecurityEntityCommandThree;
            break;
        case SAVEntityEvent_4:
            serviceRequest.request = SAVSecurityEntityCommandFour;
            break;
        case SAVEntityEvent_5:
            serviceRequest.request = SAVSecurityEntityCommandFive;
            break;
        case SAVEntityEvent_6:
            serviceRequest.request = SAVSecurityEntityCommandSix;
            break;
        case SAVEntityEvent_7:
            serviceRequest.request = SAVSecurityEntityCommandSeven;
            break;
        case SAVEntityEvent_8:
            serviceRequest.request = SAVSecurityEntityCommandEight;
            break;
        case SAVEntityEvent_9:
            serviceRequest.request = SAVSecurityEntityCommandNine;
            break;
        case SAVEntityEvent_0:
            serviceRequest.request = SAVSecurityEntityCommandZero;
            break;
        case SAVEntityEvent_Pound:
            serviceRequest.request = SAVSecurityEntityCommandPound;
            break;
        case SAVEntityEvent_Star:
            serviceRequest.request = SAVSecurityEntityCommandAsterix;
            break;
        case SAVEntityEvent_Panic:
            serviceRequest.request = SAVSecurityEntityCommandPanic;
            break;
        case SAVEntityEvent_Stay:
            serviceRequest.request = SAVSecurityEntityCommandStay;
            break;
        case SAVEntityEvent_Away:
            serviceRequest.request = SAVSecurityEntityCommandAway;
            break;
        case SAVEntityEvent_Disarm:
            serviceRequest.request = SAVSecurityEntityCommandDisarm;
            break;
        case SAVEntityEvent_Fire:
            serviceRequest.request = SAVSecurityEntityCommandFire;
            break;
        case SAVEntityEvent_Medical:
            serviceRequest.request = SAVSecurityEntityCommandMedical;
            break;
        case SAVEntityEvent_Police:
            serviceRequest.request = SAVSecurityEntityCommandPolice;
            break;
        case SAVEntityEvent_Left:
            serviceRequest.request = SAVSecurityEntityCommandLeft;
            break;
        case SAVEntityEvent_Right:
            serviceRequest.request = SAVSecurityEntityCommandRight;
            break;
        case SAVEntityEvent_Menu:
            serviceRequest.request = SAVSecurityEntityCommandMenu;
            break;
        case SAVEntityEvent_Release:
            serviceRequest.request = SAVSecurityEntityCommandEndKeypress;
            break;
        default:
            RPMLogErr(@"Unrecognized event %ld for keypad security", (long)event);
            break;
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (SAVServiceRequest *)sensorRequestForEvent:(SAVEntityEvent)event
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    switch (event)
    {
        case SAVEntityEvent_Bypass:
            serviceRequest.request = @"BypassZone";
            break;
        case SAVEntityEvent_Unbypass:
            serviceRequest.request = @"UnBypassZone";
            break;
        default:
            RPMLogErr(@"Unrecognized event %ld for security sensor", (long)event);
            break;
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    SAVEntityType type = SAVEntityType_Unknown;

    if ([typeString isEqualToString:@"Zone"])
    {
        type = SAVEntityType_Sensor;
    }
    else if ([typeString isEqualToString:@"Partition"])
    {
        type = SAVEntityType_Partition;
    }

    return type;
}

- (NSArray *)states
{
    NSMutableArray *states = [NSMutableArray array];

    switch (self.type)
    {
        case SAVEntityType_Partition:
            [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentPartitionStatus]];
            [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentPartitionArmingStatus]];

            //--------------------------------------------------
            // User security systems and keypad systems register
            // for slightly different states.
            //--------------------------------------------------
            if (self.isUserSecurity)
            {
                [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentUserAccessCode]];
                [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentUserNumber]];
            }
            else
            {
                [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentLCDContentsLine1]];
                [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentLCDContentsLine2]];
            }
            break;
        case SAVEntityType_Sensor:
            [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentZoneStatusID]];
            [states addObject:[self stateFromStateName:SAVSecurityEntityStateCurrentZoneStatus]];
            [states addObject:[self stateFromStateName:SAVSecurityEntityStateIsZoneBypassed]];
            break;
        default:
            RPMLogErr(@"Invalid type for security entity");
            states = nil;
            break;
    }

    return states;
}

- (NSString *)stateFromType:(SAVEntityState)type
{
    NSString *state = nil;

    switch (type)
    {
        case SAVEntityState_PartitionStatus:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentPartitionStatus];
            break;
        case SAVEntityState_PartitionArmingStatus:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentPartitionArmingStatus];
            break;
        case SAVEntityState_PartitionMenuLine1:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentLCDContentsLine1];
            break;
        case SAVEntityState_PartitionMenuLine2:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentLCDContentsLine2];
            break;
        case SAVEntityState_PartitionUserAccessCode:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentUserAccessCode];
            break;
        case SAVEntityState_PartitionUserNumber:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentUserNumber];
            break;
        case SAVEntityState_SensorStatus:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentZoneStatusID];
            break;
        case SAVEntityState_SensorDetailedStatus:
            state = [self stateFromStateName:SAVSecurityEntityStateCurrentZoneStatus];
            break;
        case SAVEntityState_SensorBypassToggle:
            state = [self stateFromStateName:SAVSecurityEntityStateIsZoneBypassed];
            break;
        default:
            break;
    }

    return state;
}

- (SAVEntityState)typeFromState:(NSString *)state
{
    NSString *name = [self nameFromState:state];
    SAVEntityState stateType = SAVEntityState_Unknown;

    if ([name isEqualToString:SAVSecurityEntityStateCurrentPartitionStatus])
    {
        stateType = SAVEntityState_PartitionStatus;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentPartitionArmingStatus])
    {
        stateType = SAVEntityState_PartitionArmingStatus;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentLCDContentsLine1])
    {
        stateType = SAVEntityState_PartitionMenuLine1;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentLCDContentsLine2])
    {
        stateType = SAVEntityState_PartitionMenuLine2;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentUserAccessCode])
    {
        stateType = SAVEntityState_PartitionUserAccessCode;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentUserNumber])
    {
        stateType = SAVEntityState_PartitionUserNumber;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentZoneStatusID])
    {
        stateType = SAVEntityState_SensorStatus;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateCurrentZoneStatus])
    {
        stateType = SAVEntityState_SensorDetailedStatus;
    }
    else if ([name isEqualToString:SAVSecurityEntityStateIsZoneBypassed])
    {
        stateType = SAVEntityState_SensorBypassToggle;
    }

    return stateType;
}

- (NSString *)stateSuffix
{
    NSString *suffix = @"";

    switch (self.type)
    {
        case SAVEntityType_Partition:
            if (self.partition)
            {
                suffix = [@"_" stringByAppendingString:self.partition];
            }
            break;
        case SAVEntityType_Sensor:
            if (self.sensor)
            {
                suffix = [@"_" stringByAppendingString:self.sensor];
            }
            break;
        default:
            break;
    }

    return suffix;
}

+ (SAVSecurityEntityArmingStatus)armingStatusForString:(NSString *)armingString
{
    SAVSecurityEntityArmingStatus status = SAVSecurityEntityArmingStatus_Unknown;

    if ([armingString isEqualToString:@"Disarmed"])
    {
        status = SAVSecurityEntityArmingStatus_Disarmed;
    }
    else if ([armingString isEqualToString:@"ArmedAway"])
    {
        status = SAVSecurityEntityArmingStatus_Away;
    }
    else if ([armingString isEqualToString:@"ArmedStay"])
    {
        status = SAVSecurityEntityArmingStatus_Stay;
    }
    else if ([armingString isEqualToString:@"ArmedInstant"])
    {
        status = SAVSecurityEntityArmingStatus_Instant;
    }
    else if ([armingString isEqualToString:@"ArmedVacation"])
    {
        status = SAVSecurityEntityArmingStatus_Vaction;
    }
    else if ([armingString isEqualToString:@"ArmedNightStay"])
    {
        status = SAVSecurityEntityArmingStatus_NightStay;
    }

    return status;
}

@end
