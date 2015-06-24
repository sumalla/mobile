//
//  SCUClimateZonesModel.h
//  SavantController
//
//  Created by Stephen Silber on 9/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@protocol SCUClimateZonesModel <NSObject>

- (void)showClimateControlsForZone:(NSString *)zone indexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)reloadIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUClimateZonesTableDelegate <NSObject>

- (void)reconfigureIndexPath:(NSIndexPath *)indexPath;
- (void)setImages:(NSArray *)images forIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUClimateZonesModel : SCUDataSourceModel

@property (nonatomic, weak) id<SCUClimateZonesModel> delegate;

@property (nonatomic, weak) id<SCUClimateZonesTableDelegate> tableDelegate;

- (NSString *)firstZone;

- (NSIndexPath *)indexPathForZone:(NSString *)zone;

@end
