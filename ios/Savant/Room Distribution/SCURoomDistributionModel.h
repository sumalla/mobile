//
//  SCURoomDistributionModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUExpandableDataSourceModel.h"

typedef NS_ENUM(NSInteger, SCURoomDistributionCellTypes)
{
    SCURoomDistributionCellTypeVariant,
    SCURoomDistributionCellTypeToggle,
    SCURoomDistributionCellTypeVolume,
    SCURoomDistributionCellTypeAudioOnly
};

@protocol SCURoomDistributionModelDelegate;
@class SAVServiceGroup, SAVService;

@interface SCURoomDistributionModel : SCUExpandableDataSourceModel

@property (weak, nonatomic) id <SCURoomDistributionModelDelegate> delegate;
@property (readonly) SAVServiceGroup *serviceGroup;
@property (readonly) NSIndexPath *audioOnlyIndexPath;

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service;

- (void)powerOnRoom:(NSString *)room;
- (void)powerOffRoom:(NSString *)room;
- (NSString *)roomForIndexPath:(NSIndexPath *)indexPath;

- (NSString *)selectedServiceForIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)servicesForIndexPath:(NSIndexPath *)indexPath;
- (void)selectService:(SAVService *)service forIndexPath:(NSIndexPath *)indexPath;

- (BOOL)indexPathAllowsAudioOnly:(NSIndexPath *)indexPath;
- (void)selectRoomAtIndexPath:(NSIndexPath *)indexPath;
- (void)enableAudioOnlyForIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCURoomDistributionModelDelegate <NSObject>

- (void)reloadData;
- (void)showSpinner;
- (void)updateNumberOfChildrenBelowIndexPath:(NSIndexPath *)indexPath updateBlock:(dispatch_block_t)update;
- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)updateActiveState:(BOOL)isActive;
- (void)expandIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)collapseIndex:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end