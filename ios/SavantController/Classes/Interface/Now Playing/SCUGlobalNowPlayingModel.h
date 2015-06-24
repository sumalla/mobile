//
//  SCUNowPlayingModel.h
//  SavantController
//
//  Created by Nathan Trapp on 8/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

typedef NS_ENUM(NSInteger, SCUGlobalNowPlayingCellTypes)
{
    SCUGlobalNowPlayingCellType_Status,
    SCUGlobalNowPlayingCellType_Volume,
    SCUGlobalNowPlayingCellType_Transports,
    SCUGlobalNowPlayingCellType_Distribute,
    SCUGlobalNowPlayingCellType_Toggle
};

@protocol SCUGlobalNowPlayingModelDelegate;
@class SAVServiceGroup, SAVService;

@interface SCUGlobalNowPlayingModel : SCUExpandableDataSourceModel

@property (weak) id <SCUGlobalNowPlayingModelDelegate> delegate;

- (NSString *)statusStringForServiceGroup:(SAVServiceGroup *)service;
- (NSString *)statusStringForService:(SAVService *)service;
- (UIImage *)artworkForSection:(NSInteger)section;
- (void)expandRoomVolumeForSection:(NSInteger)section;
- (void)collapseRoomVolumeForSection:(NSInteger)section;
- (void)autoExpandRoomVolumeForSection:(NSInteger)section;
- (void)userInteractionDetected;
- (NSIndexPath *)volumeIndexPathForSection:(NSInteger)section;
- (BOOL)toggleRoomVolumeForSection:(NSInteger)section;
- (void)powerOffService:(SAVService *)service;
- (SAVServiceGroup *)serviceGroupForSection:(NSInteger)section;

@end

@protocol SCUGlobalNowPlayingModelDelegate <NSObject>

- (void)toggleIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated updateBlock:(dispatch_block_t)update;

- (void)reloadBackgroundForSection:(NSInteger)section;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (void)showSpinner;

@end
