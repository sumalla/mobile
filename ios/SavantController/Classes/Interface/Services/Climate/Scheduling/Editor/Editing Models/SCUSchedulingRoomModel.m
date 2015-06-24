//
//  SCUSchedulingRoomModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUInterface.h"
#import "SCUSchedulingRoomModel.h"
#import "SCUSchedulingRoomCell.h"
#import <SavantControl/SavantControl.h>

@interface SCUSchedulingRoomModel ()

@property (nonatomic) NSArray *observers;
@property (nonatomic) NSMutableDictionary *images;
@property (nonatomic) NSArray *zones;
@property (nonatomic) SAVCoalescedTimer *imageReloadTimer;

@end

@implementation SCUSchedulingRoomModel

- (instancetype)initWithSchedule:(SAVClimateSchedule *)schedule
{
    self = [super initWithSchedule:schedule];
    
    if (self)
    {
        self.imageReloadTimer = [[SAVCoalescedTimer alloc] init];
        self.imageReloadTimer.timeInverval = 0.5;

        self.zones = [[SavantControl sharedControl].data HVACZonesInRooms];

        [self registerForObservers];

        [self toggleInitialRoom];
    }
    
    return self;
}

- (void)toggleInitialRoom
{
    if (!self.schedule.zones.count)
    {
        if ([self numberOfItemsInSection:0])
        {
            // Select first row for Services First if there are options to choose from
            [self toggleRoomSelectedAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    NSInteger numberOfItems = 0;
    numberOfItems = [self.zones count];

    return numberOfItems;
}

- (void)toggleRoomSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *zones = [[SavantControl sharedControl].data HVACZonesInRooms];
    
    NSDictionary *zoneData = zones[indexPath.row];
    
    NSString *zone = zoneData[@"zoneName"];
    
    if ([self.schedule.zones containsObject:zone])
    {
        NSMutableArray *scheduleZones = [self.schedule.zones mutableCopy];
        [scheduleZones removeObject:zone];
        self.schedule.zones = [scheduleZones copy];
    }
    else
    {
        NSMutableArray *scheduleZones = (self.schedule.zones) ? [self.schedule.zones mutableCopy] : [NSMutableArray array];
        [scheduleZones addObject:zone];
        self.schedule.zones = [scheduleZones copy];
    }
    
    [self.delegate reconfigureIndexPath:indexPath];

}

- (NSArray *)imagesForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *zones = [[SavantControl sharedControl].data HVACZonesInRooms];
    NSDictionary *zoneData = zones[indexPath.row];
    NSMutableArray *images = [NSMutableArray array];
    
    for (NSString *room in zoneData[@"rooms"])
    {
        if (self.images[room])
        {
            [images addObject:self.images[room]];
        }
    }
    
    return images;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *zones = [[SavantControl sharedControl].data HVACZonesInRooms];
    NSDictionary *zoneData = zones[indexPath.row];
    NSString *zone = zoneData[@"zoneName"];
    NSArray *images = [self imagesForIndexPath:indexPath];
    BOOL selected = [self.schedule.zones containsObject:zone];

    return @{SCUDefaultTableViewCellKeyTitle: zoneData[@"zoneName"],
             SCUScenesZoneCellCellKeyRoomsList: zoneData[@"rooms"],
             SCUScenesZoneCellCellKeySelected: @(selected),
             SCUScenesZoneCellCellKeyRoomImagesArray: images};
}

- (void)invalidateImageReloadTimer
{
    [self.imageReloadTimer invalidate];
    self.observers = nil;
}

- (NSIndexPath *)indexPathForZone:(NSString *)zone
{
    NSUInteger index = 0;
    for (NSDictionary *zoneData in self.zones)
    {
        if ([zoneData[@"zoneName"] isEqualToString:zone])
        {
            break;
        }
        index++;
    }
    
    return [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)registerForObservers
{
    if (self.observers)
    {
        return;
    }
    NSDictionary *zoneToRooms = [[SavantControl sharedControl].data HVACRoomsInZones];
    
    self.images = [NSMutableDictionary dictionary];
    
    NSMutableArray *observers = [NSMutableArray array];
    
    for (NSString *zone in [zoneToRooms allKeys])
    {
        for (NSString *room in zoneToRooms[zone])
        {
            SAVWeakSelf;
            id observer = [[SavantControl sharedControl].imageModel addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeSmall blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {
                    if (image)
                    {
                        wSelf.images[room] = image;
                        NSIndexPath *indexPath = [self indexPathForZone:zone];
                        [wSelf.delegate setImages:[self imagesForIndexPath:indexPath] forIndexPath:indexPath];
                    }
                }];
                [observers addObject:observer];
        }
    }
    
    self.observers = [observers copy];
}

@end
