//
//  SCUTextEntryAlert.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAlertView.h"

typedef NS_OPTIONS(NSUInteger, SCUTextEntryAlertFieldType)
{
    SCUTextEntryAlertFieldTypeDefault = 1 << 0,
    SCUTextEntryAlertFieldTypeSecure  = 1 << 1,
    SCUTextEntryAlertFieldTypeBoth    = SCUTextEntryAlertFieldTypeDefault | SCUTextEntryAlertFieldTypeSecure
};

@interface SCUTextEntryAlert : SCUAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message textEntryType:(SCUTextEntryAlertFieldType)textEntryType buttonTitles:(NSArray *)buttonTitles;

- (NSString *)textForFieldWithType:(SCUTextEntryAlertFieldType)fieldType;

@property (nonatomic, readonly, copy) NSString *text;

@end
