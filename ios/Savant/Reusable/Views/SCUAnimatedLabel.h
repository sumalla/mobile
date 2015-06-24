//
//  SCUAnimatedLabel.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, SCUAnimatedLabelTransitionType)
{
    SCUAnimatedLabelTransitionTypeNone, /* Swap the text immediately like a normal label. */
    SCUAnimatedLabelTransitionTypeFadeIn, /* Fade in the new text. */
    SCUAnimatedLabelTransitionTypeFadeOutFadeIn, /* Fade out the old text and then fade in the new text. */
    SCUAnimatedLabelTransitionTypeMarquee, /* Send the old text to the left and bring the new text in from the right. */
    SCUAnimatedLabelTransitionTypeMarqueeLeft, /* Send the old text to the left and bring the new text in from the right. */
    SCUAnimatedLabelTransitionTypeMarqueeRight /* Send the old text to the right and bring the new text in from the left. */
};

@interface SCUAnimatedLabel : UIView

/**
 *  Set the text color.
 */
@property (nonatomic) UIColor *textColor;

/**
 *  Set the font.
 */
@property (nonatomic) UIFont *font;

/**
 *  Set the fade inset for SCUAnimatedLabelTransitionTypeMarquee. The default is 15.
 */
@property (nonatomic) CGFloat fadeInset;

/**
 *  Set the transition type. The default is SCUAnimatedLabelTransitionTypeNone.
 */
@property (nonatomic) SCUAnimatedLabelTransitionType transitionType;

/**
 *  Set the total transition duration. This is ignored for SCUAnimatedLabelTransitionTypeNone.
 */
@property (nonatomic) NSTimeInterval transitionDuration;

/**
 *  Set the text on the label.
 */
@property (nonatomic) NSString *text;

/**
 *  Reset the label. Stops animations and clears text.
 */
- (void)resetText;

@end
