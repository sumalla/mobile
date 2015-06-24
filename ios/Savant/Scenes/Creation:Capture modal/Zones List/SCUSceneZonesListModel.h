//
//  SCUSceneZonesListModel.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"

@protocol SCUSceneZoneModelDelegate;

@interface SCUSceneZonesListModel : SCUSceneCreationDataSource

@property (weak) id <SCUSceneZoneModelDelegate> delegate;

- (NSArray *)imagesForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)zoneForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath;
@property (nonatomic, readonly) BOOL hasSelectedRows;

- (void)addZone:(NSString *)zone;
- (void)removeZone:(NSString *)zone;

@end

@protocol SCUSceneZoneModelDelegate <NSObject>

- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end