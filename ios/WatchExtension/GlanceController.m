//
//  GlanceController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "GlanceController.h"
#import "SDKInterfaceControllerPrivate.h"
@import SDK;
@import Extensions;

static NSString *SAVActiveServiceState = @"ActiveService";
static NSString *SAVRoomLightsAreOn = @"RoomLightsAreOn";
static NSString *SAVRoomCurrentTemperature = @"RoomCurrentTemperature";

@interface GlanceController () <StateDelegate>

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *temperature;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *lighting;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *media;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *homename;

@property NSMutableArray *roomLightsAreOn;
@property NSMutableDictionary *cachedClimateStates;
@property NSMutableArray *roomAVIsOn;

@property BOOL lightsAreOn;
@property BOOL avIsOn;
@property NSInteger averageTemperature;

@property BOOL hasLighting;
@property BOOL hasAV;
@property BOOL hasHVAC;

@property BOOL hvacNeedsUpdates;
@property BOOL avNeedsUpdate;
@property BOOL lightingNeedsUpdate;

@property NSArray *cachedRooms;
@property NSArray *registeredStates;
@property SAVCoalescedTimer *stateUpdate;

@end

@implementation GlanceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];

    self.stateUpdate = [[SAVCoalescedTimer alloc] init];
    self.stateUpdate.timeInverval = 0.2;

    self.roomLightsAreOn = [NSMutableArray array];
    self.roomAVIsOn = [NSMutableArray array];
    self.cachedClimateStates = [NSMutableDictionary dictionary];
}

- (void)didDeactivate
{
    [[Savant states] unregisterForStates:self.registeredStates forObserver:self];

    [super didDeactivate];

    self.registeredStates = nil;
    [self.roomLightsAreOn removeAllObjects];
    [self.roomAVIsOn removeAllObjects];
    [self.cachedClimateStates removeAllObjects];
    self.cachedRooms = nil;
}

- (void)connectionIsReady
{
    NSArray *rooms = [[Savant data] allRooms];

    if (![self.cachedRooms isEqualToArray:rooms] || !self.hasConnected)
    {
        self.cachedRooms = rooms;

        [[Savant states] unregisterForStates:self.registeredStates forObserver:self];

        NSMutableArray *statesToRegister = [NSMutableArray array];
        for (SAVRoom *room in self.cachedRooms)
        {
            if (room.hasAV)
            {
                self.hasAV = YES;

                [statesToRegister addObject:[NSString stringWithFormat:@"%@.%@", room.roomId, SAVActiveServiceState]];
            }

            if (room.hasLighting)
            {
                self.hasLighting = YES;

                [statesToRegister addObject:[NSString stringWithFormat:@"%@.%@", room.roomId, SAVRoomLightsAreOn]];
            }

            if (room.hasHVAC)
            {
                self.hasHVAC = YES;

                [statesToRegister addObject:[NSString stringWithFormat:@"%@.%@", room.roomId, SAVRoomCurrentTemperature]];
            }
        }

        [[Savant states] registerForStates:statesToRegister forObserver:self];
        self.registeredStates = statesToRegister;
    }

    [super connectionIsReady];

    [self.homename setText:[Savant control].currentSystem.name];

    [self showIndicators];
}

- (BOOL)cachedDataAvailable
{
    return [self.registeredStates count] ? YES : NO;
}

- (void)showStatusLabelWithText:(NSString *)text
{
    [super showStatusLabelWithText:text];

    [self.temperature setHidden:YES];
    [self.lighting setHidden:YES];
    [self.media setHidden:YES];
    [self.homename setHidden:YES];
}

- (void)showIndicators
{
    [self.statusLabel setHidden:YES];
    [self.temperature setHidden:!self.hasHVAC];
    [self.lighting setHidden:!self.hasLighting];
    [self.media setHidden:!self.hasAV];
    [self.homename setHidden:NO];

    if (self.lightsAreOn)
    {
        [self.lighting setAlpha:1];
    }
    else
    {
        [self.lighting setAlpha:.3];
    }

    if (self.avIsOn)
    {
        [self.media setAlpha:1];
    }
    else
    {
        [self.media setAlpha:.3];
    }

    if (self.averageTemperature > 0)
    {
        [self.temperatureLabel setText:[SAVHVACEntity addDegreeSuffix:[NSString stringWithFormat:@"%ld", (long)self.averageTemperature]]];
    }
    else
    {
        [self.temperature setHidden:YES];
    }
}

- (void)updateIndicators
{
    if (self.hvacNeedsUpdates)
    {
        NSInteger temperatureTotal = 0;
        for (NSString *temp in [self.cachedClimateStates allValues])
        {
            temperatureTotal += [temp integerValue];
        }

        self.averageTemperature = temperatureTotal / [self.cachedClimateStates count];
    }

    if (self.avNeedsUpdate)
    {
        self.avIsOn = [self.roomAVIsOn count] ? YES : NO;
    }

    if (self.lightingNeedsUpdate)
    {
        self.lightsAreOn = [self.roomLightsAreOn count] ? YES : NO;
    }

    self.hvacNeedsUpdates = NO;
    self.avNeedsUpdate = NO;
    self.lightingNeedsUpdate = NO;

    [self showIndicators];
}

#pragma mark - State Delegate

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    NSString *roomName = stateUpdate.scope;

    if ([stateUpdate.stateName isEqualToString:SAVRoomCurrentTemperature])
    {
        self.cachedClimateStates[roomName] = stateUpdate.value;

        self.hvacNeedsUpdates = YES;
    }
    else if ([stateUpdate.stateName isEqualToString:SAVRoomLightsAreOn])
    {
        if ([stateUpdate.value boolValue])
        {
            if (![self.roomLightsAreOn containsObject:roomName])
            {
                [self.roomLightsAreOn addObject:roomName];
            }
        }
        else
        {
            [self.roomLightsAreOn removeObject:roomName];
        }

        BOOL lightsAreOn = [self.roomLightsAreOn count] ? YES : NO;

        if (self.lightsAreOn != lightsAreOn)
        {
            self.lightingNeedsUpdate = YES;
        }
    }
    else if ([stateUpdate.stateName isEqualToString:SAVActiveServiceState])
    {
        if ([stateUpdate.value length])
        {
            if (![self.roomAVIsOn containsObject:roomName])
            {
                [self.roomAVIsOn addObject:roomName];
            }
        }
        else
        {
            [self.roomAVIsOn removeObject:roomName];
        }

        BOOL avIsOn = [self.roomAVIsOn count] ? YES : NO;

        if (self.avIsOn != avIsOn)
        {
            self.avNeedsUpdate = YES;
        }
    }

    SAVWeakSelf;
    [self.stateUpdate addWorkWithKey:@"stateUpdate" work:^{
        [wSelf updateIndicators];
    }];
}

@end
