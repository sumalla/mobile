//
//  SCUSceneRoomListModelPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 8/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneRoomsListModel.h"
#import "SCUSceneCreationDataSourcePrivate.h"

@interface SCUSceneRoomsListModel ()

@property NSArray *rooms;
@property NSMutableDictionary *images;
@property NSArray *observers;
@property SAVSceneService *sceneService;

- (void)addRoom:(NSString *)room;
- (void)removeRoom:(NSString *)room;

@end