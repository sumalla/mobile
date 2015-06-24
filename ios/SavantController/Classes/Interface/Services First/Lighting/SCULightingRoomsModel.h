//
//  SCULightingRoomsModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
@class SAVService;

@protocol SCULightingRoomsModel <NSObject>

- (void)showLightingControlsForRoom:(NSString *)room indexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)reloadData;

@end

@interface SCULightingRoomsModel : SCUDataSourceModel

- (instancetype)initWithService:(SAVService *)service;

@property (nonatomic, weak) id<SCULightingRoomsModel> delegate;

- (NSString *)firstRoom;

- (NSIndexPath *)indexPathForRoom:(NSString *)room;

@end
