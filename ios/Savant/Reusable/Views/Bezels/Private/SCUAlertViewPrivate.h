//
//  SCUAlertView+ForSubclassEyesOnly.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAlertView.h"

@interface SCUAlertView ()

+ (UIColor *)defaultBackgroundColor;

+ (UIColor *)defaultButtonSeparatorColor;

+ (CGFloat)cornerRadius;

- (void)setButtonViewHidden:(BOOL)hidden;

- (void)positionInView:(UIView *)containingView;

@property (nonatomic, readonly) CGFloat buttonWidth;

@property (nonatomic, readonly) CGFloat contentPadding;

@property (nonatomic) UIView *maskingView;

- (void)hideWithCompletion:(dispatch_block_t)block;

@end
