//
//  SAVNowPlayingManager.m
//  Savant
//
//  Created by Cameron Pulsford on 5/19/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SAVNowPlayingManagerPrivate.h"
#import "Savant.h"
#import "SAVNowPlayingStatusPrivate.h"
@import Extensions;

NSString * const SAVStateNameArtistName = @"CurrentArtistName";
NSString * const SAVStateNameAlbumName = @"CurrentAlbumName";
NSString * const SAVStateNameSongName = @"CurrentSongName";

typedef void (^SAVNowPlayingManagerStatusCallback)(id<SAVNowPlayingManagerDelegate> o, NSString *r);

@interface SAVNowPlayingManager () <ActiveServiceObserver, StateDelegate>

@property (nonatomic) NSArray *stateNames;
@property (nonatomic) NSMutableDictionary *roomObservers;
@property (nonatomic) NSHashTable *globalObservers;
@property (nonatomic) NSArray *rooms;
@property (nonatomic) NSMutableDictionary *statuses; // { component.logical_component: status }
@property (nonatomic) NSMutableDictionary *serviceToRooms; // { component.logical_component: [rooms] }
@property (nonatomic) NSMutableDictionary *roomToService; // { room: component.logical_component }

@end

@implementation SAVNowPlayingManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.stateNames = @[SAVStateNameArtistName, SAVStateNameAlbumName, SAVStateNameSongName];
        self.roomObservers = [NSMutableDictionary dictionary];
        self.globalObservers = [NSHashTable weakObjectsHashTable];
        self.rooms = [[Savant data] allRoomIds];
        self.statuses = [NSMutableDictionary dictionary];
        self.serviceToRooms = [NSMutableDictionary dictionary];
        self.roomToService = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)addNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer forRoom:(NSString *)room
{
    NSParameterAssert([room length]);
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVNowPlayingManagerDelegate)]);
    
    NSHashTable *observers = self.roomObservers[room];
    
    if (!observers)
    {
        observers = [NSHashTable weakObjectsHashTable];
        self.roomObservers[room] = observers;
    }
    
    [observers addObject:observer];
    
    NSString *service = self.roomToService[room];
    SAVNowPlayingStatus *status = self.statuses[service];
    
    if (status)
    {
        if (status.artist)
        {
            [self callbackForService:service name:SAVStateNameArtistName value:status.artist](observer, room);
        }
        
        if (status.album)
        {
            [self callbackForService:service name:SAVStateNameAlbumName value:status.album](observer, room);
        }
        
        if (status.song)
        {
            [self callbackForService:service name:SAVStateNameSongName value:status.song](observer, room);
        }
    }
}

- (void)removeNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer forRoom:(NSString *)room
{
    NSParameterAssert([room length]);
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVNowPlayingManagerDelegate)]);
    
    NSHashTable *observers = self.roomObservers[room];
    [observers removeObject:observer];
    
    if (![observers count])
    {
        [self.roomObservers removeObjectForKey:room];
    }
}

- (void)addGlobalNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVNowPlayingManagerDelegate)]);
    [self.globalObservers addObject:observer];
}

- (void)removeNowPlayingObserver:(id<SAVNowPlayingManagerDelegate>)observer
{
    NSParameterAssert([observer conformsToProtocol:@protocol(SAVNowPlayingManagerDelegate)]);
    
    [self.globalObservers removeObject:observer];
    
    for (NSString *room in self.rooms)
    {
        [self removeNowPlayingObserver:observer forRoom:room];
    }
}

- (SAVNowPlayingStatus *)nowPlayingStatusForRoom:(NSString *)room
{
    return self.statuses[self.roomToService[room]];
}

- (NSDictionary *)globalNowPlayingStatus
{
    NSMutableDictionary *statuses = [NSMutableDictionary dictionary];
    
    for (NSString *room in self.rooms)
    {
        SAVNowPlayingStatus *status = [self nowPlayingStatusForRoom:room];
        
        if (status)
        {
            statuses[room] = status;
        }
    }
    
    return [statuses copy];
}

#pragma mark - ActiveServiceObserver

- (void)room:(NSString *)roomId didUpdateActiveService:(SAVService *)service
{
    if (service)
    {
        [self handleNewActiveService:service forRoom:roomId];
    }
    else
    {
        [self removeActiveServiceForRoom:roomId];
    }
}

#pragma mark - StateDelegate

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    NSString *service = stateUpdate.scope;
    NSString *stateName = stateUpdate.stateName;
    SAVNowPlayingStatus *status = self.statuses[service];
    [status setObject:stateUpdate.value forKey:stateName];
    
    void (^block)(id<SAVNowPlayingManagerDelegate> o, NSString *r) = nil;
    
    for (NSString *room in self.serviceToRooms[service])
    {
        for (id<SAVNowPlayingManagerDelegate> observer in self.roomObservers[room])
        {
            //-------------------------------------------------------------------
            // Only compute the callback once per loop. If it could not be
            // computed, break out of this method.
            //-------------------------------------------------------------------
            if (!block)
            {
                block = [self callbackForService:service name:stateName value:stateUpdate.value];
                
                if (!block)
                {
                    return;
                }
            }
            
            block(observer, room);
        }
    }
}

#pragma mark - Private

- (void)reset
{
    self.roomObservers = [NSMutableDictionary dictionary];
    self.globalObservers = [NSHashTable weakObjectsHashTable];
    self.rooms = [[Savant data] allRoomIds];
    self.statuses = [NSMutableDictionary dictionary];
    self.serviceToRooms = [NSMutableDictionary dictionary];
    self.roomToService = [NSMutableDictionary dictionary];
    
    [[Savant states] addActiveServiceObserver:self];
    
    for (NSString *room in self.rooms)
    {
        [self room:room didUpdateActiveService:[[Savant states] activeServiceForRoom:room]];
    }
}

- (void)handleNewActiveService:(SAVService *)fullService forRoom:(NSString *)room
{
    NSString *service = [NSString stringWithFormat:@"%@.%@", fullService.component, fullService.logicalComponent];
    
    if (self.roomToService[room])
    {
        [self removeActiveServiceForRoom:room];
    }
    
    if (![SAVService isLMQService:fullService.serviceId])
    {
        return;
    }
    
    self.roomToService[room] = service;
    
    NSMutableArray *rooms = self.serviceToRooms[service];
    
    if (!rooms)
    {
        rooms = [NSMutableArray array];
        self.serviceToRooms[service] = rooms;
        [self registerForService:service];
        SAVNowPlayingStatus *status = [[SAVNowPlayingStatus alloc] init];
        self.statuses[service] = status;
    }
    
    [rooms addObject:room];
}

- (void)removeActiveServiceForRoom:(NSString *)room
{
    NSString *service = self.roomToService[room];
    [self.roomToService removeObjectForKey:room];
    
    if (service)
    {
        NSMutableArray *rooms = self.serviceToRooms[service];
        [rooms removeObject:room];
        
        if (![rooms count])
        {
            [self unregisterForService:service];
            [self.serviceToRooms removeObjectForKey:service];
            [self.statuses removeObjectForKey:service];
        }
    }
}

- (void)registerForService:(NSString *)service
{
    [[Savant states] registerForStates:[self fullyQualifiedStatesForService:service] forObserver:self];
}

- (void)unregisterForService:(NSString *)service
{
    [[Savant states] unregisterForStates:[self fullyQualifiedStatesForService:service] forObserver:self];
}

- (NSArray *)fullyQualifiedStatesForService:(NSString *)service
{
    return [self.stateNames arrayByMappingBlock:^id(NSString *stateName) {
        return [NSString stringWithFormat:@"%@.%@", service, stateName];
    }];
}

- (SAVNowPlayingManagerStatusCallback)callbackForService:(NSString *)service name:(NSString *)stateName value:(id)value
{
    if ([stateName isEqualToString:SAVStateNameArtistName])
    {
        return ^(id<SAVNowPlayingManagerDelegate> o, NSString *r){
            if ([o respondsToSelector:@selector(artistDidUpdate:inRoom:)])
            {
                [o artistDidUpdate:value inRoom:r];
            }
        };
    }
    else if ([stateName isEqualToString:SAVStateNameAlbumName])
    {
        return ^(id<SAVNowPlayingManagerDelegate> o, NSString *r){
            if ([o respondsToSelector:@selector(albumDidUpdate:inRoom:)])
            {
                [o albumDidUpdate:value inRoom:r];
            }
        };
    }
    else if ([stateName isEqualToString:SAVStateNameSongName])
    {
        return ^(id<SAVNowPlayingManagerDelegate> o, NSString *r){
            if ([o respondsToSelector:@selector(songDidUpdate:inRoom:)])
            {
                [o songDidUpdate:value inRoom:r];
            }
        };
    }
    
    return nil;
}

@end
