//
//  SCUSecurityModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityModelPrivate.h"

@implementation SCUSecurityModel

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    
    if (self)
    {
        NSArray *entities = [[SavantControl sharedControl].data securityEntities:nil zone:nil service:nil];

        NSMutableDictionary *securityEntities = [NSMutableDictionary dictionary];

        for (SAVSecurityEntity *entity in entities)
        {
            NSMutableDictionary *sortedEntities = securityEntities[entity.service.component];

            if (!sortedEntities)
            {
                sortedEntities = [NSMutableDictionary dictionary];
                securityEntities[entity.service.component] = sortedEntities;
            }

            NSString *key = nil;
            switch (entity.type)
            {
                case SAVEntityType_Sensor:
                    key = SCUSecurityKeySensor;
                    break;
                case SAVEntityType_Partition:
                    key = SCUSecurityKeyPartition;
                    break;
                default:
                    break;
            }

            if (key)
            {
                NSMutableArray *entityArray = sortedEntities[key];

                if (!entityArray)
                {
                    entityArray = [NSMutableArray array];
                    sortedEntities[key] = entityArray;
                }

                [entityArray addObject:entity];
            }

            sortedEntities[SCUSecurityKeyService] = entity.service;
            sortedEntities[SCUSecurityKeyUserSecurity] = @(entity.isUserSecurity);
            sortedEntities[SCUSecurityKeyIdentifier] = @(entity.identifier);
        }

        self.securityEntities = [securityEntities copy];

        if (!self.currentSystem)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self selectSecuritySystem:[self.systems firstObject]];
            });
        }

        self.unknownSensorsTable = [NSHashTable weakObjectsHashTable];
        self.readySensorsTable = [NSHashTable weakObjectsHashTable];
        self.troubleSensorsTable = [NSHashTable weakObjectsHashTable];
        self.criticalSensorsTable = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)viewWillAppear
{
    [self cleanup];

    self.isOnScreen = YES;

    [super viewWillAppear];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];

    self.isOnScreen = NO;

    [self cleanup];
}

- (void)cleanup
{
    [self.unknownSensorsTable removeAllObjects];

    for (SAVSecurityEntity *sensor in self.sensors)
    {
        [self.unknownSensorsTable addObject:sensor];
    }

    [self.readySensorsTable removeAllObjects];
    [self.troubleSensorsTable removeAllObjects];
    [self.criticalSensorsTable removeAllObjects];

    [self.delegate securitySystemSensorCountDidChange:self.currentSystem];
}

- (SAVSecurityEntity *)sensorForSensorNumber:(NSString *)sensorKey
{
    SAVSecurityEntity *sensor = nil;

    for (SAVSecurityEntity *entity in self.sensors)
    {
        if ([entity.sensor isEqualToString:sensorKey])
        {
            sensor = entity;
            break;
        }
    }

    return sensor;
}

- (SAVSecurityEntity *)sensorForIdentifier:(NSInteger)identifier
{
    SAVSecurityEntity *sensor = nil;

    for (SAVSecurityEntity *entity in self.sensors)
    {
        if (entity.identifier == identifier)
        {
            sensor = entity;
            break;
        }
    }

    return sensor;
}

- (void)selectSecuritySystem:(NSString *)componentName
{
    NSAssert(self.securityEntities[componentName], @"Component is not a valid security system");

    if (componentName == self.currentSystem)
    {
        return;
    }

    if (self.currentSystem)
    {
        [[SavantControl sharedControl] unregisterForStates:self.statesToRegister forObserver:self];
    }

    self.currentSystem = componentName;

    if ([self.delegate respondsToSelector:@selector(securitySystemDidChange:)])
    {
        [self.delegate securitySystemDidChange:self.currentSystem];
    }

    [self cleanup];

    if (self.currentSystem && self.isOnScreen)
    {
        [[SavantControl sharedControl] registerForStates:self.statesToRegister forObserver:self];
    }
}

- (NSArray *)systems
{
    return [[self.securityEntities allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *system1, NSString *system2) {
        if ([self.securityEntities[system1][SCUSecurityIdentifer] integerValue] > [self.securityEntities[system2][SCUSecurityIdentifer] integerValue])
        {
            return NSOrderedAscending;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
}

- (NSArray *)partitions
{
    return self.securityEntities[self.currentSystem][SCUSecurityKeyPartition];
}

- (NSArray *)sensors
{
    return self.securityEntities[self.currentSystem][SCUSecurityKeySensor];
}

- (BOOL)isUserSecurity
{
    return [self.securityEntities[self.currentSystem][SCUSecurityKeyUserSecurity] boolValue];
}

- (SAVService *)service
{
    return self.currentSystem ? self.securityEntities[self.currentSystem][SCUSecurityKeyService] : [super service];
}

- (NSUInteger)unknownSensors
{
    return [self.unknownSensorsTable count];
}

- (NSUInteger)readySensors
{
    return [self.readySensorsTable count];
}

- (NSUInteger)troubleSensors
{
    return [self.troubleSensorsTable count];
}

- (NSUInteger)criticalSensors
{
    return [self.criticalSensorsTable count];
}

#pragma mark - SCUStateReceiver

- (NSArray *)statesToRegister
{
    NSMutableArray *sensorStates = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Always register for all sensors status states
    //-------------------------------------------------------------------
    for (SAVSecurityEntity *entity in self.sensors)
    {
        [sensorStates addObject:[entity stateFromType:SAVEntityState_SensorStatus]];
    }

    return sensorStates;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    SAVSecurityEntity *sensor = [self sensorForSensorNumber:[[[self.sensors firstObject] addressesFromState:stateUpdate.state] firstObject]];

    SAVEntityState state = [sensor typeFromState:stateUpdate.state];

    if (sensor)
    {
        switch (state)
        {
            case SAVEntityState_SensorStatus:
            {
                SAVSecurityEntityStatus status = [stateUpdate.value integerValue];

                [self.readySensorsTable removeObject:sensor];
                [self.troubleSensorsTable removeObject:sensor];
                [self.criticalSensorsTable removeObject:sensor];
                [self.unknownSensorsTable removeObject:sensor];

                switch (status)
                {
                    case SAVSecurityEntityStatus_Ready:
                        [self.readySensorsTable addObject:sensor];
                        break;
                    case SAVSecurityEntityStatus_Trouble:
                        [self.troubleSensorsTable addObject:sensor];
                        break;
                    case SAVSecurityEntityStatus_Critical:
                        [self.criticalSensorsTable addObject:sensor];
                        break;
                    case SAVSecurityEntityStatus_Unknown:
                        [self.unknownSensorsTable addObject:sensor];
                        break;
                }

                if ([self.delegate respondsToSelector:@selector(securitySystemSensorCountDidChange:)])
                {
                    [self.delegate securitySystemSensorCountDidChange:self.currentSystem];
                }
            }
                break;
            default:
                break;
        }
    }
}

@end
