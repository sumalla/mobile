//
//  SCUClimateHistoryModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUGraph.h"
#import "SCUHVACPickerModel.h"

@protocol SCUClimateHistoryDelegate;
@class SAVService, SAVServiceGroup;

@interface SCUClimateHistoryModel : SCUDataSourceModel <SCUGraphDataSource, SCUHVACPickerModelDelegate>

- (instancetype)initWithService:(SAVService *)service;

- (void)fetchStageDataFromStartTime:(NSTimeInterval)startTime toEndTime:(NSTimeInterval)endTime;
- (void)fetchAllDataForTime:(NSTimeInterval)time;

@property (nonatomic) NSInteger currentZoneIndex;

@property (weak) id <SCUClimateHistoryDelegate> delegate;
@property SAVService *service;
@property SAVServiceGroup *serviceGroup;

@property NSString *zoneName;
@property (nonatomic, readonly) BOOL isCelsius;
@property (nonatomic, strong) SCUHVACPickerModel *hvacPickerModel;

@end

@protocol SCUClimateHistoryDelegate <NSObject>

- (void)reloadData;
- (BOOL)isServicesFirst;
- (void)fetchCurrentData;

@end

