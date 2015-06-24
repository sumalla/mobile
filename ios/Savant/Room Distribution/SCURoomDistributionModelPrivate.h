//
//  SCURoomDistributionModelPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 10/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomDistributionModel.h"
#import "SCUToggleSwitchTableViewCell.h"
#import "SCUVolumeTableViewCell.h"
#import "SCUDataSourceModelPrivate.h"

@import SDK;

@interface SCURoomDistributionModel ()

@property NSArray *rooms;
@property NSMutableDictionary *serviceForRoom;
@property NSMutableDictionary *numberOfChildren;
@property NSArray *dataSource;
@property SAVServiceGroup *serviceGroup;
@property NSArray *activeRooms;
@property NSIndexPath *audioOnlyIndexPath;

- (BOOL)childIsVariantPicker:(NSIndexPath *)child belowIndexPath:(NSIndexPath *)indexPath;
- (void)calculateNumberOfChildrenUnderIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForRoom:(NSString *)room;
- (BOOL)serviceIsActive:(SAVService *)service;

- (BOOL)sendCommands;
- (BOOL)showMasterVolume;

- (BOOL)indexPathIsAudioOnly:(NSIndexPath *)indexPath;

@end

@interface SCURoomDistributionModel (Optional)

- (void)loadAdditionalData;
- (void)addRoom:(NSString *)room;
- (void)removeRoom:(NSString *)room;

@end