//
//  SCUClimateHistoryDataFilterModel.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

@protocol SCUClimateHistoryDataFilterDelegate;

@interface SCUClimateHistoryDataFilterModel : SCUDataSourceModel

@property (weak) id <SCUClimateHistoryDataFilterDelegate> delegate;

- (void)listenToSwitch:(UISwitch *)toggleSwith forIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SCUClimateHistoryDataFilterDelegate <NSObject>

- (void)toggleChart:(NSInteger)type;
- (BOOL)chartIsVisible:(NSInteger)type;

@end