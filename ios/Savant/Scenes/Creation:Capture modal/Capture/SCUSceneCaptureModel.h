//
//  SCUSceneCaptureModel.h
//  SavantController
//
//  Created by Nathan Trapp on 8/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneRoomsListModel.h"

@protocol SCUSceneCaptureModelDelegate;

@interface SCUSceneCaptureModel : SCUSceneRoomsListModel

@property (weak) id <SCUSceneCaptureModelDelegate, SCUSceneRoomModelDelegate> delegate;

@property (nonatomic) NSMutableArray *selectedIndexPaths;

- (BOOL)indexPathIsSelected:(NSIndexPath *)indexPath;

@end

@protocol SCUSceneCaptureModelDelegate <NSObject>

- (void)toggleIndex:(NSIndexPath *)indexPath;
- (void)reloadIndex:(NSIndexPath *)indexPath;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)updateImage:(UIImage *)image forRow:(NSInteger)row;
- (void)reloadChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end