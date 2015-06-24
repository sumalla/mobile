//
//  SCUClimateZonesModel.m
//  SavantController
//
//  Created by Stephen Silber on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateZonesModel.h"
#import "SCUDataSourceModelPrivate.h"
#import "SCUDefaultTableViewCell.h"
#import "SCUScenesZoneCell.h"
#import <SavantControl/SavantControl.h>

@interface SCUClimateZonesModel ()

@property NSArray *zones;
@property NSMutableDictionary *images;
@property NSDictionary *zoneToRooms;
@property NSArray *observers;
@property SAVSceneService *sceneService;

@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic) NSIndexPath *lastSelectedIndexPath;

@end

@implementation SCUClimateZonesModel

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.zoneToRooms = [[SavantControl sharedControl].data HVACRoomsInZones];
        self.zones = [self.zoneToRooms allKeys];
        
        NSMutableArray *dataSource = [NSMutableArray array];
        
        for (NSString *zone in self.zones)
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle:zone} mutableCopy];
            modelObject[SCUScenesZoneCellCellKeyRoomsList] = self.zoneToRooms[zone];
            [dataSource addObject:modelObject];
        }

        self.dataSource = dataSource;
    }
    
    return self;
}

- (void)loadDataIfNecessary
{
    if (self.observers)
    {
        return;
    }
    
    self.images = [NSMutableDictionary dictionary];
    
    NSMutableArray *observers = [NSMutableArray array];
    
    for (NSString *zone in self.zones)
    {
        for (NSString *room in self.zoneToRooms[zone])
        {
            SAVWeakSelf;
            id observer = [[SavantControl sharedControl].imageModel addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                SAVStrongWeakSelf;
                if (image)
                {
                    sSelf.images[room] = image;
                }
                NSIndexPath *indexPath = [self indexPathForZone:zone];
                [self.tableDelegate setImages:[self imagesForIndexPath:indexPath] forIndexPath:indexPath];
            }];
            
            [observers addObject:observer];
        }
    }
    
    self.observers = [observers copy];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForIndexPath:indexPath] mutableCopy];
    
    modelObject[SCUScenesZoneCellCellKeyRoomImagesArray] = [self imagesForIndexPath:indexPath];
    
    return modelObject;
}

- (NSString *)firstZone
{
    self.lastSelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    return [self.dataSource firstObject][SCUDefaultTableViewCellKeyTitle];
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

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice isPhone] || ![indexPath isEqual:self.lastSelectedIndexPath])
    {
        self.lastSelectedIndexPath = indexPath;
        [self.delegate showClimateControlsForZone:[self modelObjectForIndexPath:indexPath][SCUDefaultTableViewCellKeyTitle] indexPath:indexPath animated:YES];
    }
}

- (BOOL)shouldDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [UIDevice isPhone] ? YES : NO;
}

@end
