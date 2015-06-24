//
//  SAVShadeEntity.m
//  SavantControl
//
//  Created by Nathan Trapp on 5/13/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVShadeEntity.h"
#import "SAVServiceRequest.h"
#import "rpmSharedLogger.h"

//-------------------------------------------------------------------
// Entity Commands
//-------------------------------------------------------------------

// Set Shade Commands
static NSString *SAVHVACEntityCommandShadeUp   = @"ShadeUp";
static NSString *SAVHVACEntityCommandShadeDown = @"ShadeDown";
static NSString *SAVHVACEntityCommandShadeStop = @"ShadeStop";

@implementation SAVShadeEntity

- (SAVEntityType)typeFromString:(NSString *)typeString
{
    SAVEntityType type = SAVEntityType_Unknown;

    if ([typeString isEqualToString:@"Shade"])
    {
        type = SAVEntityType_Shade;
    }
    else if ([typeString isEqualToString:@"Variable"])
    {
        type = SAVEntityType_Variable;
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
        case SAVEntityEvent_ShadeDown:
            if (self.type == SAVEntityType_Shade)
            {
                serviceRequest.request = SAVHVACEntityCommandShadeDown;
            }
            else if (self.type == SAVEntityType_Variable)
            {
                serviceRequest.request = self.shadeSetCommand ? self.shadeSetCommand : self.pressCommand;
                requestArgs[@"ShadeLevel"] = @"0";
            }
            break;
        case SAVEntityEvent_ShadeUp:
            if (self.type == SAVEntityType_Shade)
            {
                serviceRequest.request = SAVHVACEntityCommandShadeUp;
            }
            else if (self.type == SAVEntityType_Variable)
            {
                serviceRequest.request = self.shadeSetCommand ? self.shadeSetCommand : self.pressCommand;
                requestArgs[@"ShadeLevel"] = @"100";
            }
            break;
        case SAVEntityEvent_ShadeSet:
            serviceRequest.request = self.shadeSetCommand ? self.shadeSetCommand : self.pressCommand;
            if (value)
            {
                requestArgs[@"ShadeLevel"] = value;
            }
            break;
        case SAVEntityEvent_ShadeStop:
            serviceRequest.request = SAVHVACEntityCommandShadeStop;
            break;
        default:
            RPMLogErr(@"Unexpected event type for Shade entity %ld", (long)event);
            break;
    }

    if (serviceRequest.request)
    {
        //-------------------------------------------------------------------
        // Add in the standard shade args.
        //-------------------------------------------------------------------
        if (self.fadeTime)
        {
            requestArgs[@"FadeTime"] = self.fadeTime;
        }

        if (self.delayTime)
        {
            requestArgs[@"DelayTime"] = self.delayTime;
        }

        if (self.sceneNumber)
        {
            requestArgs[@"SceneNumber"] = self.sceneNumber;
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
