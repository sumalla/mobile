//
//  SCUAnimatedLabel.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAnimatedLabel.h"
#import "SCUGradientView.h"
@import Extensions;

@interface SCUAnimatedLabel ()

@property (nonatomic) UILabel *label;
@property (nonatomic) BOOL animating;
@property (nonatomic) CAGradientLayer *gradientLayer;

@end

@implementation SCUAnimatedLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.clipsToBounds = YES;
        self.transitionType = SCUAnimatedLabelTransitionTypeNone;
        self.transitionDuration = .5;
        self.fadeInset = 15;
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.backgroundColor = self.label.backgroundColor;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.textColor = self.label.textColor;
        self.font = self.label.font;
        [self addSubview:self.label];

        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blueColor].CGColor, (id)[UIColor blueColor].CGColor, (id)[UIColor clearColor].CGColor];
    }

    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeMake(UIViewNoIntrinsicMetric, 20);

    if (self.label.text)
    {
        size = [self.label.text sizeWithAttributes:@{NSFontAttributeName: self.label.font}];
        size.width += self.fadeInset * 2;
    }

    return size;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (!backgroundColor)
    {
        backgroundColor = [UIColor clearColor];
    }
    
    [super setBackgroundColor:backgroundColor];

    self.label.backgroundColor = backgroundColor;

    [self setNeedsDisplay];
}

- (void)setFadeInset:(CGFloat)fadeInset
{
    _fadeInset = fadeInset;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.label.textColor = textColor;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    self.label.font = font;
}

- (void)setText:(NSString *)text
{
    NSString *oldText = _text;
    _text = text;

    if (!text)
    {
        [self stopAnimations];
        self.label.text = text;
        self.label.alpha = 1;
    }
    else if (oldText)
    {
        [self animateWithNewText:text oldText:oldText];
    }
    else
    {
        self.label.text = text;
    }
}

- (void)resetText
{
    self.text = nil;
    [self stopAnimations];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self stopAnimations];

    CGFloat totalWidth = CGRectGetWidth(self.bounds);

    CGRect frame = self.bounds;

    self.label.frame = frame;

    if (!self.animating)
    {
        self.gradientLayer.frame = frame;
        CGFloat percentage = self.fadeInset / totalWidth;
        self.gradientLayer.startPoint = CGPointMake(0, .5);
        self.gradientLayer.endPoint = CGPointMake(1, .5);
        self.gradientLayer.locations = @[@0, @(percentage), @(1 - percentage), @1];
        self.layer.mask = self.gradientLayer;
    }
    else
    {
        self.layer.mask = nil;

    }

}

- (void)animateWithNewText:(NSString *)newText oldText:(NSString *)oldText
{
    if (self.transitionType == SCUAnimatedLabelTransitionTypeNone)
    {
        self.label.text = newText;
    }
    else if (self.transitionType == SCUAnimatedLabelTransitionTypeFadeIn)
    {
        if ([oldText isEqualToString:newText])
        {
            return;
        }
        
        self.label.alpha = 0;
        self.label.text = newText;

        [UIView animateWithDuration:self.transitionDuration delay:0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.label.alpha = 1;
        } completion:^(BOOL finished) {
            self.label.alpha = 1;
        }];
    }
    else if (self.transitionType == SCUAnimatedLabelTransitionTypeFadeOutFadeIn)
    {
        if ([oldText isEqualToString:newText])
        {
            return;
        }
        NSTimeInterval duration = self.transitionDuration / 2;

        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.label.alpha = 0;
        } completion:^(BOOL finished) {

            self.label.text = newText;

            if (finished)
            {
                [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    self.label.alpha = 1;
                } completion:^(BOOL finished) {
                    self.label.alpha = 1;
                }];
            }
            else
            {
                self.label.alpha = 1;
            }
        }];
    }
    else if (self.transitionType == SCUAnimatedLabelTransitionTypeMarquee || self.transitionType == SCUAnimatedLabelTransitionTypeMarqueeLeft)
    {
        self.layer.mask = self.gradientLayer;
        CGRect currentFrame = self.label.frame;
        CGRect animatedFrame = currentFrame;
        animatedFrame.origin.x = -(CGRectGetWidth(currentFrame));

        NSTimeInterval duration = self.transitionDuration / 2;

        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.label.frame = animatedFrame;
        } completion:^(BOOL finished) {
            if (finished)
            {
                self.label.text = newText;

                CGRect rightFrame = currentFrame;
                rightFrame.origin.x = CGRectGetWidth(currentFrame);
                self.label.frame = rightFrame;

                [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.label.frame = currentFrame;
                } completion:^(BOOL finished) {
                    self.layer.mask = nil;
                }];
            }
        }];
    }
    else if (self.transitionType == SCUAnimatedLabelTransitionTypeMarqueeRight)
    {
        self.layer.mask = self.gradientLayer;
        CGRect currentFrame = self.label.frame;
        
        CGRect animatedFrame = currentFrame;
        animatedFrame.origin.x = CGRectGetWidth(currentFrame);
        
        NSTimeInterval duration = self.transitionDuration / 2;
        
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.label.frame = animatedFrame;
        } completion:^(BOOL finished) {
            if (finished)
            {
                self.label.text = newText;
                
                CGRect leftFrame = currentFrame;
                leftFrame.origin.x = -(CGRectGetWidth(currentFrame));
                self.label.frame = leftFrame;
                
                [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.label.frame = currentFrame;
                } completion:^(BOOL finished) {
                    self.layer.mask = nil;
                }];
            }
        }];
    }
}

- (void)stopAnimations
{
    [self.label.layer removeAllAnimations];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];

    if (!newWindow)
    {
        [self stopAnimations];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window)
    {
        [self setNeedsLayout];
    }
}

@end
