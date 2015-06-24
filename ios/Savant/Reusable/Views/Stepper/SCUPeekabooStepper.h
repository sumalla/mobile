//
//  SCUPeekabooStepper.h
//  SavantController
//
//  Created by Alicia Tams on 2/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;
@class SCUButton;

@protocol SCUPeekabooStepperDelegate;

@interface SCUPeekabooStepper : UIView

@property (nonatomic) BOOL isAnimating;

@property (nonatomic, weak) id<SCUPeekabooStepperDelegate> delegate;
@property (nonatomic) UILabel *textLabel;
@property (nonatomic, assign) BOOL textLabelClosesStepper;
@property (nonatomic, assign) BOOL isOpen;

- (instancetype)initWithSize:(CGSize)size text:(NSString *)text image:(UIImage *)image;
- (instancetype)initWithSize:(CGSize)size text:(NSString *)text image:(UIImage *)image decrementImage:(UIImage *)decrementImage incrementImage:(UIImage *)incrementImage;

- (void)open;
- (void)close;

@end

@protocol SCUPeekabooStepperDelegate <NSObject>

- (void)incrementTappedForStepper:(SCUPeekabooStepper *)stepper;
- (void)decrementTappedForStepper:(SCUPeekabooStepper *)stepper;

@optional
- (void)willOpenStepper:(SCUPeekabooStepper *)stepper;
- (void)willCloseStepper:(SCUPeekabooStepper *)stepper;
- (void)didOpenStepper:(SCUPeekabooStepper *)stepper;
- (void)didCloseStepper:(SCUPeekabooStepper *)stepper;

@end
