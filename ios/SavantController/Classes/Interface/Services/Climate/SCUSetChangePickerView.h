//
//  SCUSetChangePickerView.h
//  SavantController
//
//  Created by David Fairweather on 5/23/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUSetChangePickerView : UIView

- (void)showPickerVisibility:(BOOL)visible;

@property (nonatomic) CGFloat componentHeight;
@property (nonatomic) UIPickerView *pickerView;

@end
