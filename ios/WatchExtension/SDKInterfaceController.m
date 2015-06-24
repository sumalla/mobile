//
//  SDKInterfaceController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SDKInterfaceControllerPrivate.h"
@import SDK;
@import Extensions;

@interface SDKInterfaceController() <SystemStatusDelegate>

@property (nonatomic, weak) NSTimer *connectionTimer;

@end

@implementation SDKInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    [self setupSDK];
}

- (void)willActivate
{
    [super willActivate];

    [self cleanupTimer];

    [[Savant control] addSystemStatusObserver:self];

    if ([Savant control].isConnectedToSystem)
    {
        [self connectionIsReady];
    }
    else if ([[Savant control] loadPreviousConnection])
    {
        NSString *currentUID = [Savant control].currentSystem.hostID;

        dispatch_block_t block = ^{
            [self showStatusLabelWithText:NSLocalizedString(@"Connecting to your Savant Home.", nil)];
        };

        if ([self.lastConnectedUID isEqualToString:currentUID] && [self cachedDataAvailable])
        {
            self.connectionTimer = [NSTimer sav_scheduledBlockWithDelay:2 block:^{
                block();
            }];
        }
        else
        {
            block();
        }

        self.lastConnectedUID = currentUID;
    }
    else
    {
        [self showStatusLabelWithText:NSLocalizedString(@"Unable to connect. Please ensure your App is connected to a Savant system.", nil)];
    }
}

- (void)didDeactivate
{
    [super didDeactivate];
    
    [[Savant control] removeSystemStatusObserver:self];
    
    if ([[Savant control] systemStatusObservers].count == 0)
    {
        [[Savant control] disconnect];
    }
    
    [self cleanupTimer];
    self.hasConnected = NO;
}

- (BOOL)cachedDataAvailable
{
    return NO;
}

- (void)showStatusLabelWithText:(NSString *)text
{
    [self.reconnectIcon setHidden:NO];
    [self.statusLabel setHidden:NO];

    if (text)
    {
        [self.statusLabel setText:text];
    }
}

#pragma mark - SystemStatusObserver

- (void)connectionIsReady
{
    [self cleanupTimer];

    self.hasConnected = YES;
}

- (void)connectionDidFailToConnect
{
    [self cleanupTimer];

    if (self.hasConnected)
    {
        [self showStatusLabelWithText:NSLocalizedString(@"Lost connection to your Savant Home", nil)];
    }
    else
    {
        [self showStatusLabelWithText:nil];
    }
}

- (void)cleanupTimer
{
    [self.connectionTimer invalidate];
    self.connectionTimer = nil;
}

#pragma mark - SDK

- (void)setupSDK
{
    [Savant control].deviceFormFactor = @"watch";
    [Savant control].deviceManufacturer = @"Apple";
    [Savant control].deviceOperatingSystem = [UIDevice currentDevice].systemName;
    [Savant control].deviceOperatingSystemVersion = [UIDevice currentDevice].systemVersion;
    [Savant control].deviceName = [UIDevice currentDevice].name;
    [Savant control].deviceModel = [[UIDevice currentDevice] model];
    [Savant control].deviceModelVersion = [[UIDevice currentDevice] sav_modelVersion];
    [Savant control].deviceUID = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByAppendingString:@"-watch"];
    [Savant control].appName = @"Savant";
    [Savant control].controlMode = SAVControlModeDatabase;
    [Savant control].appVersion = [self appVersion];
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
#elif defined(SERVER_DEV)
    server = @"Dev";
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
