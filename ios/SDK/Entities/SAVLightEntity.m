//
//  SAVLightEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVLightEntity.h"
#import "SAVServiceRequest.h"
#import "rpmSharedLogger.h"
@import Extensions;

@implementation SAVLightEntity

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    SAVEntityType type = SAVEntityType_Unknown;

    if ([typeString isEqualToString:@"Dimmer"])
    {
        type = SAVEntityType_Dimmer;
    }
    else if ([typeString isEqualToString:@"Switch"])
    {
        type = SAVEntityType_Switch;
    }
    else if ([typeString isEqualToString:@"Button"])
    {
        type = SAVEntityType_Button;
    }
    else if ([typeString isEqualToString:@"Scene"])
    {
        type = SAVEntityType_Scene;
    }
    else if ([typeString isEqualToString:@"Hue"])
    {
        type = SAVEntityType_Hue;
    }
    else if ([typeString isEqualToString:@"Fan"])
    {
        type = SAVEntityType_Fan;
    }

    return type;
}

- (SAVServiceRequest *)requestForEvent:(SAVEntityEvent)event value:(id)value
{
    SAVServiceRequest *serviceRequest = self.baseRequest;

    NSMutableDictionary *requestArgs = [NSMutableDictionary dictionaryWithDictionary:serviceRequest.requestArguments];
    serviceRequest.requestArguments = requestArgs;

    switch (event)
    {
        case SAVEntityEvent_Press:
            serviceRequest.request = self.pressCommand;
            break;
        case SAVEntityEvent_Hold:
            serviceRequest.request = self.holdCommand;
            break;
        case SAVEntityEvent_Release:
            serviceRequest.request = self.releaseCommand;
            break;
        case SAVEntityEvent_TogglePress:
            serviceRequest.request = self.togglePressCommand;
            break;
        case SAVEntityEvent_ToggleHold:
            serviceRequest.request = self.toggleHoldCommand;
            break;
        case SAVEntityEvent_ToggleRelease:
            serviceRequest.request = self.toggleReleaseCommand;
            break;
        case SAVEntityEvent_SwitchOn:

            if (self.type == SAVEntityType_Dimmer)
            {
                serviceRequest.request = self.dimmerCommand ? self.dimmerCommand : self.pressCommand;
                requestArgs[@"DimmerLevel"] = @"100";
            }
            else if (self.type == SAVEntityType_Switch)
            {
                serviceRequest.request = self.releaseCommand ? self.releaseCommand : self.pressCommand;

                if ([serviceRequest.request sav_containsString:@"dimmerset" options:NSCaseInsensitiveSearch])
                {
                    requestArgs[@"DimmerLevel"] = @"100";
                }
            }

            break;
        case SAVEntityEvent_SwitchOff:

            if (self.type == SAVEntityType_Dimmer)
            {
                serviceRequest.request = self.dimmerCommand ? self.dimmerCommand : self.pressCommand;
                requestArgs[@"DimmerLevel"] = @"0";
            }
            else
            {
                serviceRequest.request = self.toggleReleaseCommand ? self.toggleReleaseCommand : self.togglePressCommand;

                {
                    requestArgs[@"DimmerLevel"] = @"0";
                }
            }

            break;
        case SAVEntityEvent_Dimmer:
            serviceRequest.request = self.dimmerCommand ? self.dimmerCommand : self.pressCommand;
            if (value)
            {
                requestArgs[@"DimmerLevel"] = value;
            }
            break;
        case SAVEntityEvent_Restore:
            serviceRequest.request = self.restoreCommand;
            break;
        case SAVEntityEvent_FanOff:
        case SAVEntityEvent_FanLow:
        case SAVEntityEvent_FanMedium:
        case SAVEntityEvent_FanHigh:
            serviceRequest.request = @"FanSet";
            requestArgs[@"FanSpeed"] = value;
            break;
        default:
            RPMLogErr(@"Unexpected event type for Lighting entity %ld", (long)event);
            break;
    }

    if (serviceRequest.request)
    {
        //-------------------------------------------------------------------
        // Add in the standard lighting args.
        //-------------------------------------------------------------------
        if (self.fadeTime)
        {
            requestArgs[@"FadeTime"] = self.fadeTime;
        }

        if (self.delayTime)
        {
            requestArgs[@"DelayTime"] = self.delayTime;
        }
    }

    return serviceRequest.request ? serviceRequest : nil;
}

- (NSArray *)states
{
    if (!self.stateName.length)
    {
        return nil;
    }
    return @[self.stateName];
}

@end
