//
//  SCUSceneZonesListModel.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneZonesListModelPrivate.h"
#import "SCUScenesZoneCell.h"

@import SDK;

@interface SCUSceneZonesListModel ()

@property NSDictionary *zoneToServiceMap;

@end

@implementation SCUSceneZonesListModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        SAVMutableService *dummyService = [[SAVMutableService alloc] init];
        dummyService.serviceId = @"SVC_ENV_HVAC";
        NSArray *entities = [[Savant data] HVACEntities:nil zone:nil service:dummyService];

        NSMutableArray *sceneServices = [NSMutableArray array];
        NSMutableDictionary *zoneToService = [NSMutableDictionary dictionary];

        for (SAVHVACEntity *entity in entities)
        {
            SAVSceneService *sceneService = [self.scene sceneServiceForService:entity.service];
            [sceneServices addObject:sceneService];
            zoneToService[entity.zoneName] = sceneService;
        }

        self.zoneToServiceMap = [zoneToService copy];
        self.sceneServices = [sceneServices copy];
    }
    return self;
}

- (void)loadDataIfNecessary
{
    if (self.observers)
    {
        return;
    }

    self.zoneToRooms = [[Savant data] HVACRoomsInZones];
    self.zones = [self.zoneToRooms allKeys];
    
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *zones = [NSMutableArray array];
    
    for (NSString *zone in self.zones)
    {
        NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle:zone} mutableCopy];
        
        if (self.service.logicalComponent)
        {
            modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryDisclosureIndicator);
        }
        
        modelObject[SCUScenesZoneCellCellKeyRoomsList] = self.zoneToRooms[zone];
        
        [zones addObject:modelObject];
    }
    
    [dataSource addObject:zones];
    self.dataSource = dataSource;
    
    self.images = [NSMutableDictionary dictionary];
    
    NSMutableArray *observers = [NSMutableArray array];
    
    for (NSString *zone in self.zones)
    {
        for (NSString *room in self.zoneToRooms[zone])
        {
            SAVWeakSelf;
            id observer = [[Savant images] addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                if (image)
                {
                    wSelf.images[room] = image;
                }
                
                NSIndexPath *indexPath = [self indexPathForZone:zone];
                [self.delegate setImages:[self imagesForIndexPath:indexPath] forIndexPath:indexPath];
                
            }];
            
            [observers addObject:observer];
        }
    }
    
    self.observers = [observers copy];
}

- (BOOL)isFlat
{
    return NO;
}

- (NSIndexPath *)indexPathForZone:(NSString *)zone
{
    NSUInteger index = [self.zones indexOfObject:zone];
    return [NSIndexPath indexPathForRow:index inSection:0];
}

- (NSArray *)imagesForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *images = [NSMutableArray array];
    NSString *zone = [self zoneForIndexPath:indexPath];
    for (NSString *room in self.zoneToRooms[zone])
    {
        if (self.images[room])
        {
            [images addObject:self.images[room]];
        }
    }
    
    return images;
}

- (NSString *)zoneForIndexPath:(NSIndexPath *)indexPath
{
    return self.zones[indexPath.row];
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return [NSLocalizedString(@"Zones", nil) uppercaseString];
}

- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath
{
    BOOL selected = NO;
    
    NSString *zone = self.zones[indexPath.row];

    if ([self.sceneServices count])
    {
        SAVSceneService *service = self.zoneToServiceMap[zone];
        selected = [service.zones containsObject:zone];
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            selected = [self.scene.hvacOff containsObject:zone];
        }
    }
    
    return selected;
}

- (BOOL)hasSelectedRows
{
    BOOL hasSelected = NO;
    
    if ([self.sceneServices count])
    {
        for (SAVSceneService *service in self.sceneServices)
        {
            hasSelected = [service.zones count] ? YES : NO;

            if (hasSelected)
            {
                break;
            }
        }
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            hasSelected = [self.scene.hvacOff count] ? YES : NO;
        }
    }
    
    return hasSelected;
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 1;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForIndexPath:indexPath] mutableCopy];
    
    modelObject[SCUScenesZoneCellCellKeySelected] = @([self indexPathIsSelected:indexPath]);
    
    modelObject[SCUScenesZoneCellCellKeyRoomImagesArray] = [self imagesForIndexPath:indexPath];
    
    return modelObject;
}

- (void)addZone:(NSString *)zone
{
    if (self.zoneToServiceMap[zone])
    {
        SAVSceneService *service = self.zoneToServiceMap[zone];
        [service.zones addObject:zone];
    }
}

- (void)removeZone:(NSString *)zone
{
    if (self.zoneToServiceMap[zone])
    {
        SAVSceneService *service = self.zoneToServiceMap[zone];
        [service.zones removeObject:zone];
    }
}

- (void)doneEditing
{
    for (SAVSceneService *service in self.sceneServices)
    {
        if (![service.zones count] || ![service.states count])
        {
            if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
            {
                [self.scene removeHVACSceneService:service];
            }
        }
    }
}

@end
