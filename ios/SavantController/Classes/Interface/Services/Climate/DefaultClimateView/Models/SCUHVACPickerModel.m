//
//  SCUHVACPickerModel.m
//  SavantController
//
//  Created by Jason Wolkovitz on 10/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHVACPickerModel.h"
#import "SCUInterface.h"

@interface SCUHVACPickerModel()

@property (nonatomic, strong) NSString *currentHVACZoneKey;

@property (nonatomic) id settingsObserver;

@property (nonatomic) NSInteger currentZoneIndex;

@end

@implementation SCUHVACPickerModel

- (instancetype)initWithHVACArray:(NSArray *)hvacArray serviceType:(SCUClimateServiceType)serviceType
{
    self = [super init];
    if (self)
    {
        self.currentHVACZoneKey = [NSString stringWithFormat:@"%@.currentHVACZone", [SCUInterface sharedInstance].currentRoom.roomId];

        NSMutableArray *hvacEntities = [NSMutableArray array];

        for (id obj in hvacArray)
        {
            if ([obj isKindOfClass:[SAVHVACEntity class]])
            {
                [hvacEntities addObject:obj];
            }
            else if ([obj isKindOfClass:[NSString class]])
            {
                SAVMutableService *dummyService = [[SAVMutableService alloc] init]; // redmine Bug #7984 Lighting controller used as HVAC controller showing up twice
                dummyService.serviceId = @"SVC_ENV_HVAC";
                NSArray *entitiesForZone = [[SavantControl sharedControl].data HVACEntities:nil zone:obj service:dummyService];
                [hvacEntities addObjectsFromArray:entitiesForZone];
            }
        }

        for (NSInteger i = [hvacEntities count]  - 1; i >= 0; i--)
        {
            SAVHVACEntity *entity = [hvacEntities objectAtIndex:i];
            if ([self removeEntity:entity forServiceType:serviceType])
            {
                [hvacEntities removeObject:entity];
            }
        }
        
        _HVACEntities = [hvacEntities copy];

        _currentZoneIndex = [self startEntityForRoomID:[SCUInterface sharedInstance].currentRoom.roomId otherKeys:@[]];

        if (!self.settingsObserver)
        {
            SAVWeakSelf;
            self.settingsObserver = [[SAVSettings localSettings] addObserverForKey:self.currentHVACZoneKey
                                                                        usingBlock:^(NSString *key, id zoneName) {
                                                                            [wSelf changeHVACForUpdateZoneName:zoneName];
                                                                        }];
        }
    }
    
    return self;
}

- (BOOL)removeEntity:(SAVHVACEntity *)entity forServiceType:(SCUClimateServiceType)serviceType
{
    BOOL remove = NO;
    switch (serviceType)
    {
        case SCUClimateServiceTypeHumidity:
        {
            if (entity.humiditySPCount == 0)//!entity.dehumidifySetPoint && !entity.humidifySetPoint &&
            {
                remove = YES;
            }
            break;
        }
        case SCUClimateServiceTypeTemperature:
        {
            if (entity.tempSPCount == 0)//!entity.coolSetPoint && !entity.heatSetPoint && (
            {
                remove = YES;
            }
            break;
        }
        case SCUClimateServiceTypeHistory:
        {
//            if (!entity)//need something in the entity to check if HVAC has histroy
//            {
//                remove = YES;
//            }
            break;
        }
            
        default:
            break;
    }
    return remove;
}

- (SAVHVACEntity *)currentHVACEntity
{
    SAVHVACEntity *hvacEntity = nil;
    NSInteger currentZoneIndex = self.currentZoneIndex;
    if (currentZoneIndex < (NSInteger)[self.HVACEntities count])
    {
        hvacEntity = self.HVACEntities[currentZoneIndex];
    }
    return hvacEntity;
}

- (NSString *)currentHVACZone
{
    SAVHVACEntity *hvacEntity = [self currentHVACEntity];
    
    if (hvacEntity)
    {
        [[SAVSettings localSettings] setObject:hvacEntity.zoneName forKey:self.currentHVACZoneKey];
        [[SAVSettings localSettings] synchronize];
    }
    
    return hvacEntity.zoneName;
}

- (NSString *)currentHVACEntityName
{
    return [self zoneNameForEntity:[self currentHVACEntity]];
}

- (NSObject *)findFirstHVACEntityWithPosibleZoneNames:(NSArray *)zoneNames
{
    NSObject *hvacEntity = nil;
    if ([self.HVACEntities count] < 1)
    {
        hvacEntity = nil;
        self.currentZoneIndex = NSNotFound;
    }
    else
    {
        NSInteger firstZoneIndex = [self startEntityForRoomID:[SCUInterface sharedInstance].currentRoom.roomId otherKeys:zoneNames];
        if (firstZoneIndex < 0 || firstZoneIndex >= (NSInteger)[self.HVACEntities count])
        {
            hvacEntity = [self.HVACEntities firstObject];
            self.currentZoneIndex = 0;
        }
        else
        {
            hvacEntity = [self.HVACEntities objectAtIndex:firstZoneIndex];
            self.currentZoneIndex = firstZoneIndex;
        }
    }
    return hvacEntity;
}

- (NSInteger)startEntityForRoomID:(NSString *)roomID otherKeys:(NSArray *)otherKeys
{
    NSString *zoneName = [[SAVSettings localSettings] objectForKey:self.currentHVACZoneKey];
    NSInteger currentZoneIndex = [self.HVACEntitiesZoneNames indexOfObject:zoneName];
    NSInteger firstZoneIndex = NSNotFound;
    NSInteger minLevenshteinDistance = NSNotFound;

    if (currentZoneIndex >= 0 && currentZoneIndex != NSNotFound)
    {
        firstZoneIndex = currentZoneIndex;
    }
    else
    {
        if (roomID)
        {
            otherKeys = [@[roomID] arrayByAddingObjectsFromArray:otherKeys];
        }
        if (otherKeys && (firstZoneIndex < 0 || firstZoneIndex == NSNotFound))
        {
            NSString *testKey;
            for (NSInteger i = 0; i < (NSInteger)[otherKeys count]; i++)
            {
                testKey = [otherKeys objectAtIndex:i];
                firstZoneIndex = [self.HVACEntitiesZoneNames indexOfObject:testKey];
                if (firstZoneIndex >= 0 && firstZoneIndex != NSNotFound)
                {
                    break;
                }
                for (NSUInteger i = 0; i < [self.HVACEntitiesZoneNames count]; i++)
                {
                    NSInteger levDistance = [testKey computeLevenshteinDistanceWithString:self.HVACEntitiesZoneNames[i]];
                    if (minLevenshteinDistance > levDistance)
                    {
                        minLevenshteinDistance = levDistance;
                        firstZoneIndex = i;
                    }
                }
            }
        }
    }
    
    if (firstZoneIndex < 0 || firstZoneIndex == NSNotFound)
    {
        firstZoneIndex = 0;
    }
    self.currentZoneIndex = firstZoneIndex;
    return firstZoneIndex;
}

- (NSInteger)HVACEntityIndexForZoneName:(NSString *)zoneName
{
    NSInteger zoneIndex = [self.HVACEntitiesZoneNames indexOfObject:zoneName];
    return zoneIndex;
}

- (NSInteger)zoneIndexForEntity:(NSObject *)entity
{
    NSInteger zi = -1;
    for (NSInteger i = 0; i < (NSInteger)[self.HVACEntities count]; i++)
    {
        if (entity == self.HVACEntities[i])
        {
            zi = i;
            break;
        }
    }
    return zi;
}

- (void)setCurrentZoneIndexFromPicker:(NSInteger)newZoneIndex
{
    NSInteger currentZoneIndex = self.currentZoneIndex;
    
    if ((NSInteger)[self.HVACEntities count] > newZoneIndex &&
        newZoneIndex != currentZoneIndex)
    {
        NSObject *entity = [self.HVACEntities objectAtIndex:newZoneIndex];
        NSString *zoneName = nil;
        
        if ([entity isKindOfClass:[SAVPoolEntity class]])
        {
            zoneName = [(SAVPoolEntity *)entity label];
        }
        else if ([entity isKindOfClass:[SAVHVACEntity class]])
        {
            zoneName = [(SAVHVACEntity *)entity zoneName];
        }
        else if ([entity isKindOfClass:[SAVZone class]])
        {
            zoneName = [(SAVZone *)entity zoneName];
        }
        
        if (zoneName)
        {
            [[SAVSettings localSettings] setObject:zoneName forKey:self.currentHVACZoneKey];
            [[SAVSettings localSettings] synchronize];
            
            if ([self.viewDelegate respondsToSelector:@selector(hvacPickerChangedZone:)])
            {
                [self.viewDelegate hvacPickerChangedZone:zoneName];
            }
            if ([self.schedulingDelegate respondsToSelector:@selector(hvacPickerChangedZone:)])
            {
                [self.schedulingDelegate hvacPickerChangedZone:zoneName];
            }
        }
    }
}

- (void)setCurrentZoneIndex:(NSInteger)newZoneIndex
{
    NSInteger currentZoneIndex = self.currentZoneIndex;
    
    if ((NSInteger)[self.HVACEntities count] > newZoneIndex &&
        newZoneIndex != currentZoneIndex)
    {
        _currentZoneIndex = newZoneIndex;
        NSObject *hvacEntity = [self.HVACEntities objectAtIndex:newZoneIndex];
        if (self.delegate)
        {
            [self.delegate internalSetNewCurrentEntity:hvacEntity];
        }
        if (self.viewDelegate)
        {
            [self.viewDelegate setHvacLabelText];
        }
    }
}

- (NSArray *)HVACEntitiesZoneNames
{
    NSObject *entity;
    
    NSMutableArray *zoneNames = [[NSMutableArray alloc] initWithCapacity:[self.HVACEntities count]];
    NSInteger count = [self.HVACEntities count];
    for (NSInteger i = 0; i < count; i++)
    {
        entity = self.HVACEntities[i];
        NSString *zoneName = [self zoneNameForEntity:entity];
        [zoneNames addObject:zoneName];
    }
    return zoneNames;
}

- (void)changeHVACForUpdateZoneName:(NSString *)zoneName
{
    if ([zoneName length] > 0)
    {
        NSInteger zoneIndex = [self HVACEntityIndexForZoneName:zoneName];

        if (zoneIndex == NSNotFound || zoneIndex < 0)
        {
            zoneIndex = [self startEntityForRoomID:zoneName otherKeys:@[]];
        }

        if (zoneIndex != NSNotFound && zoneIndex >= 0)
        {
            [self setCurrentZoneIndex:zoneIndex];
        }
    }
}

- (NSString *)zoneNameForEntity:(NSObject *)entity
{
    SAVHVACEntity *hvacEntity = nil;
    SAVZone *hvacZone = nil;
    SAVService *hvacService = nil;
    
    if ([entity isKindOfClass:[SAVHVACEntity class]])
    {
        hvacEntity = (SAVHVACEntity *)entity;
    }
    else if ([entity isKindOfClass:[SAVZone class]])
    {
        hvacZone = (SAVZone *)entity;
    }
    else if ([entity isKindOfClass:[SAVService class]])
    {
        hvacService = (SAVService *)entity;
    }
    
    NSString *zoneName = nil;
    if (hvacEntity)
    {
        zoneName = hvacEntity.zoneName;
    }
    else if (hvacZone)
    {
        zoneName = hvacZone.zoneName;
    }
    else if (hvacService)
    {
        zoneName = hvacService.zoneName;
    }
    
    if (!zoneName && hvacEntity)
    {
        zoneName = hvacEntity.label;
        if (!zoneName)
        {
            zoneName = hvacEntity.service.zoneName;
            NSString *hvacType;
            if ([hvacEntity.service.serviceId isEqualToString:@"SVC_ENV_POOLANDSPA"])
            {
                hvacType = @"Pool Controller";
            }
            else
            {
                hvacType = @"Climate Control";
            }
            
            NSInteger index = [self.HVACEntities indexOfObject:entity];
            if (index != NSNotFound && index != 0)
            {
                hvacType = [NSString stringWithFormat:@"%@ %ld", hvacType, (long)index];
            }
            if (zoneName)
            {
                zoneName = [NSString stringWithFormat:@"%@ %@", zoneName, hvacType];
            }
        }
    }
    else if ((!zoneName && hvacZone) || (!zoneName && hvacService))
    {
        zoneName = [NSString stringWithFormat:@"Zone %ld", (long)index];
    }
    return zoneName;
}

- (void)unregisterForStates
{
    [[SAVSettings userSettings] removeObserver:self.settingsObserver];
}

@end
