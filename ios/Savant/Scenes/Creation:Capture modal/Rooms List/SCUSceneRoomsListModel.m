//
//  SCUSceneRoomsListModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneRoomsListModelPrivate.h"
#import "SCUScenesRoomCell.h"

@implementation SCUSceneRoomsListModel

- (instancetype)initWithScene:(SAVScene *)scene andService:(SAVService *)service
{
    self = [super initWithScene:scene andService:service];
    if (self)
    {
        if (service)
        {
            if ([service.serviceId isEqualToString:@"SVC_ENV_LIGHTING"])
            {
                self.rooms = [[[[Savant data] allRooms] filteredArrayUsingBlock:^BOOL(SAVRoom *room) {
                    return room.hasLighting || room.hasFans;
                }] arrayByMappingBlock:^id(SAVRoom *room) {
                    return room.roomId;
                }];
            }
            else if ([service.serviceId isEqualToString:@"SVC_ENV_SHADE"])
            {
                self.rooms = [[[[Savant data] allRooms] filteredArrayUsingBlock:^BOOL(SAVRoom *room) {
                    return room.hasShades;
                }] arrayByMappingBlock:^id(SAVRoom *room) {
                    return room.roomId;
                }];
            }
            else
            {
                SAVService *filterService = nil;

                if ([service.serviceId hasPrefix:@"SVC_ENV"])
                {
                    filterService = [[SAVService alloc] initWithZone:nil component:nil logicalComponent:nil variantId:nil serviceId:service.serviceId];
                }
                else
                {
                    filterService = service;
                }

                self.rooms = [[Savant data] zonesWithService:filterService];
            }
        }
        else
        {
            self.rooms = [[Savant data] allRoomIds];
        }

        NSMutableArray *dataSource = [NSMutableArray array];

        for (NSString *room in self.rooms)
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle:room} mutableCopy];

            if (self.service.logicalComponent)
            {
                modelObject[SCUDefaultTableViewCellKeyAccessoryType] = @(UITableViewCellAccessoryDisclosureIndicator);
            }

            [dataSource addObject:modelObject];
        }

        self.dataSource = dataSource;
        self.sceneService = [scene sceneServiceForService:service];
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

    for (NSString *room in self.rooms)
    {
        SAVWeakSelf;
        id observer = [[Savant images] addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault) {

            if (image)
            {
                wSelf.images[room] = image;
            }
            else
            {
                [wSelf.images removeObjectForKey:room];
            }

            [wSelf.delegate updateImage:image forRow:[wSelf.rooms indexOfObject:room]];
        }];

        [observers addObject:observer];
    }

    self.observers = [observers copy];
}

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath
{
    return self.images[self.rooms[indexPath.row]];
}

- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = nil;
    if ((NSInteger)[self.rooms count] > indexPath.row)
    {
        room = self.rooms[indexPath.row];
    }
    return room;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
    return [NSLocalizedString(@"Rooms", nil) uppercaseString];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate selectRowAtIndexPath:indexPath];
}

- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath
{
    BOOL selected = NO;

    NSString *room = self.rooms[indexPath.row];

    if (self.sceneService)
    {
        selected = [self.sceneService.rooms containsObject:room];
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            selected = [self.scene.hvacOff containsObject:room];
        }
        else if ([self.service.serviceId hasPrefix:@"SVC_AV"])
        {
            selected = [self.scene.avOff containsObject:room];
        }
        else
        {
            selected = [self.scene.lightingOff containsObject:room];
        }
    }

    return selected;
}

- (BOOL)hasSelectedRows
{
    BOOL hasSelected = NO;

    if (self.sceneService)
    {
        hasSelected = [self.sceneService.rooms count] ? YES : NO;
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            hasSelected = [self.scene.hvacOff count] ? YES : NO;
        }
        else if ([self.service.serviceId hasPrefix:@"SVC_AV"])
        {
            hasSelected = [self.scene.avOff count] ? YES : NO;
        }
        else
        {
            hasSelected = [self.scene.lightingOff count] ? YES : NO;
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

    modelObject[SCUScenesRoomCellCellKeySelected] = @([self indexPathIsSelected:indexPath]);

    return modelObject;
}

- (void)addRoom:(NSString *)room
{
    if (self.sceneService)
    {
        [self.sceneService.rooms addObject:room];

        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            [self.scene.hvacOff removeObject:room];
        }
        else if ([self.service.serviceId hasPrefix:@"SVC_AV"])
        {
            [self.scene.avPower removeObjectForKey:room];
        }
        else
        {
            [self.scene.lightingOff removeObject:room];
        }
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            for (SAVSceneService *sceneService in [self.scene.hvacServices copy])
            {
                [sceneService.rooms removeObject:room];

                if (![sceneService.rooms count])
                {
                    [self.scene removeHVACSceneService:sceneService];
                }
            }

            [self.scene.hvacOff addObject:room];
        }
        else if ([self.service.serviceId hasPrefix:@"SVC_AV"])
        {
            for (SAVSceneService *sceneService in [self.scene.avServices copy])
            {
                [sceneService.rooms removeObject:room];

                if (![sceneService.rooms count])
                {
                    [self.scene removeAVSceneService:sceneService];
                }
            }

            self.scene.avPower[room] = [@{} mutableCopy];
        }
        else
        {
            for (SAVSceneService *sceneService in [self.scene.lightingServices copy])
            {
                [sceneService.rooms removeObject:room];

                if (![sceneService.rooms count])
                {
                    [self.scene removeLightingSceneService:sceneService];
                }
            }

            [self.scene.lightingOff addObject:room];
        }
    }
}

- (void)removeRoom:(NSString *)room
{
    if (self.sceneService)
    {
        if ([self.scene.lightingServices containsObject:self.sceneService])
        {
            for (SAVSceneService *service in self.scene.lightingServices)
            {
                [service.rooms removeObject:room];
            }
        }
        else
        {
            NSMutableDictionary *roomDict = self.scene.avPower[room];
            if (!roomDict)
            {
                roomDict = [NSMutableDictionary dictionary];
                self.scene.avPower[room] = roomDict;
            }

            [self.sceneService.rooms removeObject:room];
            [roomDict removeObjectForKey:self.service.serviceString];

            if (![roomDict count])
            {
                [self.scene.avPower removeObjectForKey:room];
            }
        }
    }
    else
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            [self.scene.hvacOff removeObject:room];
        }
        else if ([self.service.serviceId hasPrefix:@"SVC_AV"])
        {
            [self.scene.avPower removeObjectForKey:room];
        }
        else
        {
            [self.scene.lightingOff removeObject:room];
        }
    }
}

- (void)doneEditing
{
    if (self.sceneService && ![self.sceneService.rooms count])
    {
        if ([self.service.serviceId isEqualToString:@"SVC_ENV_HVAC"])
        {
            [self.scene removeHVACSceneService:self.sceneService];
        }
        else
        {
            [self.scene removeLightingSceneService:self.sceneService];
        }
    }
}

@end
