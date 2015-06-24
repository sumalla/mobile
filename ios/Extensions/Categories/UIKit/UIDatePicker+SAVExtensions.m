//
//  UIDatePicker+SAVExtensions.m
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIDatePicker+SAVExtensions.h"
@import ObjectiveC.runtime;

@implementation UIDatePicker (SAVExtensions)

- (void)setSav_handler:(SAVDatePickerHandler)handler
{
    [self removeTarget:self action:@selector(sav_valueChanged) forControlEvents:UIControlEventValueChanged];

    if (handler)
    {
        [self addTarget:self action:@selector(sav_valueChanged) forControlEvents:UIControlEventValueChanged];
    }

    objc_setAssociatedObject(self, @selector(sav_handler), handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (SAVDatePickerHandler)sav_handler
{
    return objc_getAssociatedObject(self, @selector(sav_handler));
}

- (void)sav_valueChanged
{
    self.sav_handler(self.date);
}

@end
