//
//  SCUClimateHistoryDayViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUModelViewController.h"
#import "SCUClimateHistoryDataFilterModel.h"

@class SCUClimateHistoryModel;

typedef NS_ENUM(NSInteger, SCUClimateHistoryDayPlotType)
{
    SCUClimateHistoryDayPlotType_IndoorTemp,
    SCUClimateHistoryDayPlotType_Humidity,
    SCUClimateHistoryDayPlotType_HeatPoint,
    SCUClimateHistoryDayPlotType_CoolPoint,
    SCUClimateHistoryDayPlotType_Heating,
    SCUClimateHistoryDayPlotType_Cooling,
    SCUClimateHistoryDayPlotType_FanOn
};

@interface SCUClimateHistoryDayViewController : SCUModelViewController <SCUClimateHistoryDataFilterDelegate>

- (instancetype)initWithDataSource:(SCUClimateHistoryModel *)dataSource;

- (void)reloadData;

@end
