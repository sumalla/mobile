//
//  SCUNotificationZonesListViewModel.h
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

@class SAVScene;
@class SAVService;
@class SAVSceneService;

@protocol SCUNotificationZonesListModelDelegate <NSObject>

- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUNotificationZonesListViewModel : SCUNotificationCreationDataSource

@property (weak) id <SCUNotificationZonesListModelDelegate> delegate;

- (NSArray *)imagesForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)zoneForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath;

@property (nonatomic, readonly) BOOL hasSelectedRows;

- (void)addZone:(NSString *)zone;
- (void)removeZone:(NSString *)zone;

@property NSArray *zones;
@property NSMutableDictionary *images;
@property NSDictionary *zoneToRooms;
@property NSArray *observers;
@property NSArray *sceneServices;

@end



