//
//  SCUClimateHistoryDataFilterCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUClimateHistoryDataFilterCellKeyState;
extern NSString *const SCUClimateHistoryDataFilterCellKeyStyle;

@interface SCUClimateHistoryDataFilterCell : SCUDefaultTableViewCell

@property (readonly) UISwitch *toggleSwitch;

@end
