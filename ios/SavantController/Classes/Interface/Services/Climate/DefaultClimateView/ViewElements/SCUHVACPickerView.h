//
//  SCUHVACPickerView.h
//  SavantController
//
//  Created by Jason Wolkovitz on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import "SCUButton.h"
#import "SCUPopoverController.h"
#import "SCUHVACPickerModel.h"

@interface SCUHVACPickerView : NSObject <SCUHVACPickerModelViewDelegate>

@property (nonatomic, weak) SCUHVACPickerModel *model;

- (instancetype)initWithHVACPickerModel:(SCUHVACPickerModel *)model;

- (UIView *)labelOrHVACSelector;

- (BOOL)hasHVACHistory;

- (BOOL)hasHVACService;

@end
