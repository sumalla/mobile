//
//  SCUBezelView.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;

typedef void (^SCUAlertViewCallback)(NSUInteger buttonIndex);

typedef NS_ENUM(NSUInteger, SCUAlertAnimation)
{
    SCUAlertAnimationDefault,
    SCUAlertAnimationSlideInTop,
    SCUAlertAnimationSlideInLeft,
    SCUAlertAnimationSlideInRight,
    SCUAlertAnimationSlideInBottom,
    SCUAlertAnimationSlideOutTop,
    SCUAlertAnimationSlideOutBottom,
    SCUAlertAnimationSlideOutLeft,
    SCUAlertAnimationSlideOutRight
};

typedef NS_ENUM(NSUInteger, SCUAlertAnimationDirection)
{
    SCUAlertAnimationDirectionTop,
    SCUAlertAnimationDirectionBottom,
    SCUAlertAnimationDirectionLeft,
    SCUAlertAnimationDirectionRight
};

@interface SCUAlertView : UIView

@property (nonatomic, copy) SCUAlertViewCallback callback;

@property (nonatomic) NSIndexSet *primaryButtons;

@property (nonatomic) BOOL tapToDismiss;

@property (nonatomic) SCUAlertAnimation presentationStyle;

@property (nonatomic) BOOL blurBackground;

- (instancetype)initWithTitle:(NSString *)title contentView:(UIView *)contentView buttonTitles:(NSArray *)buttonTitles;

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttonTitles:(NSArray *)buttonTitles;

- (instancetype)initWithError:(NSError *)error;

- (instancetype)initInvalidPasswordAlert;

- (instancetype)initErrorAlertWithMessage:(NSAttributedString *)message bullets:(NSArray *)bullets buttontTitles:(NSArray *)buttonTitles;

- (void)show;

- (void)hide;

@end
