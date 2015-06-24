//
//  SCUNotificationRoomsListViewModel.m
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationRoomsListViewModel.h"
#import "SCUNotificationRoomsListTableViewController.h"
#import "SavantControl.h"
#import "SCUScenesRoomCell.h"

@interface SCUNotificationRoomsListViewModel ()

@property (nonatomic) NSArray *dataSource;

@end

@implementation SCUNotificationRoomsListViewModel

- (instancetype)initWithNotification:(SAVNotification *)notification
{
    self = [super initWithNotification:notification];
    if (self)
    {
        self.rooms = [[SavantControl sharedControl].data allRoomIds];
        
        NSString *hasService = nil;
        
        switch (notification.serviceType)
        {
            case SAVNotificationServiceTypeHumidity:
                hasService = @"hasHVAC";
                break;
            case SAVNotificationServiceTypeTemperature:
                hasService = @"hasHVAC";
                break;
            case SAVNotificationServiceTypeLighting:
                hasService = @"hasLighting";
                break;
            case SAVNotificationServiceTypeEntertainment:
                hasService = @"hasAV";
                break;
        }
        
        NSArray *unfilteredRooms = [[SavantControl sharedControl].data allRooms];

        self.rooms = [unfilteredRooms arrayByMappingBlock:^id(SAVRoom *object) {
            return [[object valueForKey:hasService] boolValue] ? object.roomId : nil;
        }];
        
        if (![notification.rooms count])
        {
            self.notification.rooms = [self.rooms mutableCopy];
        }
        
        NSMutableArray *dataSource = [NSMutableArray array];
        
        for (NSString *room in self.rooms)
        {
            NSMutableDictionary *modelObject = [@{SCUDefaultTableViewCellKeyTitle:room} mutableCopy];
            
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
    
    for (NSString *room in self.rooms)
    {
        SAVWeakSelf;
        id observer = [[SavantControl sharedControl].imageModel addObserverForKey:room type:SAVImageTypeRoomImage size:SAVImageSizeMedium blurred:NO andCompletionHandler:^(UIImage *image, BOOL isDefault)
        {
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
    
    if (self.notification)
    {
        selected = [self.notification.rooms containsObject:room];
    }
    
    return selected;
}

- (BOOL)hasSelectedRows
{
    BOOL hasSelected = NO;
    
    if (self.notification)
    {
        hasSelected = [self.notification.rooms count] ? YES : NO;
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
    if (self.notification.rooms)
    {
        [self.notification.rooms addObject:room];
    }
    else
    {
        self.notification.rooms = [[NSMutableArray alloc] initWithObjects:room, nil];
    }
}

- (void)removeRoom:(NSString *)room
{
    if (self.notification)
    {
        if ([self.notification.rooms containsObject:room])
        {
            [self.notification.rooms removeObject:room];
        }
    }
}

- (void)doneEditing
{
    if (self.notification && [self.notification.rooms count])
    {
        if ([self.notification.rooms count] == [self.rooms count])
        {
            self.notification.rooms = nil;
        }
    }
}

@end
