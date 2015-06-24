//
//  SCUNotificationZonesListViewModel.m
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationZonesListViewModel.h"
#import <SavantControl/SavantControl.h>
#import "SCUDefaultTableViewCell.h"
#import "SCUScenesZoneCell.h"

@interface SCUNotificationZonesListViewModel ()

@property NSDictionary *zoneToServiceMap;
@property NSMutableArray *dataSource;

@end

@implementation SCUNotificationZonesListViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    if (self)
    {
        SAVService *dummyService = [[SAVService alloc] initWithZone:nil component:nil logicalComponent:nil variantId:nil serviceId:@"SVC_ENV_HVAC"];
        NSArray *entities = [[SavantControl sharedControl].data HVACEntities:nil zone:nil service:dummyService];
        
        NSMutableDictionary *zoneToService = [NSMutableDictionary dictionary];
        
        for (SAVHVACEntity *entity in entities)
        {
            SAVNotificationServiceType serviceType = self.notification.serviceType;
            zoneToService[entity.zoneName] = @(serviceType);
        }
        
        self.zoneToServiceMap = [zoneToService copy];
    }
    return self;
}

- (void)loadDataIfNecessary
{
    if (self.observers)
    {
        return;
    }
    
    self.zoneToRooms = [[SavantControl sharedControl].data HVACRoomsInZones];
    self.zones = [self.zoneToRooms allKeys];
    
    if (![self.notification.zones count])
    {
        self.notification.zones = [self.zones mutableCopy];
    }
    
    NSMutableArray *dataSource = [NSMutableArray array];
    NSMutableArray *zones = [NSMutableArray array];
    
    for (NSString *zone in self.zones)
    {
        NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle:zone} mutableCopy];
        
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
            id observer = [[SavantControl sharedControl].imageModel addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
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
    
    if ([self.notification.zones count])
    {
        selected = [self.notification.zones containsObject:zone];
    }
    
    return selected;
}

- (BOOL)hasSelectedRows
{
    BOOL hasSelected = NO;
    
    if (self.notification)
    {
        hasSelected = [self.notification.zones count] ? YES : NO;
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
        [self.notification.zones addObject:zone];
    }
}

- (void)removeZone:(NSString *)zone
{
    if (self.zoneToServiceMap[zone])
    {
        [self.notification.zones removeObject:zone];
    }
}

- (void)doneEditing
{
    if (self.notification && [self.notification.zones count])
    {
        if ([self.notification.zones count] == [self.zones count])
        {
            self.notification.zones = nil;
        }
    }
}

@end
