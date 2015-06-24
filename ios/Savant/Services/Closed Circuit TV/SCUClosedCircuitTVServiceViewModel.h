//
//  SCUClosedCircuitTVServiceViewModel.h
//  SavantController
//
//  Created by Stephen Silber on 2/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUServiceViewModel.h"

@interface SCUClosedCircuitTVServiceViewModel : SCUServiceViewModel <UIPickerViewDelegate, UIPickerViewDataSource>

- (NSString *)titleForRow:(NSInteger)row;

@end
