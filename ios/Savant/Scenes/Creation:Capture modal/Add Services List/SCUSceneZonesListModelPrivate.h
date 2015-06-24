//
//  SCUSceneZonesListModelPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneZonesListModel.h"
#import "SCUSceneCreationDataSourcePrivate.h"

@interface SCUSceneZonesListModel ()

@property NSArray *zones;
@property NSMutableDictionary *images;
@property NSDictionary *zoneToRooms;
@property NSArray *observers;
@property NSArray *sceneServices;

- (void)addZone:(NSString *)zone;
- (void)removeZone:(NSString *)zone;

@end
