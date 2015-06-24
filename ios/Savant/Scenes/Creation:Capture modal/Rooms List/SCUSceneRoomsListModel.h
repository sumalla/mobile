//
//  SCUSceneRoomsListModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDataSource.h"

@protocol SCUSceneRoomModelDelegate;

@interface SCUSceneRoomsListModel : SCUSceneCreationDataSource

@property (weak) id <SCUSceneRoomModelDelegate> delegate;

- (UIImage *)imageForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath;
@property (nonatomic, readonly) BOOL hasSelectedRows;

- (void)addRoom:(NSString *)room;
- (void)removeRoom:(NSString *)room;

@end

@protocol SCUSceneRoomModelDelegate <NSObject>

- (void)updateImage:(UIImage *)image forRow:(NSInteger)row;
- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath;

@end