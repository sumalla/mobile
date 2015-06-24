//
//  SCUClosedCircuitTVServiceViewModel.m
//  SavantController
//
//  Created by Stephen Silber on 2/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUClosedCircuitTVServiceViewModel.h"

@implementation SCUClosedCircuitTVServiceViewModel

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 2;
}

- (NSString *)titleForRow:(NSInteger)row
{
    return row ? [NSLocalizedString(@"Iris", nil) uppercaseString] : [NSLocalizedString(@"Zoom", nil) uppercaseString];
}

@end
