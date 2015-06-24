//
//  SCUSceneCaptureModel.m
//  SavantController
//
//  Created by Nathan Trapp on 8/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCaptureModel.h"
#import "SCUSceneRoomsListModelPrivate.h"
#import "SCUScenesRoomCell.h"
#import "SCUCaptureRoomCell.h"

typedef NS_ENUM(NSInteger, SCUSceneCapturePowerOffTypes)
{
    SCUSceneCapturePowerOffTypeMedia,
    SCUSceneCapturePowerOffTypeLighting,
    SCUSceneCapturePowerOffTypeHVAC
};

@interface SCUSceneCaptureModel ()

@property NSMutableDictionary *selectedServicesForRoom;
@property NSMutableDictionary *selectedPowerOffForRoom;

@property NSDictionary *servicesForRoom;
@property NSDictionary *powerOffForRoom;

@property (nonatomic, copy) NSArray *childrenDataSource;

@end

@implementation SCUSceneCaptureModel

- (void)loadObservers
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

- (void)loadDataIfNecessary
{
    [self loadObservers];

    NSMutableSet *rooms = [[NSMutableSet alloc] init];
    NSMutableDictionary *servicesForRoom = [NSMutableDictionary dictionary];
    NSMutableDictionary *powerOffForRoom = [NSMutableDictionary dictionary];

    self.selectedServicesForRoom = [NSMutableDictionary dictionary];
    self.selectedPowerOffForRoom = [NSMutableDictionary dictionary];

    NSMutableArray *dataSource = [NSMutableArray array];
    self.selectedIndexPaths = [NSMutableArray array];

    for (SAVSceneService *service in self.scene.services)
    {
        [rooms addObjectsFromArray:service.rooms];

        for (NSString *room in service.rooms)
        {
            NSHashTable *services = servicesForRoom[room];
            if (!services)
            {
                services = [NSHashTable weakObjectsHashTable];
                servicesForRoom[room] = services;
            }

            [services addObject:service];
        }
    }

    for (NSString *room in self.scene.avOff)
    {
        NSMutableArray *array = powerOffForRoom[room];
        if (!array)
        {
            array = [NSMutableArray array];
            powerOffForRoom[room] = array;
        }

        [array addObject:@(SCUSceneCapturePowerOffTypeMedia)];

        [rooms addObject:room];
    }

    for (NSString *room in self.scene.lightingOff)
    {
        NSMutableArray *array = powerOffForRoom[room];
        if (!array)
        {
            array = [NSMutableArray array];
            powerOffForRoom[room] = array;
        }

        [array addObject:@(SCUSceneCapturePowerOffTypeLighting)];

        [rooms addObject:room];
    }

    for (NSString *room in self.scene.hvacOff)
    {
        NSMutableArray *array = powerOffForRoom[room];
        if (!array)
        {
            array = [NSMutableArray array];
            powerOffForRoom[room] = array;
        }

        [array addObject:@(SCUSceneCapturePowerOffTypeHVAC)];

        [rooms addObject:room];
    }

    self.rooms = [[Savant data] sortedRoomsWithRooms:[rooms allObjects]];

    for (NSString *room in self.rooms)
    {
        [dataSource addObject:@{SCUDefaultTableViewCellKeyTitle:room}];
    }

    self.powerOffForRoom = powerOffForRoom;
    self.servicesForRoom = servicesForRoom;
    self.dataSource = dataSource;

    NSMutableArray *childrenDataSource = [NSMutableArray array];

    [dataSource enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [childrenDataSource addObject:[self _dataSourceBelowIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]]];
    }];

    self.childrenDataSource = childrenDataSource;
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    if ([self.selectedIndexPaths containsObject:indexPath])
    {
        [self.selectedIndexPaths removeObject:indexPath];
    }
    else
    {
        [self.selectedIndexPaths addObject:indexPath];
    }
}

- (void)selectChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    NSString *room = self.rooms[indexPath.row];
    id modelObject = [self modelObjectForChild:child belowIndexPath:indexPath][SCUDefaultTableViewCellKeyModelObject];

    if ([modelObject isKindOfClass:[NSArray class]])
    {
        for (SAVSceneService *service in modelObject)
        {
            NSHashTable *services = self.selectedServicesForRoom[room] ? self.selectedServicesForRoom[room] : [NSHashTable weakObjectsHashTable];

            if ([services containsObject:service])
            {
                if ([self.scene.lightingServices containsObject:service])
                {
                    for (SAVSceneService *lightingService in self.scene.lightingServices)
                    {
                        [services removeObject:lightingService];
                    }
                }
                else if ([self.scene.hvacServices containsObject:service])
                {
                    for (SAVSceneService *hvacService in self.scene.hvacServices)
                    {
                        [services removeObject:hvacService];
                    }
                }
                else
                {
                    [services removeObject:service];
                }
            }
            else
            {
                if ([self.scene.lightingServices containsObject:service])
                {
                    for (SAVSceneService *lightingService in self.scene.lightingServices)
                    {
                        [services addObject:lightingService];
                    }
                }
                else if ([self.scene.hvacServices containsObject:service])
                {
                    for (SAVSceneService *hvacService in self.scene.hvacServices)
                    {
                        [services addObject:hvacService];
                    }
                }
                else
                {
                    [services addObject:service];
                }
            }
            
            
            self.selectedServicesForRoom[room] = services;
        }
    }
    else
    {
        NSMutableArray *powerOff = self.selectedPowerOffForRoom[room] ? self.selectedPowerOffForRoom[room] : [NSMutableArray array];
        
        if ([powerOff containsObject:modelObject])
        {
            [powerOff removeObject:modelObject];
        }
        else
        {
            [powerOff addObject:modelObject];
        }
        
        self.selectedPowerOffForRoom[room] = powerOff;
    }
    
    [self.delegate reloadIndex:[self absoluteIndexPathForRelativeChild:child belowIndexPath:indexPath]];
    [self.delegate reloadIndex:[self absoluteIndexPathForRelativeIndexPath:indexPath]];
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *modelObject = [[super modelObjectForIndexPath:indexPath] mutableCopy];
    modelObject[SCUScenesRoomCellCellKeySelected] = @([self indexPathIsSelected:indexPath]);

    if ([self cellTypeForIndexPath:indexPath] == 1)
    {
        modelObject[SCUCaptureRoomCellKeyChevronDirection] = [self.expandedIndexPaths containsObject:indexPath] ? @(SCUCaptureRoomCellChevronDirectionUp) : @(SCUCaptureRoomCellChevronDirectionDown);
    }

    return modelObject;
}

- (NSArray *)dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSArray *array = self.childrenDataSource[indexPath.row];
    NSString *room = self.rooms[indexPath.row];

    for (NSMutableDictionary *dict in array)
    {
        id modelObject = dict[SCUDefaultTableViewCellKeyModelObject];

        if ([modelObject isKindOfClass:[NSArray class]])
        {
            SAVSceneService *service = nil;

            for (SAVSceneService *ss in modelObject)
            {
                if ([ss.rooms containsObject:room])
                {
                    service = ss;
                    break;
                }
            }

            dict[SCUDefaultTableViewCellKeyAccessoryType] = [self serviceIsSelected:service inRoom:room] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone);
        }
        else
        {
            SCUSceneCapturePowerOffTypes type = [modelObject integerValue];

            dict[SCUDefaultTableViewCellKeyAccessoryType] = [self powerOffIsSelectedForType:type inRoom:room] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone);
        }
    }

    return array;
}

- (NSArray *)_dataSourceBelowIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *dataSource = [NSMutableArray array];

    NSString *room = self.rooms[indexPath.row];
    NSArray *powerOff = self.powerOffForRoom[room];
    NSArray *services = [self.servicesForRoom[room] allObjects];

    BOOL hasLights = NO;
    BOOL hasHVAC = NO;

    NSMutableArray *serviceGroups = [NSMutableArray array];

    for (SAVSceneService *service in services)
    {
        NSString *title = nil;
        NSString *iconName = nil;
        NSArray *serviceObject = nil;

        if ([self.scene.lightingServices containsObject:service])
        {
            if (hasLights)
            {
                continue;
            }

            service.serviceID = @"SVC_ENV_LIGHTING";

            title = service.service.displayName;
            iconName = service.service.iconName;

            hasLights = YES;

            serviceObject = @[service];
        }
        else if ([self.scene.hvacServices containsObject:service])
        {
            if (hasHVAC)
            {
                continue;
            }

            title = service.service.displayName;
            iconName = service.service.iconName;

            hasHVAC = YES;

            serviceObject = @[service];
        }
        else
        {
            SAVServiceGroup *serviceGroup = [self.scene serviceGroupForSceneService:service];

            if (![serviceGroups containsObject:serviceGroup] && serviceGroup)
            {
                [serviceGroups addObject:serviceGroup];

                title = serviceGroup.alias;
                iconName = serviceGroup.iconName;

                NSMutableArray *sceneServices = [NSMutableArray array];

                for (SAVService *service in serviceGroup.services)
                {
                    [sceneServices addObject:[self.scene sceneServiceForService:service]];
                }

                serviceObject = [sceneServices copy];
            }
            else
            {
                continue;
            }
        }

        if (title && serviceObject)
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle: title,
                                                  SCUDefaultTableViewCellKeyAccessoryType: [self serviceIsSelected:service inRoom:room] ? @(UITableViewCellAccessoryCheckmark) : @(UITableViewCellAccessoryNone),
                                                  SCUDefaultTableViewCellKeyModelObject: serviceObject} mutableCopy];

            UIImage *icon = [UIImage imageNamed:iconName];

            if (icon)
            {
                modelObject[SCUDefaultTableViewCellKeyImage] = icon;
                modelObject[SCUDefaultTableViewCellKeyImageTintColor] = [[SCUColors shared] color04];
            }
            
            [dataSource addObject:modelObject];
        }
    }

    for (NSNumber *t in powerOff)
    {
        SCUSceneCapturePowerOffTypes type = [t integerValue];

        NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyModelObject: t} mutableCopy];

        switch (type)
        {
            case SCUSceneCapturePowerOffTypeLighting:
                modelObject[SCUDefaultTableViewCellKeyTitle] = NSLocalizedString(@"Lights Off", nil);
                modelObject[SCUDefaultTableViewCellKeyImage] = [UIImage imageNamed:@"Lighting"];
                break;
            case SCUSceneCapturePowerOffTypeHVAC:
                modelObject[SCUDefaultTableViewCellKeyTitle] = NSLocalizedString(@"Climate Off", nil);
                modelObject[SCUDefaultTableViewCellKeyImage] = [UIImage imageNamed:@"Climate"];
                break;
            case SCUSceneCapturePowerOffTypeMedia:
                modelObject[SCUDefaultTableViewCellKeyTitle] = NSLocalizedString(@"Media Off", nil);
                modelObject[SCUDefaultTableViewCellKeyImage] = [UIImage imageNamed:@"Media"];
                break;
        }

        modelObject[SCUDefaultTableViewCellKeyImageTintColor] = [[SCUColors shared] color04];

        [dataSource addObject:modelObject];
    }

    return dataSource;
}

- (NSUInteger)cellTypeForChild:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath
{
    return 0;
}

- (BOOL)powerOffIsSelectedForType:(SCUSceneCapturePowerOffTypes)type inRoom:(NSString *)room
{
    return [self.selectedPowerOffForRoom[room] containsObject:@(type)];
}

- (BOOL)serviceIsSelected:(SAVSceneService *)service inRoom:(NSString *)room
{
    NSHashTable *services = self.selectedServicesForRoom[room];

    return [services containsObject:service];
}

- (BOOL)hasSelectedRows
{
    return [self.selectedServicesForRoom count] || [self.selectedPowerOffForRoom count] ? YES : NO;
}

- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath
{
    NSString *room = self.rooms[indexPath.row];

    return [self.selectedServicesForRoom[room] count] || [self.selectedPowerOffForRoom[room] count] ? YES : NO;
}

- (void)addRoom:(NSString *)room
{
    if (self.servicesForRoom[room])
    {
        self.selectedServicesForRoom[room] = [self.servicesForRoom[room] mutableCopy];
    }

    if (self.powerOffForRoom[room])
    {
        self.selectedPowerOffForRoom[room] = [self.powerOffForRoom[room] mutableCopy];
    }
}

- (void)removeRoom:(NSString *)room
{
    [self.selectedServicesForRoom removeObjectForKey:room];
    [self.selectedPowerOffForRoom removeObjectForKey:room];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.rooms indexOfObject:room] inSection:0];
    if ([self.expandedIndexPaths containsObject:indexPath])
    {
        [self.delegate toggleIndex:indexPath];
    }
}

- (void)doneEditing
{
    for (SAVSceneService *service in self.scene.avServices)
    {
        //-------------------------------------------------------------------
        // Do some hacks on SMS to save/recall the current queue.
        //-------------------------------------------------------------------
        if ([service.service.serviceId containsString:@"SAVANTMEDIAAUDIO"])
        {
            SAVMediaRequestGenerator *generator = [SAVMediaRequestGenerator mediaRequestGeneratorFromService:service.service];
            SAVMediaRequest *savePreset = [generator mediaRequest];
            savePreset.query = @"SaveQueue";
            savePreset.arguments = @{@"QueueName": [NSString stringWithFormat:@"savantqueue%@", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]]};

            [[Savant control] sendMediaRequest:savePreset];

            SAVMediaRequest *recallPreset = [savePreset copy];
            recallPreset.query = @"RecallQueue";
            service.mediaNode = [recallPreset dictionaryRepresentation];
        }

        for (NSString *room in [service.rooms copy])
        {
            if (![self.selectedServicesForRoom[room] containsObject:service])
            {
                [service.rooms removeObject:room];
                [self.scene.volume removeObjectForKey:room];

                [self.scene.avPower[room] removeAllObjects];
            }
        }

        if (![service.rooms count])
        {
            [self.scene removeAVSceneService:service];
        }
    }

    for (SAVSceneService *service in self.scene.lightingServices)
    {
        for (NSString *room in [service.rooms copy])
        {
            if (![self.selectedServicesForRoom[room] containsObject:service])
            {
                [service.rooms removeObject:room];
            }
        }

        if (![service.rooms count])
        {
            [self.scene removeLightingSceneService:service];
        }
    }

    for (SAVSceneService *service in self.scene.hvacServices)
    {
        for (NSString *room in [service.rooms copy])
        {
            if (![self.selectedServicesForRoom[room] containsObject:service])
            {
                [service.rooms removeObject:room];
            }
        }

        if (![service.rooms count])
        {
            [self.scene removeHVACSceneService:service];
        }
    }

    for (NSString *room in self.rooms)
    {
        NSArray *powerOff = self.selectedPowerOffForRoom[room];

        if (![powerOff containsObject:@(SCUSceneCapturePowerOffTypeMedia)] &&
            ![self.scene.avPower[room] count])
        {
            [self.scene.avPower removeObjectForKey:room];
        }

        if (![powerOff containsObject:@(SCUSceneCapturePowerOffTypeLighting)])
        {
            [self.scene.lightingOff removeObject:room];
        }

        if (![powerOff containsObject:@(SCUSceneCapturePowerOffTypeHVAC)])
        {
            [self.scene.hvacOff removeObject:room];
        }
    }
}

@end
