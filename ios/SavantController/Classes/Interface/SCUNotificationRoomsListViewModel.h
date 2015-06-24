//
//  SCUNotificationRoomCaptureViewModel.h
//  SavantController
//
//  Created by Julian Locke on 1/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUNotificationCreationDataSource.h"

@class SAVScene;
@class SAVService;
@class SAVSceneService;

@protocol SCUNotifcationRoomsListModelDelegate <NSObject>

- (void)updateImage:(UIImage *)image forRow:(NSInteger)row;
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUNotificationRoomsListViewModel : SCUNotificationCreationDataSource

@property (weak) id <SCUNotifcationRoomsListModelDelegate> delegate;

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath;

@property (nonatomic, readonly) BOOL hasSelectedRows;

- (void)addRoom:(NSString *)room;
- (void)removeRoom:(NSString *)room;

@property NSArray *rooms;
@property NSMutableDictionary *images;
@property NSArray *observers;

@end

