//
//  SCUScenesExtensionModel.m
//  SavantController
//
//  Created by Nathan Trapp on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesExtensionModel.h"
@import Extensions;
@import SDK;

NSUInteger const SCUMaxScenes = 5;

@interface SCUScenesExtensionModel () <StateDelegate, SystemStatusDelegate>

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) SAVDISRequestGenerator *generator;
@property (nonatomic) NSArray *feedbackNames;
@property (nonatomic) NSArray *identifiers;

@end

@implementation SCUScenesExtensionModel

- (instancetype)initWithDelegate:(id <SCUScenesExtensionModelDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.delegate = delegate;

        //-------------------------------------------------------------------
        // Setup SavantControl.
        //-------------------------------------------------------------------
        [Savant control].controlMode = SAVControlModeCustom;
        [Savant control].deviceFormFactor = [UIDevice isPad] ? @"tablet" : @"phone";
        [Savant control].deviceManufacturer = @"Apple";
        [Savant control].deviceOperatingSystem = [UIDevice currentDevice].systemName;
        [Savant control].deviceOperatingSystemVersion = [UIDevice currentDevice].systemVersion;
        [Savant control].deviceName = [UIDevice currentDevice].name;
        [Savant control].deviceModel = [[UIDevice currentDevice] model];
        [Savant control].deviceModelVersion = [[UIDevice currentDevice] sav_modelVersion];
        [Savant control].deviceUID = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByAppendingString:@"-sceneExtension"];
        [Savant control].appName = @"Savant";
        [Savant control].appVersion = self.appVersion;
        [[Savant control] addSystemStatusObserver:self];
    }

    return self;
}

- (void)dealloc
{
    [[Savant control] removeSystemStatusObserver:self];
    [[Savant states] unregisterForStates:self.feedbackNames forObserver:self];
}

- (BOOL)loadPreviousConnection
{
    BOOL success = [Savant control].connectedToSystem;

    if (!success)
    {
        success = [[Savant control] loadPreviousConnection];

        if (!success)
        {
            [[Savant control] disconnect];
        }
    }

    if (success)
    {
        NSArray *rawScenes = [[NSUserDefaults standardUserDefaults] objectForKey:@"RawScenes"];
        [self parseScenes:rawScenes ready:NO];
    }
    else
    {
        [[Savant control] disconnect];
        [[Savant control] removeSystemStatusObserver:self];
    }

    return success;
}

- (void)selectItem:(NSUInteger)item
{
    SAVDISRequest *applyScene = [self.generator request:@"ApplyScene" withArguments:@{@"id": [self sceneIdentifierForItem:item]}];
    [[Savant control] sendMessage:applyScene];
}

#pragma mark - StateDelegate methods

- (void)didReceiveDISFeedback:(SAVDISFeedback *)feedback
{
    if ([feedback.stateName isEqualToString:@"scenes"])
    {
        [self loadScenes:[feedback value]];
    }
}

#pragma mark -

- (NSUInteger)numberOfScenes
{
    return [self.dataSource count];
}

- (void)loadScenes:(NSArray *)scenes
{
    NSMutableArray *rawScenes = [NSMutableArray array];

    NSUInteger sceneCount = 0; // allow a max of SCUMaxScenes scenes
    for (NSDictionary *sceneDict in scenes)
    {
        [rawScenes addObject:sceneDict];

        if (++sceneCount >= SCUMaxScenes)
        {
            break;
        }
    }

    [self parseScenes:[rawScenes copy] ready:YES];
}

- (void)parseScenes:(NSArray *)rawScenes ready:(BOOL)ready
{
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *identifiers = [NSMutableArray array];

    NSUInteger sceneCount = 0; // allow a max of SCUMaxScenes scenes
    //-------------------------------------------------------------------
    // Add scenes
    //-------------------------------------------------------------------
    for (NSDictionary *sceneDict in rawScenes)
    {
        SAVScene *scene = [[SAVScene alloc] init];
        scene.imageSize = SAVImageSizeSmall;
        [scene applySettings:sceneDict];

        if (scene && scene.name)
        {
            [dataSource addObject:scene];
            [identifiers addObject:scene.identifier];
        }

        if (++sceneCount >= SCUMaxScenes)
        {
            break;
        }
    }

    [NSUserDefaults sav_modifyDefaults:^(NSUserDefaults *defaults) {
        [defaults setObject:rawScenes forKey:@"RawScenes"];
    }];

    self.identifiers = [identifiers copy];
    self.dataSource = dataSource;

    if (ready)
    {
        [NSTimer sav_scheduledBlockWithDelay:0.2 block:^{
            [self.delegate loadScenes:ready];
        }];
    }
    else
    {
        [self.delegate loadScenes:ready];
    }
}

- (SAVScene *)sceneForItem:(NSUInteger)item
{
    SAVScene *scene = nil;

    if (item < [self.dataSource count])
    {
        scene = self.dataSource[item];
    }

    return scene;
}

- (NSString *)sceneIdentifierForItem:(NSUInteger)item
{
    SAVScene *scene = [self sceneForItem:item];

    return scene.identifier;
}

#pragma mark - SystemStatusDelegate

- (void)connectionIsReady
{
    if (!self.generator)
    {
        self.generator = [[SAVDISRequestGenerator alloc] initWithApp:@"dashboard"];
        self.feedbackNames = [self.generator feedbackStringsWithStateNames:@[@"scenes"]];
        [[Savant states] registerForStates:self.feedbackNames forObserver:self];
    }

    if (self.dataSource)
    {
        [self.delegate loadScenes:YES];
    }
}

- (void)establishedConnectionDidFail
{
    [self notifyDelegateOfConnectionFailure];
}

- (void)connectionDidFailToConnect
{
    [self notifyDelegateOfConnectionFailure];
}

- (void)notifyDelegateOfConnectionFailure
{
    [self.delegate connectionLostToSystem:[Savant control].currentSystem.name];
}

#pragma mark - App version

- (NSString *)appVersion
{
#ifdef DEBUG
    return @"Debug";
#else
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];

#ifdef SERVER_PRODUCTION
    return info[@"ActualVersion"];
#else
    NSString *branch = nil;

#ifdef SERVER_ALPHA
    branch = @"Alpha";
#elif defined(SERVER_DEV1)
    server = @"Dev1";
#elif defined(SERVER_DEV2)
    server = @"Dev2";
#elif defined(SERVER_BETA)
    branch = @"Beta";
#elif defined(SERVER_QA)
    branch = @"QA";
#elif defined(SERVER_TRAINING)
    branch = @"Training";
#else
    branch = @"Unknown";
#endif

    return [NSString stringWithFormat:@"%@ (%@)", branch, info[@"CFBundleVersion"]];
#endif
#endif
}

@end
