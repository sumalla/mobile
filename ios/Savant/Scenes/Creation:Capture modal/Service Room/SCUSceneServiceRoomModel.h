//
//  SCUSceneServiceRoomModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURoomDistributionModel.h"

typedef NS_ENUM(NSInteger, SCUSceneServiceRoomCellTypes)
{
    SCUSceneServiceRoomCellTypeVariant,
    SCUSceneServiceRoomCellTypeToggle,
    SCUSceneServiceRoomCellTypeSlider,
    SCUSceneServiceRoomCellTypeAudioOnly
};

@class SCUSlider, SAVScene, SCUSceneCreationViewController;

@interface SCUSceneServiceRoomModel : SCURoomDistributionModel

- (instancetype)initWithScene:(SAVScene *)scene andServiceGroup:(SAVServiceGroup *)serviceGroup;

@property SAVScene *scene;

- (void)addRoom:(NSString *)room;
- (void)removeRoom:(NSString *)room;

//- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath;

- (void)listenToSlider:(SCUSlider *)slider withParent:(NSIndexPath *)indexPath;
- (BOOL)hasSelectedRows;

- (void)doneEditing;

@end

