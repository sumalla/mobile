//
//  SCUSecurityChartModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityModel.h"

typedef NS_ENUM(NSInteger, SCUSecurityEntityStatusFilter)
{
    SCUSecurityEntityStatusFilter_Unknown  = -1,
    SCUSecurityEntityStatusFilter_Ready    = 0,
    SCUSecurityEntityStatusFilter_Trouble  = 1,
    SCUSecurityEntityStatusFilter_Critical = 2,
    SCUSecurityEntityStatusFilter_All      = 3
};

@class SAVSecurityEntity;
@protocol SCUSecurityChartModelDelegate;

@interface SCUSecurityChartModel : SCUSecurityModel <SCUDataSourceModel>

@property (weak) id <SCUSecurityChartModelDelegate, SCUSecurityModelDelegate> delegate;

- (void)filterByStatus:(SCUSecurityEntityStatusFilter)status;
- (void)filterByRoomId:(NSString *)roomId;
- (void)bypassPressedForRow:(NSInteger)row bypass:(BOOL)bypass;

@end

@protocol SCUSecurityChartModelDelegate <SCUSecurityModelDelegate>

- (void)reloadTable;

@end