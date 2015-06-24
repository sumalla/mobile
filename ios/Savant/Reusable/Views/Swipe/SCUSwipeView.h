//
//  SCUSwipeView2.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_OPTIONS(NSUInteger, SCUSwipeViewConfiguration)
{
    SCUSwipeViewConfigurationVertical   = 1 << 0,
    SCUSwipeViewConfigurationHorizontal = 1 << 1,
    SCUSwipeViewConfigurationCenter     = 1 << 2,
    SCUSwipeViewConfigurationAll        = SCUSwipeViewConfigurationVertical | SCUSwipeViewConfigurationHorizontal | SCUSwipeViewConfigurationCenter
};

typedef NS_OPTIONS(NSUInteger, SCUSwipeViewDirection)
{
    SCUSwipeViewDirectionRight = UISwipeGestureRecognizerDirectionRight,
    SCUSwipeViewDirectionLeft = UISwipeGestureRecognizerDirectionLeft,
    SCUSwipeViewDirectionUp = UISwipeGestureRecognizerDirectionUp,
    SCUSwipeViewDirectionDown = UISwipeGestureRecognizerDirectionDown,
    SCUSwipeViewDirectionCenter = 1 << 4,
    SCUSwipeViewDirectionUnknown = 1 << 10
};

@protocol SCUSwipeViewDelegate;

@interface SCUSwipeView : UIView

/**
 *  Set and retrieve the delegate.
 */
@property (nonatomic, weak) id<SCUSwipeViewDelegate> delegate;

/**
 *  Retrieve the configuration.
 */
@property (nonatomic, readonly) SCUSwipeViewConfiguration configuration;

/**
 *  Set the arrow color. The default is white.
 */
@property (nonatomic) UIColor *arrowColor UI_APPEARANCE_SELECTOR;

/**
 *  Set the swipe color. The default is [[SCUColors shared] color01].
 */
@property (nonatomic) UIColor *swipeColor UI_APPEARANCE_SELECTOR;

/**
 *  Defaults to 2.
 */
@property (nonatomic) NSTimeInterval textFadeDelay;

/**
 *  Defaults to "Swipe to control"
 */
@property (nonatomic) NSString *initialText;

/**
 *  Defaults to "Select"
 */
@property (nonatomic) NSString *mainText;

/**
 *  The center label. Set any properties you need.
 */
@property (nonatomic, readonly) UILabel *centerLabel;

/**
 *  Set the bounding size of the arrow view. A square is assumed. The default is 150.
 */
@property (nonatomic) CGFloat arrowViewSize;

/**
 *  Set the size of the arrows. A square is assumed. The default is 15.
 */
@property (nonatomic) CGSize arrowSize;

/**
 *  Set the delay before a hold may begin. The default is .45 seconds.
 */
@property (nonatomic) NSTimeInterval holdDelay;

/**
 *  Set the hold animation interval.
 */
@property (nonatomic) NSTimeInterval holdAnimationInterval;

/**
 *  Set this to YES to allow holding on the swipe view. The default is YES.
 */
@property (nonatomic) BOOL allowsHolding;

/**
 *  Adds a view to the bottom of the swipeview, the arrows are centered above this area.
 */
@property (nonatomic) UIView *footerView;

/**
 *  Relative values for the footers height/width.
 */
@property (nonatomic) CGSize relativeFooterSize;

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCUSwipeViewConfiguration)configuration;

@end

@protocol SCUSwipeViewDelegate <NSObject>

@optional

- (void)swipeView:(SCUSwipeView *)swipeView didReceiveInteraction:(SCUSwipeViewDirection)interaction isHold:(BOOL)isHold;

- (void)swipeView:(SCUSwipeView *)swipeView holdInteractionDidEnd:(SCUSwipeViewDirection)interaction;

@end
