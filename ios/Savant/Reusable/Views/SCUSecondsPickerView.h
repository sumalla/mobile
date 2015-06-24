//
//  SCUSecondsPickerView.h
//  SavantController
//
//  Created by Nathan Trapp on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumericPickerView.h"

@interface SCUSecondsPickerView : SCUNumericPickerView

+ (NSString *)stringForValue:(NSTimeInterval)value;

@end
