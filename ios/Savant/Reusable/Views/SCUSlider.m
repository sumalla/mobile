//
//  SCUSlider.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSlider.h"
#import "SCUSliderPrivate.h"

@interface SCUSlider () <UIGestureRecognizerDelegate>

@property (nonatomic) SCUSliderStyle style;
@property (nonatomic, getter = isTracking) BOOL tracking;
@property (nonatomic, weak) NSTimer *callbackTimer;
@property (nonatomic) CGFloat lastValue;
@property (nonatomic) UIView *thumbView;
@property (nonatomic) UIView *iTunesThumbView;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic) UIView *indicatorTab;
@property (nonatomic) UILabel *indicatorLabel;

@end

@implementation SCUSlider

- (instancetype)initWithStyle:(SCUSliderStyle)style frame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.style = style;
        self.value = 0;
        self.minimumValue = 0;
        self.maximumValue = 100;
        self.delta = 0;
        self.continuous = YES;

        self.trackView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.trackView];
        [self sav_pinView:self.trackView withOptions:SAVViewPinningOptionsCenterY];
        [self sav_pinView:self.trackView withOptions:SAVViewPinningOptionsHorizontally withSpace:10];

        CGFloat trackHeight = 2;
        
        self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        self.thumbView.layer.cornerRadius = 10;

        switch (self.style)
        {
            case SCUSliderStylePlain:
                trackHeight = 4;
                self.thumbView.borderColor = [[SCUColors shared] color01];
                self.thumbView.borderWidth = [UIScreen screenPixel];
                break;
            case SCUSliderStyleiTunes:
                trackHeight = 8;
                break;
            case SCUSliderStyleVolumePopup:
                trackHeight = 12;
                self.trackView.layer.cornerRadius = 2;
                self.fillView.layer.cornerRadius = 2;
                self.trackColor = [[SCUColors shared] color03shade08];
                self.fillColor = [[SCUColors shared] color01];
                self.thumbColor = [UIColor clearColor];
                break;
        }

        [self sav_setHeight:trackHeight *= [UIScreen screenPixel] forView:self.trackView isRelative:NO];
        
        self.fillView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.fillView];

        if (self.style == SCUSliderStyleiTunes)
        {
            self.thumbView.backgroundColor = [UIColor clearColor];
            self.iTunesThumbView = [[UIView alloc] initWithFrame:CGRectMake(10 - [UIScreen screenPixel] * 2, 0, [UIScreen screenPixel] * 2, 20)];
            [self.thumbView addSubview:self.iTunesThumbView];
        }

        [self addSubview:self.thumbView];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        [self addGestureRecognizer:panGesture];
        self.panGestureRecognizer = panGesture;

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGesture.numberOfTapsRequired = 2;
        [self addGestureRecognizer:tapGesture];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self initWithStyle:SCUSliderStylePlain frame:frame];
    return self;
}

#pragma mark - Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (!self.isTracking)
    {
        [self updateViewWithPercentage:[self percentageFromValue:self.value]];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView = [self findParentScrollView:self.superview];
    });
}

- (void)drawIndicatorArrow
{
    [self updateIndicatorTab];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineCapStyle  = kCGLineCapRound;
    
    CGFloat height = self.indicatorLabel.intrinsicContentSize.height + 10;
    
    [path moveToPoint:CGPointMake(30, height + 8)];
    [path addLineToPoint:CGPointMake(22, height)];
    [path addLineToPoint:CGPointMake(38, height)];
    [path closePath];
    
    CAShapeLayer *triangle = [[CAShapeLayer alloc] init];
    triangle.fillColor = self.indicatorTab.backgroundColor.CGColor;
    [triangle setPath:path.CGPath];
    [[self.indicatorTab layer] addSublayer:triangle];
}

- (UIScrollView *)findParentScrollView:(UIView *)view
{
    if (view)
    {
        if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UICollectionView class]])
        {
            return (UIScrollView *)view;
        }
        else
        {
            return [self findParentScrollView:view.superview];
        }
    }
    else
    {
        return nil;
    }
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 24);
}

- (void)setTrackColor:(UIColor *)trackColor
{
    _trackColor = trackColor;
    self.trackView.backgroundColor = trackColor;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
    self.fillView.backgroundColor = fillColor;
}

- (void)setThumbColor:(UIColor *)thumbColor
{
    _thumbColor = thumbColor;

    if (self.style == SCUSliderStylePlain)
    {
        self.thumbView.backgroundColor = thumbColor;
    }
    else if (self.style == SCUSliderStyleiTunes)
    {
        self.iTunesThumbView.backgroundColor = thumbColor;
    }
}

- (void)setValue:(CGFloat)value
{
    if (value != _value)
    {
        _value = value;

        if (!self.isTracking)
        {
            [self updateViewWithPercentage:[self percentageFromValue:value]];
        }
    }
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:ANIMATION_CONSTANT * .2 animations:^{
            self.value = value;
        }];
    }
    else
    {
        self.value = value;
    }
}

- (UIView *)thumb
{
    return self.thumbView ? self.thumbView : self.iTunesThumbView;
}

#pragma mark - Gesture handling

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint velocity = [gesture velocityInView:self];

            if (ABS(velocity.y) > ABS(velocity.x))
            {
                gesture.enabled = NO;
                gesture.enabled = YES;
                return;
            }
            else if (self.scrollView)
            {
                self.scrollView.panGestureRecognizer.enabled = NO;
                self.scrollView.panGestureRecognizer.enabled = YES;
            }

            self.tracking = YES;

            [self updateValueWithGesture:gesture];

            if (self.isContinuous)
            {
                [self callCallback];
            }

            if (self.callbackTimeInterval > 0)
            {
                SAVWeakSelf;
                self.callbackTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.callbackTimeInterval repeats:YES block:^{
                    [wSelf callCallback];
                }];
            }
            
            if (self.showsIndicator)
            {
                self.indicatorTab.hidden = NO;
                self.indicatorTab.layer.opacity = 0.0;
                [UIView animateWithDuration:0.20 animations:^{
                    self.indicatorTab.layer.opacity = 1.0;
                }];
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self updateValueWithGesture:gesture];

            if (!self.callbackTimer && self.isContinuous)
            {
                [self callCallback];
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self.callbackTimer invalidate];
            [self callCallback];
            self.tracking = NO;
            
            if (self.showsIndicator)
            {
                [UIView animateWithDuration:0.20 animations:^{
                    self.indicatorTab.layer.opacity = 0.0;
                } completion:^(BOOL finished) {
                    self.indicatorTab.hidden = YES;
                }];
            }
            
            break;
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    self.tracking = YES;
    [self updateValueWithGesture:gesture];
    self.tracking = NO;
    [self callCallback];
}

- (void)updateValueWithGesture:(UIGestureRecognizer *)gesture
{
    BOOL isTap = [gesture isKindOfClass:[UITapGestureRecognizer class]];
    CGFloat percentage = [self percentageFromLocation:[self normalizedPointFromPoint:[gesture locationInView:self] isTap:isTap]];
    self.value = [self valueFromPercentage:percentage];
    
    if (self.showsIndicator)
    {
        [self initializeIndicatorLabelIfNecessary];
        self.indicatorLabel.text = [NSString stringWithFormat:@"%.0f%%", percentage * 100];
    }
    
    [self updateViewWithPercentage:percentage];
}

- (void)updateViewWithPercentage:(CGFloat)percentage
{
    [self updateThumbWithPercentage:percentage];
    [self updateFillWithPercentage:percentage];
    
    if (self.showsIndicator)
    {
        [self updateIndicatorTab];
    }
}

- (void)updateIndicatorTab
{
    CGRect thumbFrame = [self convertRect:self.thumbView.frame toView:[UIApplication sharedApplication].keyWindow];
    CGRect frame = CGRectMake(CGRectGetMidX(thumbFrame) - 30.0f, CGRectGetMinY(thumbFrame) - CGRectGetHeight(thumbFrame) - 25.0f, 60.0f, self.indicatorLabel.intrinsicContentSize.height + 10.0f);
    self.indicatorTab.frame = frame;
}

- (void)updateThumbWithPercentage:(CGFloat)percentage
{
    if (CGPointEqualToPoint(self.center, CGPointZero))
    {
        //-------------------------------------------------------------------
        // The view hasn't been initially layed out yet, so ignore this request.
        //-------------------------------------------------------------------
        return;
    }

    CGRect thumbFrame = self.thumbView.frame;
    thumbFrame.origin.x = CGRectGetWidth(self.trackView.frame) * percentage;
    thumbFrame.origin.y = self.trackView.center.y - (CGRectGetHeight(thumbFrame) / 2);
    thumbFrame = CGRectIntegral(thumbFrame);
    thumbFrame.size.width = 20;
    thumbFrame.size.height = 20;
    self.thumbView.frame = thumbFrame;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Callbacks

- (void)callCallback
{
    if (self.callback && ((self.lastValue != self.value) || !self.isContinuous))
    {
        self.lastValue = self.value;
        self.callback(self);
    }
}

#pragma mark - Private methods

- (void)updateFillWithPercentage:(CGFloat)percentage
{
    CGRect frame = self.trackView.frame;
    frame.size.width *= percentage;
    self.fillView.frame = CGRectIntegral(frame);
}

- (CGPoint)normalizedPointFromPoint:(CGPoint)point isTap:(BOOL)isTap
{
    return point;
}

- (void)initializeIndicatorLabelIfNecessary
{
    if (self.showsIndicator && !self.indicatorTab)
    {
        self.indicatorTab = [[UIView alloc] initWithFrame:CGRectZero];
        self.indicatorTab.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.9];
        self.indicatorTab.layer.cornerRadius = 4.0f;

        self.indicatorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.indicatorLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
        self.indicatorLabel.textColor = [[SCUColors shared] color04];
        self.indicatorLabel.textAlignment = NSTextAlignmentCenter;
        self.indicatorLabel.text = @"100%";

        [self.indicatorTab addSubview:self.indicatorLabel];
        [self.indicatorTab sav_addFlushConstraintsForView:self.indicatorLabel withPadding:5.0f];

        self.indicatorTab.hidden = YES;

        [[UIApplication sharedApplication].keyWindow addSubview:self.indicatorTab];
        [self drawIndicatorArrow];
    }
}

#pragma mark -

- (CGFloat)percentageFromLocation:(CGPoint)location
{
    CGFloat value = location.x / CGRectGetWidth(self.bounds);

    if (value < 0)
    {
        value = 0;
    }
    else if (value > 1)
    {
        value = 1;
    }

    return value;
}

- (CGFloat)valueFromPercentage:(CGFloat)percentage
{
    CGFloat minimumValue = ABS(self.minimumValue);
    CGFloat maximumValue = ABS(self.maximumValue) + minimumValue;

    CGFloat value = (percentage * maximumValue) - minimumValue;

    CGFloat diff = self.delta ? fmod(value, self.delta) : 0;

    return value - diff;
}

- (CGFloat)percentageFromValue:(CGFloat)value
{
    CGFloat minimumValue = ABS(self.minimumValue);
    CGFloat maximumValue = ABS(self.maximumValue) + minimumValue;
    return (value + minimumValue) / maximumValue;
}

@end
