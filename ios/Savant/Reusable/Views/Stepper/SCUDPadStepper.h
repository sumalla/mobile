//
//  SCUDPadStepper.h
//  SavantController
//
//  Created by Alicia Tams on 2/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSInteger, SCUDPadStepperDirection)
{
	SCUDPadStepperDirectionNone,
	SCUDPadStepperDirectionUp,
	SCUDPadStepperDirectionDown,
	SCUDPadStepperDirectionLeft,
	SCUDPadStepperDirectionRight
};

@protocol SCUDPadStepperDelegate;

@interface SCUDPadStepper : UIView

@property (nonatomic, weak) id<SCUDPadStepperDelegate> delegate;

@property (nonatomic, assign) BOOL isOpen;

- (instancetype)initWithSize:(CGSize)size expandedSize:(CGSize)expandedSize padding:(CGFloat)padding;

- (void)open;
- (void)close;

@end

@protocol SCUDPadStepperDelegate <NSObject>

- (void)stepper:(SCUDPadStepper *)stepper didPressDirection:(SCUDPadStepperDirection)direction;

@optional

- (void)willOpenDPadStepper:(SCUDPadStepper *)stepper;
- (void)didOpenDPadStepper:(SCUDPadStepper *)stepper;

- (void)willCloseDPadStepper:(SCUDPadStepper *)stepper;
- (void)didCloseDPadStepper:(SCUDPadStepper *)stepper;

@end
