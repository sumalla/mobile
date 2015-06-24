//
//  SCUMarqueeLabel.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMarqueeLabel.h"
#import "SCUGradientView.h"
@import Extensions;

@interface SCUMarqueeLabel ()

@property (nonatomic) UILabel *referenceLabel;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *label1;
@property (nonatomic) UILabel *label2;
@property (nonatomic) NSArray *labels;
@property (nonatomic) CGFloat currentTextWidth;
@property (nonatomic) CAGradientLayer *gradientLayer;
@property (nonatomic, weak) NSTimer *animationStartTimer;

@end

@implementation SCUMarqueeLabel

- (void)dealloc
{
    [self stopAnimations];
}

- (instancetype)init
{
    self = [self initWithFrame:CGRectZero];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame andReferenceLabel:[[UILabel alloc] initWithFrame:CGRectZero]];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame andReferenceLabel:(UILabel *)label
{
    NSParameterAssert(label);
    self = [super initWithFrame:frame];

    if (self)
    {
        self.clipsToBounds = YES;
        self.fadeInset = 15;
        self.scrollDelay = 1;
        self.scrollDuration = 12;
        self.animationCurve = UIViewAnimationOptionCurveEaseIn;
        self.deadSpace = 50;
        self.referenceLabel = label;
        self.backgroundColor = label.backgroundColor;
        self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.containerView];
        self.label1 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label2 = [[UILabel alloc] initWithFrame:CGRectZero];
        self.labels = @[self.label1, self.label2];

        for (UILabel *label in self.labels)
        {
            [self setupAndForwardPropertiesToLabel:label];
            [self.containerView addSubview:label];
        }

        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blueColor].CGColor, (id)[UIColor blueColor].CGColor, (id)[UIColor clearColor].CGColor];
    }

    return self;
}

#pragma mark - Overrides

- (void)setText:(NSString *)text
{
    _text = text;

    for (UILabel *label in self.labels)
    {
        label.attributedText = nil;
        label.text = text;
    }

    self.currentTextWidth = [self widthForCurrentText];

    [self setNeedsLayout];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = attributedText;

    for (UILabel *label in self.labels)
    {
        label.text = @"";
        label.attributedText = attributedText;
    }

    self.currentTextWidth = [self widthForCurrentText];

    [self setNeedsLayout];
}

- (void)setFadeInset:(CGFloat)fadeInset
{
    _fadeInset = fadeInset;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setDeadSpace:(CGFloat)deadSpace
{
    _deadSpace = deadSpace;
    [self setNeedsLayout];
}

- (void)setFont:(UIFont *)font
{
    _font = font;

    for (UILabel *label in self.labels)
    {
        label.font = font;
    }

    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;

    for (UILabel *label in self.labels)
    {
        label.textColor = textColor;
    }
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    _textAlignment = textAlignment;

    for (UILabel *label in self.labels)
    {
        label.textAlignment = textAlignment;
    }

    [self setNeedsLayout];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];

    for (UILabel *label in self.labels)
    {
        label.backgroundColor = backgroundColor;
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 25);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self stopAnimations];

    CGRect frame = self.bounds;
    CGFloat totalWidth = CGRectGetWidth(frame);
    CGFloat textWidth = self.currentTextWidth;

    if (textWidth > totalWidth)
    {
        CGRect frame1 = frame;
        frame1.origin.x = self.fadeInset;
        frame1.size.width = textWidth;
        self.label1.frame = frame1;
        self.label1.hidden = NO;

        CGRect frame2 = frame1;
        frame2.origin.x += self.deadSpace + textWidth;
        self.label2.frame = frame2;
        self.label2.hidden = NO;

        CGRect containerFrame = frame;
        containerFrame.size.width = (self.fadeInset * 2) + self.deadSpace + (textWidth * 2);
        self.containerView.frame = containerFrame;

        self.gradientLayer.frame = frame;
        CGFloat percentage = self.fadeInset / totalWidth;
        self.gradientLayer.startPoint = CGPointMake(0, .5);
        self.gradientLayer.endPoint = CGPointMake(1, .5);
        self.gradientLayer.locations = @[@0, @(percentage), @(1 - percentage), @1];
        self.layer.mask = self.gradientLayer;

        self.animationStartTimer = [NSTimer sav_scheduledBlockWithDelay:0.1 block:^{
            [self startAnimations];
        }];
    }
    else
    {
        self.label1.frame = frame;
        self.label1.hidden = NO;
        self.label2.hidden = YES;
        self.layer.mask = nil;
        self.containerView.frame = frame;
    }
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

#pragma mark -

- (void)setupAndForwardPropertiesToLabel:(UILabel *)label
{
    label.numberOfLines = 1;
    label.font = self.referenceLabel.font;
    label.textColor = [UIColor blackColor];
}

- (CGFloat)widthForCurrentText
{
    CGFloat width = 0;

    if (self.label1.attributedText)
    {
        width = [self.label1.attributedText size].width;
    }
    else
    {
        width = [self.label1.text sizeWithAttributes:@{NSFontAttributeName: self.label1.font}].width;
    }

    return ceil(width);
}

- (void)stopAnimations
{
    [self.animationStartTimer invalidate];
    self.animationStartTimer = nil;
    [self.containerView.layer removeAllAnimations];
}

- (void)startAnimations
{
    CGRect originalFrame = self.containerView.frame;
    originalFrame.origin.x = 0;

    CGRect newFrame = originalFrame;
    newFrame.origin.x -= (self.currentTextWidth + self.deadSpace);

    [UIView animateWithDuration:self.scrollDuration delay:self.scrollDelay options:self.animationCurve | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.containerView.frame = newFrame;
    } completion:^(BOOL finished) {

        self.containerView.frame = originalFrame;

        if (finished)
        {
            [self startAnimations];
        }
    }];
}

@end
