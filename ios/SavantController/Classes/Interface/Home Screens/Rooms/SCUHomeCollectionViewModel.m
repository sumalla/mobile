//
//  SCUHomeCollectionViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeCollectionViewModel.h"
#import "SCUDefaultCollectionViewCell.h"
#import "SCUStateReceiver.h"
#import "SCUInterface.h"
#import "SCUDataSourceModelPrivate.h"

#import <SavantControl/SavantControl.h>

static NSString *const SCUCollectionViewKeySectionObjects = @"SCUCollectionViewKeySectionObjects";

@interface SCUHomeCollectionViewModel () <StateDelegate>

@property NSArray *allRoomsDataSource;
@property NSDictionary *dataByRoom;
@property NSMutableDictionary *lightsAreOn;
@property NSMutableDictionary *fansAreOn;
@property NSMutableDictionary *activeService;
@property NSMutableDictionary *currentTemperature;
@property NSMutableDictionary *securityStatus;
@property NSMutableDictionary *observers;
@property NSMutableDictionary *images; /* { indexPath -> image } */
@property BOOL hasRoomGroups;
@property NSArray *roomGroups;

@end

@implementation SCUHomeCollectionViewModel

- (void)dealloc
{
    [self unregisterObservers];

    [[SavantControl sharedControl] unregisterForStates:self.statesToRegister forObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSMutableArray *mutableRooms = [NSMutableArray array];
        NSMutableDictionary *dataByRoom = [NSMutableDictionary dictionary];
        NSArray *roomGroups = [[SavantControl sharedControl].data allRoomGroups];
        self.images = [NSMutableDictionary dictionary];

        for (SAVRoomGroup *group in roomGroups)
        {
            NSArray *roomInfo = [self roomDataForGroup:group];
            dataByRoom[group.groupId] = roomInfo;
            [mutableRooms addObjectsFromArray:roomInfo];
        }

        // ungrouped rooms
        NSArray *roomInfo = [self roomDataForGroup:nil];
        if ([roomInfo count])
        {
            dataByRoom[[NSNull null]] = roomInfo;
            [mutableRooms addObjectsFromArray:roomInfo];
        }

        if ([dataByRoom count] > 1)
        {
            self.hasRoomGroups = YES;
        }

        self.dataByRoom = dataByRoom;
        self.allRoomsDataSource = mutableRooms;
        self.roomGroups = [dataByRoom allKeys];

        self.lightsAreOn = [NSMutableDictionary dictionary];
        self.fansAreOn = [NSMutableDictionary dictionary];
        self.activeService = [NSMutableDictionary dictionary];
        self.currentTemperature = [NSMutableDictionary dictionary];
        self.securityStatus = [NSMutableDictionary dictionary];
        self.observers = [NSMutableDictionary dictionary];

        self.filterRoomGroup = [[SAVSettings localSettings] objectForKey:@"CurrentRoomGroup"];

        [[SavantControl sharedControl] registerForStates:self.statesToRegister forObserver:self];
    }
    return self;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    for (NSString *room in self.lightsAreOn)
    {
        [self.delegate lightsAreOnChangedForIndexPath:[self indexPathForRoom:room]];
    }
    
    for (NSString *room in self.fansAreOn)
    {
        [self.delegate fansAreOnChangedForIndexPath:[self indexPathForRoom:room]];
    }

    for (NSString *room in self.activeService)
    {
        [self.delegate activeServiceChangedForIndexPath:[self indexPathForRoom:room]];
    }

    for (NSString *room in self.currentTemperature)
    {
        [self.delegate currentTemperatureChangedForIndexPath:[self indexPathForRoom:room]];
    }

    for (NSString *room in self.securityStatus)
    {
        [self.delegate securityStatusChangedForIndexPath:[self indexPathForRoom:room]];
    }
}

#pragma mark - Properties

- (NSArray *)dataSource
{
    NSArray *dataSource = nil;

    if (self.filterRoomGroup)
    {
        dataSource = self.dataByRoom[self.filterRoomGroup];
    }
    else
    {
        dataSource = self.allRoomsDataSource;
    }

    return dataSource;
}

- (NSString *)selectedRoomGroupName
{
    NSString *name = nil;

    if (self.filterRoomGroup == [NSNull null])
    {
        name = NSLocalizedString(@"Other", nil);
    }
    else if (!self.filterRoomGroup)
    {
        name = NSLocalizedString(@"All Rooms", nil);
    }
    else
    {
        name = self.filterRoomGroup;
    }

    return name;
}

- (void)setFilterRoomGroup:(id)filterRoomGroup
{
    _filterRoomGroup = filterRoomGroup;

    if (filterRoomGroup)
    {
        [[SAVSettings localSettings] setObject:filterRoomGroup forKey:@"CurrentRoomGroup"];
    }
    else
    {
        [[SAVSettings localSettings] removeObjectForKey:@"CurrentRoomGroup"];
    }

    [[SAVSettings localSettings] synchronize];
}

#pragma mark - Helpers

- (NSArray *)roomDataForGroup:(SAVRoomGroup *)roomGroup
{
    return [[[SavantControl sharedControl].data roomsInRoomGroup:roomGroup] arrayByMappingBlock:^id(SAVRoom *room) {
        return @{SCUDefaultCollectionViewCellKeyModelObject: room};
    }];
}

- (SAVService *)activeServiceForIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self roomForIndexPath:indexPath];

    return self.activeService[room.roomId];
}

- (BOOL)lightsAreOnForIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self roomForIndexPath:indexPath];

    return [self.lightsAreOn[room.roomId] boolValue];
}

- (BOOL)fansAreOnForIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self roomForIndexPath:indexPath];
    
    return [self.fansAreOn[room.roomId] boolValue];
}

- (NSString *)currentTemperatureForIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self roomForIndexPath:indexPath];

    return [SAVHVACEntity addDegreeSuffix:self.currentTemperature[room.roomId]];
}

- (BOOL)hasSecurityAlertForIndexPath:(NSIndexPath *)indexPath
{
    SAVRoom *room = [self roomForIndexPath:indexPath];

    return [self.securityStatus[room.roomId] integerValue] != 0;
}

- (SAVRoom *)roomForIndexPath:(NSIndexPath *)indexPath
{
    return [self modelObjectForIndexPath:indexPath][SCUDefaultCollectionViewCellKeyModelObject];
}

- (NSIndexPath *)indexPathForRoom:(NSString *)room
{
    NSIndexPath *indexPath = nil;

    NSInteger row = 0;

    for (NSDictionary *roomInfo in self.dataSource)
    {
        if ([[roomInfo[SCUDefaultCollectionViewCellKeyModelObject] roomId] isEqualToString:room])
        {
            indexPath = [NSIndexPath indexPathForItem:row inSection:0];
            break;
        }

        row++;
    }

    return indexPath;
}

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath isDefault:(BOOL *)isDefault
{
    [self loadObserverIfNecessaryForRoom:[self roomForIndexPath:indexPath].roomId];

    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.row + 1 inSection:indexPath.section];

    if ([self.dataSource count] > (NSUInteger)nextIndexPath.row)
    {
        [self loadObserverIfNecessaryForRoom:[self roomForIndexPath:nextIndexPath].roomId];

        NSIndexPath *nextNextIndexPath = [NSIndexPath indexPathForItem:nextIndexPath.row + 1 inSection:indexPath.section];

        if ([self.dataSource count] > (NSUInteger)nextNextIndexPath.row)
        {
            [self loadObserverIfNecessaryForRoom:[self roomForIndexPath:nextNextIndexPath].roomId];
        }
    }

    NSDictionary *dict = self.images[[self roomForIndexPath:indexPath].roomId];
    UIImage *image = nil;

    BOOL isDefaultImage = NO;

    if (dict)
    {
        image = dict[@"image"];
        isDefaultImage = [dict[@"default"] boolValue];
    }
    else
    {
        isDefaultImage = YES;
        image = [UIImage imageNamed:@"No_Image"];
    }

    if (isDefault)
    {
        *isDefault = isDefaultImage;
    }

    return image;
}

#pragma mark - State Management

- (NSArray *)statesToRegister
{
    NSMutableArray *states = [NSMutableArray array];

    for (NSDictionary *roomInfo in self.allRoomsDataSource)
    {
        SAVRoom *room = roomInfo[SCUDefaultCollectionViewCellKeyModelObject];
        NSString *roomName = [room roomId];

        [states addObject:[NSString stringWithFormat:@"%@.ActiveService", roomName]];
        [states addObject:[NSString stringWithFormat:@"%@.RoomLightsAreOn", roomName]];
        [states addObject:[NSString stringWithFormat:@"%@.RoomFansAreOn", roomName]];
        [states addObject:[NSString stringWithFormat:@"%@.RoomCurrentTemperature", roomName]];
        [states addObject:[NSString stringWithFormat:@"%@.SecurityStatus", roomName]];
    }

    return states;
}

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state hasSuffix:@"ActiveService"])
    {
        if ([stateUpdate.value length])
        {
            SAVService *service = [[SAVService alloc] initWithString:stateUpdate.value];

            if (service)
            {
                (self.activeService)[stateUpdate.scope] = service;
            }
        }
        else
        {
            [self.activeService removeObjectForKey:stateUpdate.scope];
        }

        [self.delegate activeServiceChangedForIndexPath:[self indexPathForRoom:stateUpdate.scope]];
    }
    else if ([stateUpdate.state hasSuffix:@"RoomLightsAreOn"])
    {
        (self.lightsAreOn)[stateUpdate.scope] = stateUpdate.value;

        [self.delegate lightsAreOnChangedForIndexPath:[self indexPathForRoom:stateUpdate.scope]];
    }
    else if ([stateUpdate.state hasSuffix:@"RoomFansAreOn"])
    {
        (self.fansAreOn)[stateUpdate.scope] = stateUpdate.value;
        
        [self.delegate fansAreOnChangedForIndexPath:[self indexPathForRoom:stateUpdate.scope]];
    }
    else if ([stateUpdate.state hasSuffix:@"RoomCurrentTemperature"])
    {
        NSString *currentTemp = nil;

        if ([stateUpdate.value length])
        {
            NSInteger value = [stateUpdate.value integerValue];
            if (value > 0)
            {
                currentTemp = [NSString stringWithFormat:@"%ld", (long)value];
            }
        }

        [self.currentTemperature setValue:currentTemp forKeyPath:stateUpdate.scope];

        [self.delegate currentTemperatureChangedForIndexPath:[self indexPathForRoom:stateUpdate.scope]];
    }
    else if ([stateUpdate.state hasSuffix:@"SecurityStatus"])
    {
        NSString *securityStatus = nil;

        if ([stateUpdate.value isKindOfClass:[NSString class]])
        {
            if ([stateUpdate.value length])
            {
                securityStatus = stateUpdate.value;
            }
        }
        else if ([stateUpdate.value isKindOfClass:[NSNumber class]])
        {
            securityStatus = [NSString stringWithFormat:@"%ld", (long)[stateUpdate.value integerValue]];
        }

        [self.securityStatus setValue:securityStatus forKeyPath:stateUpdate.scope];

        [self.delegate securityStatusChangedForIndexPath:[self indexPathForRoom:stateUpdate.scope]];
    }
}

#pragma mark - Collection View Model

- (void)loadObserverIfNecessaryForRoom:(NSString *)room
{
    if (self.observers[room])
    {
        return;
    }

    SAVWeakSelf;
    id observer = [[SavantControl sharedControl].imageModel addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeExtraLarge blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {

        SAVStrongWeakSelf;

        if (image)
        {
            sSelf.images[room] = @{@"image": image, @"default": @(isDefault)};
        }
        else
        {
            [sSelf.images removeObjectForKey:room];
        }

        NSIndexPath *indexPath = [sSelf indexPathForRoom:room];
        BOOL isDefaultImage = NO;
        UIImage *sendImage = [sSelf imageForIndexPath:indexPath isDefault:&isDefaultImage];
        [sSelf.delegate updateImage:sendImage forIndexPath:indexPath isDefault:isDefaultImage];
    }];

    self.observers[room] = observer;

}

- (void)unregisterObservers
{
    for (id observer in [self.observers allValues])
    {
        [[SavantControl sharedControl].imageModel removeObserver:observer];
    }

    [self.observers removeAllObjects];
}

- (id)modelObjectForSection:(NSInteger)section
{
    return self.dataSource[section];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    return self.dataSource[indexPath.row];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource count];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [SCUInterface sharedInstance].currentRoom = [self roomForIndexPath:indexPath];

    if ([self.delegate respondsToSelector:@selector(presentServiceDrawer:)])
    {
        [self.delegate presentServiceDrawer:YES];
    }

    if ([self.delegate respondsToSelector:@selector(presentFullscreenView:)])
    {
        [self.delegate presentFullscreenView:YES];
    }
}

#pragma mark - SCUHomePageCollectionViewControllerDelegate

- (void)willSwitchToRoom:(SAVRoom *)room
{
    [SCUInterface sharedInstance].currentRoom = room;
}

@end
