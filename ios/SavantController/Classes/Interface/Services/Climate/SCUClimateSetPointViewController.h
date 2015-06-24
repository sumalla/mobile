//
//  SCUClimateSetPointViewController.h
//  SavantController
//
//  Created by David Fairweather on 6/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SCUClimateServiceModel.h"
#import "SCUPickerView.h"

@protocol SCUSetPointPickerDelegate;

@interface SCUClimateSetPointViewController : UIViewController

- (instancetype)initWithColorSchem:(UIColor *)color setPointType:(NSInteger)setPointType;

@property (nonatomic, weak) id<SCUSetPointPickerDelegate>delegate;

@property (nonatomic) NSString *headerString;
@property (nonatomic) NSAttributedString *currentValueAttributedString;

@end

@protocol SCUSetPointPickerDelegate <NSObject>

- (void)climateAdjustmentWithDirection:(SCUPickerViewDirection)direction forClimateSetPointType:(SCUClimateModeType)climateModeType;

- (void)climateAdjustmentDismissed;

@end