//
//  SCUMarqueeLabel.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUMarqueeLabel : UIView

/**
 *  Set the text to display. This will nil the @p attributedText property.
 */
@property (nonatomic) NSString *text;

/**
 *  Set the attributed text to display. This will nil the @p text property.
 */
@property (nonatomic) NSAttributedString *attributedText;

/**
 *  Set the fade inset width for the left and right sides of the label. The default is 50 points.
 */
@property (nonatomic) CGFloat fadeInset;

/**
 *  Set the scroll duration. The default is 12 seconds.
 */
@property (nonatomic) NSTimeInterval scrollDuration;

/**
 *  Set the time before the label begins to scroll. The default is 1 second.
 */
@property (nonatomic) NSTimeInterval scrollDelay;

/**
 *  Set the curve of the animation. The default is UIViewAnimationOptionCurveEaseIn.
 */
@property (nonatomic) UIViewAnimationOptions animationCurve;

/**
 *  Set the space between the marquee. The default is 10 points.
 */
@property (nonatomic) CGFloat deadSpace;

/**
 *  Set the marquee's font. The default is a standard UILabel's font.
 */
@property (nonatomic) UIFont *font;

/**
 *  Set the marquee's text color. The default is black.
 */
@property (nonatomic) UIColor *textColor;

/**
 *  Set the marquee's text alignment.
 */
@property (nonatomic) NSTextAlignment textAlignment;

@end
