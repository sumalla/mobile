//
//  SAVScenesDemoRouter.m
//  SavantControl
//
//  Created by Nathan Trapp on 7/22/14.
//  Copyright (c) 2014 Savant Systems, LLC. All rights reserved.
//

#import "SAVScenesDemoRouter.h"
#import "SAVScene.h"
#import "Savant.h"
#import "SAVControlPrivate.h"

@import Extensions;

static NSString *const SAVScene_UpdateScene        = @"UpdateScene";
static NSString *const SAVScene_CreateScene        = @"CreateScene";
static NSString *const SAVScene_ActivateSchedule   = @"ActivateSchedule";
static NSString *const SAVScene_DeactivateSchedule = @"DeactivateSchedule";
static NSString *const SAVScene_RemoveScene        = @"RemoveScene";
static NSString *const SAVScene_FetchScene         = @"FetchScene";
static NSString *const SAVScene_CaptureScene       = @"CaptureScene";
static NSString *const SAVScene_OrderScenes        = @"OrderScenes";

static NSString *const SAVScene_State_Scenes        = @"scenes";
static NSString *const SAVScene_State_SceneSettings = @"sceneSettings";

static NSString *const SAVSceneIDKey     = @"id";
static NSString *const SAVSceneActiveKey = @"isActive";

@interface SAVScenesDemoRouter ()

@property NSMutableDictionary *scenes;
@property NSMutableArray *scenesOrder;

@end

@implementation SAVScenesDemoRouter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self generateDemoScenes];
    }
    return self;
}

- (BOOL)handleDISRequest:(SAVDISRequest *)request
{
    BOOL shouldHandle = NO;

    id response = nil;

    if ([request.request isEqualToString:@"register"])
    {
        NSString *state = request.arguments[SAVMESSAGE_STATE_KEY];

        if ([state isEqualToString:SAVScene_State_Scenes])
        {
            response = [self fetchSceneList];
        }
    }
    else if ([request.request isEqualToString:SAVScene_CreateScene])
    {
        response = [self addScene:request.arguments];
    }
    else if ([request.request isEqualToString:SAVScene_RemoveScene])
    {
        response = [self removeScene:request.arguments[SAVSceneIDKey]];
    }
    else if ([request.request isEqualToString:SAVScene_ActivateSchedule])
    {
        response = [self activateScene:request.arguments[SAVSceneIDKey] activate:YES];
    }
    else if ([request.request isEqualToString:SAVScene_DeactivateSchedule])
    {
        response = [self activateScene:request.arguments[SAVSceneIDKey] activate:NO];
    }
    else if ([request.request isEqualToString:SAVScene_UpdateScene])
    {
        response = [self saveSceneSettings:request.arguments];
    }
    else if ([request.request isEqualToString:SAVScene_FetchScene])
    {
        response = [self fetchSceneSettings:request.arguments[SAVSceneIDKey]];
    }
    else if ([request.request isEqualToString:SAVScene_CaptureScene])
    {
        response = [self captureSceneSettings];
    }
    else if ([request.request isEqualToString:SAVScene_OrderScenes])
    {
        if (request.arguments[@"order"])
        {
            self.scenesOrder = [request.arguments[@"order"] mutableCopy];
            response = [self fetchSceneList];
        }
    }

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

#pragma mark -

- (SAVDISFeedback *)activateScene:(NSString *)identifier activate:(BOOL)activate
{
    SAVScene *scene = self.scenes[identifier];
    scene.active = activate;

    if (scene.scheduled)
    {
        self.scenes[identifier] = scene;
    }

    return [self fetchSceneList];
}

- (SAVDISFeedback *)addScene:(NSDictionary *)settings
{
    return [self saveSceneSettings:settings];
}

- (SAVDISFeedback *)removeScene:(NSString *)identifier
{
    [self.scenes removeObjectForKey:identifier];
    [self.scenesOrder removeObject:identifier];

    return [self fetchSceneList];
}

- (SAVDISFeedback *)fetchSceneList
{
    SAVDISFeedback *sceneList = [[SAVDISFeedback alloc] init];
    sceneList.state = SAVScene_State_Scenes;

    NSMutableArray *scenes = [NSMutableArray array];

    for (NSString *identifier in self.scenesOrder)
    {
        SAVScene *scene = self.scenes[identifier];

        if (scene)
        {
            NSMutableDictionary *sceneDict = [[scene dictionaryRepresentation] mutableCopy];
            //            NSMutableDictionary *sceneDict = [NSMutableDictionary dictionaryWithDictionary:@{@"id": scene.identifier,
            //                                                                                             @"name": scene.name,
            //                                                                                             @"isScheduled": @(scene.isScheduled),
            //                                                                                             @"isActive": @(scene.isActive),
            //                                                                                             @"hasCustomImage": @(scene.hasCustomImage)}];

            if (scene.imageKey)
            {
                sceneDict[@"imageKey"] = scene.imageKey;
            }

            [scenes addObject:sceneDict];
        }
    }

    sceneList.value = scenes;

    return sceneList;
}

- (SAVDISResults *)captureSceneSettings
{
    SAVDISResults *sceneSettings = [[SAVDISResults alloc] init];

    NSDictionary *avPower = @{@"Living Room": @{@"Living Room-Cable 1-Cable_box-1-SVC_AV_TV": @1},
                              @"Sitting Room": @{@"Sitting Room-AppleTV-Media_server-1-SVC_AV_LIVEMEDIAQUERY_DAAPAUDIO": @1},
                              @"Kitchen": @{@"Kitchen-All Radio-Radio_2-1-SVC_AV_SATELLITERADIO": @1},
                              @"Dining Room": @{@"Dining Room-SMS-Player_B-1-SVC_AV_LIVEMEDIAQUERY_SAVANTMEDIAAUDIO_RADIO_PANDORA": @1}};
    NSDictionary *volume = @{@"Living Room": @15,
                             @"Sitting Room": @25,
                             @"Kitchen": @5,
                             @"Dining Room": @10};

    SAVScene *capturedScene = [[SAVScene alloc] init];
    capturedScene.avPower = [avPower mutableCopy];
    capturedScene.lightingOff = [@[@"Sitting Room", @"Dining Room", @"Patio"] mutableCopy];
    capturedScene.volume = [volume mutableCopy];

    //-------------------------------------------------------------------
    // Add AV Scene Services
    //-------------------------------------------------------------------
    for (NSDictionary *serviceDict in [avPower allValues])
    {
        for (NSString *serviceString in [serviceDict allKeys])
        {
            SAVService *service = [[SAVService alloc] initWithString:serviceString];
            SAVSceneService *sceneService = [capturedScene sceneServiceForService:service];

            [capturedScene addAVSceneService:sceneService];

            [sceneService.rooms addObject:service.zoneName];
        }
    }

    //-------------------------------------------------------------------
    // Add lighting scene service
    //-------------------------------------------------------------------
    NSDictionary *lightingStates = @{@"IsLED3On_1_7": @0,
                                     @"DimmerLevel_1_49_4_0": @100,
                                     @"DimmerLevel_2_4_2_6": @0,
                                     @"IsLED3On_1_8": @0,
                                     @"DimmerLevel_2_3_1_8": @0,
                                     @"DimmerLevel_2_3_2_1": @45,
                                     @"DimmerLevel_1_5_3_0": @20,
                                     @"DimmerLevel_2_32_4_0": @0,
                                     @"DimmerLevel_2_3_2_7": @0,
                                     @"DimmerLevel_2_28_3_0": @2,
                                     @"DimmerLevel_1_5_2_0": @0,
                                     @"IsLED3On_2_26": @0,
                                     @"IsLED1On_1_5": @0,
                                     @"DimmerLevel_2_3_1_7": @0,
                                     @"IsLED1On_1_6": @0,
                                     @"DimmerLevel_2_27_3_0": @0,
                                     @"IsLED1On_2_28": @0,
                                     @"IsLED1On_2_32": @0,
                                     @"DimmerLevel_2_3_1_0": @0,
                                     @"DimmerLevel_2_3_4_5": @0,
                                     @"IsLED4On_2_1": @0,
                                     @"IsLED4On_2_27": @0,
                                     @"IsLED2On_2_32": @0,
                                     @"DimmerLevel_2_4_2_4": @0,
                                     @"DimmerLevel_2_3_1_6": @0,
                                     @"IsLED3On_2_32": @0,
                                     @"IsLED4On_2_3": @0,
                                     @"DimmerLevel_2_3_2_5": @0,
                                     @"DimmerLevel_2_4_2_3": @0,
                                     @"DimmerLevel_2_2_1_0": @0,
                                     @"IsLED3On_2_3": @0,
                                     @"DimmerLevel_2_28_8_0": @0,
                                     @"IsLED3On_2_4": @0,
                                     @"IsLED3On_2_5": @0,
                                     @"IsLED2On_2_2": @0,
                                     @"DimmerLevel_2_1_3_0": @0,
                                     @"DimmerLevel_2_27_1_0": @0,
                                     @"IsLED2On_2_3": @0,
                                     @"DimmerLevel_1_13_1_0": @0,
                                     @"DimmerLevel_2_1_2_0": @30,
                                     @"DimmerLevel_2_28_5_0": @0,
                                     @"DimmerLevel_2_15_4_0": @0,
                                     @"DimmerLevel_1_49_3_0": @0,
                                     @"IsLED2On_2_4": @0,
                                     @"DimmerLevel_2_37_8_0": @0,
                                     @"IsLED1On_2_1": @0,
                                     @"DimmerLevel_1_7_1_0": @0,
                                     @"DimmerLevel_2_4_2_8": @0,
                                     @"IsLED2On_2_18": @0,
                                     @"DimmerLevel_2_3_2_3": @0,
                                     @"IsLED3On_23_43": @0,
                                     @"IsLED2On_1_29": @0,
                                     @"IsLED1On_2_3": @0,
                                     @"DimmerLevel_2_3_4_8": @0,
                                     @"IsLED2On_2_19": @0,
                                     @"DimmerLevel_2_15_1_0": @0,
                                     @"IsLED1On_2_4": @0,
                                     @"DimmerLevel_2_4_2_7": @0,
                                     @"DimmerLevel_2_3_2_2": @0,
                                     @"IsLED1On_1_20": @0,
                                     @"IsLED1On_2_5": @0,
                                     @"IsLED2On_1_49": @0,
                                     @"IsLED4On_2_19": @0,
                                     @"IsLED2On_1_20": @0,
                                     @"DimmerLevel_2_8_2_0": @0};

    NSArray *lightingRooms = @[@"Entry", @"Kitchen", @"Living Room", @"Master Bedroom"];

    SAVSceneService *lightingScene = [SAVSceneService sceneServiceWithSettings:@{@"rooms": lightingRooms,
                                                                                 @"states": lightingStates}
                                                                     serviceID:@"SVC_ENV_LIGHTING"
                                                                      andScope:@"Lights.Lighting_controller"];

    [capturedScene addLightingSceneService:lightingScene];

    sceneSettings.results = [capturedScene dictionaryRepresentation];

    return sceneSettings;
}

- (SAVDISResults *)fetchSceneSettings:(NSString *)identifier
{
    SAVDISResults *sceneSettings = [[SAVDISResults alloc] init];
    sceneSettings.results = [self.scenes[identifier] dictionaryRepresentation];

    return sceneSettings;
}

- (SAVDISFeedback *)saveSceneSettings:(NSDictionary *)settings
{
    SAVScene *scene = nil;

    if (settings[SAVSceneIDKey])
    {
        scene = self.scenes[settings[SAVSceneIDKey]];

        if (!scene)
        {
            scene = [[SAVScene alloc] init];
        }
    }
    else
    {
        scene = [[SAVScene alloc] init];
    }

    [scene applySettings:settings];

    if (!scene.identifier)
    {
        scene.identifier = scene.name; // We need this to be consistent
        [self.scenesOrder addObject:scene.identifier];
    }

    self.scenes[scene.identifier] = scene;

    return [self fetchSceneList];
}

- (void)generateDemoScenes
{
    self.scenes = [NSMutableDictionary dictionary];
    self.scenesOrder = [NSMutableArray array];

    SAVSceneService *appleTVService = [[SAVSceneService alloc] init];
    appleTVService.component = @"AppleTV";
    appleTVService.logicalComponent = @"Media_server";
    appleTVService.rooms = [@[@"Living Room"] mutableCopy];
    appleTVService.serviceID = @"SVC_AV_APPLEREMOTEMEDIASERVER";
    NSMutableDictionary *avPower = [@{@"Living Room": @{@"Living Room-AppleTV-Media_server-1-SVC_AV_APPLEREMOTEMEDIASERVER": @1}} mutableCopy];
    NSMutableDictionary *volume = [@{@"Living Room": @15} mutableCopy];

    for (NSString *sceneName in @[@"Wake Up", @"Goodnight", @"Date Night", @"Dinner", @"Relax", @"Movie Night", @"Away", @"Shades", @"Play Time", @"Vacation"])
    {
        SAVScene *scene = [[SAVScene alloc] init];
        scene.name = NSLocalizedString(sceneName, nil);
        scene.imageKey = [@"Scene-" stringByAppendingString:sceneName];
        [scene addAVSceneService:appleTVService];
        scene.avPower = avPower;
        scene.volume = volume;

        if ([sceneName isEqualToString:@"Wake Up"] || [sceneName isEqualToString:@"Shades"])
        {
            scene.tags = [@[@"Master Bedroom", @"Master Bathroom"] mutableCopy];
        }
        else if ([sceneName isEqualToString:@"Goodnight"] || [sceneName isEqualToString:@"Away"] || [sceneName isEqualToString:@"Vacation"])
        {
            scene.tags = [@[@"Master Bedroom", @"Master Bathroom", @"Dining Room", @"Kitchen", @"Living Room", @"Patio", @"Entry", @"Sitting Room"] mutableCopy];
        }
        else if ([sceneName isEqualToString:@"Date Night"] || [sceneName isEqualToString:@"Relax"] || [sceneName isEqualToString:@"Movie Night"] || [sceneName isEqualToString:@"Play Time"])
        {
            scene.tags = [@[@"Living Room"] mutableCopy];
        }
        else if ([sceneName isEqualToString:@"Dinner"])
        {
            scene.tags = [@[@"Dining Room"] mutableCopy];
        }

        if ([sceneName isEqualToString:@"Wake Up"])
        {
            scene.scheduled = YES;
            scene.startDate = [NSDate today];
            scene.endDate = [NSDate today];
            scene.days = [@[@1, @2, @3, @4, @5] mutableCopy];
        }
        
        [self addScene:[scene dictionaryRepresentation]];
    }
}

@end
