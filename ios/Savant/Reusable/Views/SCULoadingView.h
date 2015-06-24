//
//  SCUFullscreenLoadingView.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef void(^SCULoadingViewCallback)(NSUInteger buttonIndex);

@interface SCULoadingView : UIView

/**
 *  Called with the index of the tapped button.
 */
@property (nonatomic, copy) SCULoadingViewCallback callback;

/**
 *  Sets the tint color of the top and bottom container views.
 */
@property (nonatomic) UIColor *backgroundTintColor UI_APPEARANCE_SELECTOR;

/**
 *  Sets the tint color the button text, the center image, and the circle views.
 */
@property (nonatomic) UIColor *foregroundTintColor UI_APPEARANCE_SELECTOR;

/**
 *  Sets the tint color of the buttons.
 */
@property (nonatomic) UIColor *buttonColor UI_APPEARANCE_SELECTOR;

/**
 *  Set a custom background view.
 */
@property (nonatomic) UIView *backgroundView UI_APPEARANCE_SELECTOR;

/**
 *  Set the center image.
 */
@property (nonatomic) UIImage *centerImage UI_APPEARANCE_SELECTOR;

/**
 *  Set the loading title.
 */
@property (nonatomic) NSString *title;

/**
 *  Set the button titles.
 */
@property (nonatomic) NSArray *buttonTitles;

/**
 *  Set the progress bar tint color.
 */
@property (nonatomic) UIColor *progressTintColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, readonly) UIProgressView *progressView;

/**
 *  Set the progress view label's text.
 */
@property (nonatomic) NSString *progressViewLabel;

/**
 *  Enable/disable the animations.
 *
 *  @param enabled YES to enable circle animations; otherwise, NO.
 */
- (void)setAnimationEnabled:(BOOL)enabled;

@end
