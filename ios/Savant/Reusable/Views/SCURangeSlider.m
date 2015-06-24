//
//  SCURangeSlider.m
//  SavantController
//
//  Created by Stephen Silber on 1/14/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCURangeSlider.h"
#import "SCUGradientView.h"

@import Extensions;

@interface SCURangeSlider ()

@property (nonatomic) UIView *track;
@property (nonatomic) UIView *visualTrack;
@property (nonatomic) UIView *leftMask;
@property (nonatomic) UIView *rightMask;
@property (nonatomic) UIView *leftThumb;
@property (nonatomic) UIView *rightThumb;
@property (nonatomic) UIView *leftThumbHandle;
@property (nonatomic) UIView *rightThumbHandle;

@property (nonatomic) UILabel *leftValueLabel;
@property (nonatomic) UILabel *rightValueLabel;

@property (nonatomic) SCUGradientView *fill;

@property (nonatomic) UIColor *leftColor;
@property (nonatomic) UIColor *rightColor;

@property (nonatomic) NSString *modifierCharacter;
@property (nonatomic) CGFloat leftValue;
@property (nonatomic) CGFloat rightValue;
@property (nonatomic) CGFloat minimumValue;
@property (nonatomic) CGFloat maximumValue;
@property (nonatomic) CGFloat delta;
@property (nonatomic) CGFloat buffer;

@property (nonatomic) SCURangeSliderStyle style;

@property (nonatomic, getter = isLeftTracking) BOOL leftTracking;
@property (nonatomic, getter = isRightTracking) BOOL rightTracking;

@property (nonatomic, weak) UIScrollView *scrollView;

@end

static CGFloat const animationModifier = 1.0f;
static CGFloat const thumbSize = 20.0f;

@implementation SCURangeSlider

- (instancetype)initWithStyle:(SCURangeSliderStyle)style withOffsetPercentage:(CGFloat)offset andFrame:(CGRect)frame
{
    self = [self initWithStyle:style frame:frame];
    
    if (self)
    {
        self.rightValue     = [self valueFromPercentage:(1 - offset)];
        self.leftValue      = [self valueFromPercentage:offset];
    }
    
    return self;
}

- (instancetype)initWithStyle:(SCURangeSliderStyle)style frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.minimumValue   = 0;
        self.maximumValue   = 120;
        self.delta          = 1.0f;
        self.buffer         = 5.0f;
        
        self.style = style;
        
        self.thumbColor = [[SCUColors shared] color04];
        self.trackColor = [[SCUColors shared] color03shade08];
        
        switch (style)
        {
            case SCURangeSliderStyleNone:
                self.leftColor  = [[SCUColors shared] color01];
                self.rightColor = [[SCUColors shared] color01];
                break;
            case SCURangeSliderStyleClimate:
                self.leftColor  = [UIColor sav_colorWithRGBValue:0x83e6ff];
                self.rightColor = [[SCUColors shared] color01];
                self.modifierCharacter = @"\u00B0";
                break;
            case SCURangeSliderStyleHumidity:
                self.leftColor  = [UIColor sav_colorWithRGBValue:0xebe182];
                self.rightColor = [UIColor sav_colorWithRGBValue:0x4ef259];
                self.maximumValue = 100;
                self.modifierCharacter = @"%";
        }

        [self setupViews];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        
        self.rightValue     = self.maximumValue;
        self.leftValue      = self.minimumValue;
        
        [self addGestureRecognizer:pan];
    }
    
    return self;
}

- (void)setupViews
{
    CGFloat trackHeight = 4 * [UIScreen screenPixel];

    self.track       = [[UIView alloc] initWithFrame:CGRectZero];
    self.visualTrack = [[UIView alloc] initWithFrame:CGRectZero];
    self.leftMask    = [[UIView alloc] initWithFrame:CGRectZero];
    self.rightMask   = [[UIView alloc] initWithFrame:CGRectZero];
    self.fill        = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[self.leftColor, self.rightColor]];
    
    self.leftThumb  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.rightThumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    
    UIView *leftCircle  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thumbSize, thumbSize)];
    UIView *rightCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thumbSize, thumbSize)];
    
    UILabel *leftValue  = [[UILabel alloc] initWithFrame:CGRectZero];
    leftValue.textColor = [[SCUColors shared] color04];
    leftValue.textAlignment = NSTextAlignmentCenter;
    leftValue.font      = [UIFont fontWithName:@"Gotham-Medium" size:[[SCUDimens dimens] regular].h11];
    
    UILabel *rightValue  = [[UILabel alloc] initWithFrame:CGRectZero];
    rightValue.textColor = [[SCUColors shared] color04];
    rightValue.textAlignment = NSTextAlignmentCenter;
    rightValue.font      = [UIFont fontWithName:@"Gotham-Medium" size:[[SCUDimens dimens] regular].h11];

    self.fill.startPoint    = CGPointMake(0, 0.5);
    self.fill.endPoint      = CGPointMake(1, 0.5);
    
    [self addSubview:self.visualTrack];
    [self addSubview:self.track];
    
    [self sav_pinView:self.track withOptions:SAVViewPinningOptionsHorizontally withSpace:(thumbSize / 2)];
    [self sav_pinView:self.track withOptions:SAVViewPinningOptionsCenterY];
    
    [self sav_pinView:self.visualTrack withOptions:SAVViewPinningOptionsHorizontally];
    [self sav_pinView:self.visualTrack withOptions:SAVViewPinningOptionsCenterY];
    
    [self.visualTrack addSubview:self.fill];
    [self.visualTrack addSubview:self.leftMask];
    [self.visualTrack addSubview:self.rightMask];

    [self.visualTrack sav_addFlushConstraintsForView:self.fill];

    [self sav_setHeight:trackHeight forView:self.track isRelative:NO];
    [self sav_setHeight:trackHeight forView:self.visualTrack isRelative:NO];
    
    [self setTrackBackgroundColor:self.trackColor];
    
    [self.leftThumb addSubview:leftCircle];
    [self.rightThumb addSubview:rightCircle];
    
    [self.leftThumb addSubview:leftValue];
    [self.rightThumb addSubview:rightValue];
    
    [self addSubview:self.leftThumb];
    [self addSubview:self.rightThumb];
    
    [self.leftThumb sav_addCenteredConstraintsForView:leftCircle];
    [self.rightThumb sav_addCenteredConstraintsForView:rightCircle];
    
    [self.leftThumb sav_pinView:leftValue withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsCenterX];
    [self.rightThumb sav_pinView:rightValue withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsCenterX];
    
    [self.leftThumb sav_setSize:CGSizeMake(thumbSize, thumbSize) forView:leftCircle isRelative:NO];
    [self.rightThumb sav_setSize:CGSizeMake(thumbSize, thumbSize) forView:rightCircle isRelative:NO];
    
    leftCircle.layer.cornerRadius   = thumbSize / 2;
    rightCircle.layer.cornerRadius  = thumbSize / 2;
    
    leftCircle.backgroundColor  = self.thumbColor;
    rightCircle.backgroundColor = self.thumbColor;
    
    self.leftValueLabel  = leftValue;
    self.rightValueLabel = rightValue;
    
    self.leftThumbHandle  = leftCircle;
    self.rightThumbHandle = rightCircle;
    
    self.track.backgroundColor = [UIColor clearColor];
}

#pragma mark - Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.isRightTracking && !self.isLeftTracking)
    {
        [self updateRightViewWithPercentage:[self percentageFromValue:self.rightValue]];
        [self updateLeftViewWithPercentage:[self percentageFromValue:self.leftValue]];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView = [self findParentScrollView:self.superview];
    });
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 60);
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

- (void)setTrackBackgroundColor:(UIColor *)color
{
    self.visualTrack.backgroundColor = color;
    self.leftMask.backgroundColor    = color;
    self.rightMask.backgroundColor   = color;
}

- (void)setGradientColors:(NSArray *)colors
{
    NSAssert(colors.count == 2, @"Colors array must contain two colors");
    self.fill.colors = colors;
}

- (void)setThumbColor:(UIColor *)thumbColor
{
    _thumbColor = thumbColor;

    self.rightThumb.backgroundColor = thumbColor;
    self.leftThumb.backgroundColor  = thumbColor;
}

- (void)setTrackColor:(UIColor *)trackColor
{
    _trackColor = trackColor;
    
    // Also sets the background color of the left and right mask
    [self setTrackBackgroundColor:trackColor];
}

- (CGFloat)percentageFromLocation:(CGPoint)location
{
    CGFloat value = location.x / CGRectGetWidth(self.track.frame);
    
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

- (CGFloat)percentageFromValue:(CGFloat)value
{
    return ABS((value - self.minimumValue) / (self.maximumValue - self.minimumValue));
}

- (CGFloat)valueFromPercentage:(CGFloat)percentage
{
    return ((self.maximumValue - self.minimumValue) * percentage) + self.minimumValue;
}

#pragma mark - View Handling

- (void)updateLeftViewWithPercentage:(CGFloat)percentage
{
    [self updateLeftViewWithPercentage:percentage forced:NO];
}

- (void)updateLeftViewWithPercentage:(CGFloat)percentage forced:(BOOL)forced
{
    CGRect leftHandle  = [self.leftThumb convertRect:self.leftThumbHandle.frame toView:self.track];
    CGRect rightHandle = [self.rightThumb convertRect:self.rightThumbHandle.frame toView:self.track];
    
    if ((CGRectGetMaxX(leftHandle) < CGRectGetMinX(rightHandle) && (self.leftValue < self.rightValue - self.buffer)) || forced)
    {
        CGRect thumbFrame = self.leftThumb.frame;
        thumbFrame.origin.x = (CGRectGetWidth(self.track.frame) * percentage) - (CGRectGetWidth(self.leftThumb.frame) / 2);
        
        self.leftThumb.frame = thumbFrame;
        
        [self updateLeftMask];
    }
}

- (void)updateRightViewWithPercentage:(CGFloat)percentage
{
    [self updateRightViewWithPercentage:percentage forced:NO];
}

- (void)updateRightViewWithPercentage:(CGFloat)percentage forced:(BOOL)forced
{
    CGRect leftHandle  = [self.leftThumb convertRect:self.leftThumbHandle.frame toView:self.track];
    CGRect rightHandle = [self.rightThumb convertRect:self.rightThumbHandle.frame toView:self.track];
    
    if ((CGRectGetMaxX(leftHandle) < CGRectGetMinX(rightHandle) && (self.leftValue < self.rightValue - self.buffer)) || (self.rightThumbHandle.frame.origin.x == 0) || forced)
    {
        CGRect thumbFrame = self.rightThumb.frame;
        thumbFrame.origin.x = (CGRectGetWidth(self.track.frame) * percentage) - CGRectGetWidth(leftHandle) / 2;
        
        self.rightThumb.frame = thumbFrame;
        
        [self updateRightMask];
    }
}

- (void)updateLeftMask
{
    CGRect maskFrame = self.leftMask.frame;
    maskFrame.size.width    = CGRectGetMidX(self.leftThumb.frame) - CGRectGetMinX(self.track.frame) + (thumbSize / 2);
    maskFrame.size.height   = CGRectGetHeight(self.track.frame);
    
    self.leftMask.frame = maskFrame;
}

- (void)updateRightMask
{
    CGRect maskFrame = CGRectZero;
    maskFrame.size.width    = ABS(CGRectGetMidX(self.rightThumb.frame) - CGRectGetMaxX(self.visualTrack.frame));
    maskFrame.size.height   = CGRectGetHeight(self.track.frame);
    maskFrame.origin.x      = CGRectGetMidX(self.rightThumb.frame);

    self.rightMask.frame = maskFrame;
}

#pragma mark - Value Handling

- (void)updateLeftValueWithGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self];
    CGFloat percentage = [self percentageFromLocation:location];
    CGFloat oldValue = self.leftValue;
    
    self.leftValue = [self valueFromPercentage:percentage];

    if (oldValue != self.leftValue)
    {
        [self updateLeftViewWithPercentage:percentage forced:NO];
    }
}

- (void)updateRightValueWithGesture:(UIPanGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self];
    location.x -= thumbSize;
    CGFloat percentage = [self percentageFromLocation:location];
    CGFloat oldValue = self.rightValue;
    
    self.rightValue = [self valueFromPercentage:percentage];

    if (oldValue != self.rightValue)
    {
        [self updateRightViewWithPercentage:percentage];
    }

}

- (void)setLeftValue:(CGFloat)value
{
    if (value != _leftValue)
    {
        _leftValue = ((value <= (self.rightValue - self.buffer) || value == self.minimumValue)) ? round(value) : self.rightValue - self.buffer;
        
        if (_leftValue == self.rightValue - self.buffer)
        {
            [self updateLeftViewWithPercentage:[self percentageFromValue:_leftValue] forced:YES];
        }
        self.leftValueLabel.text = [NSString stringWithFormat:@"%.0f%@", _leftValue, self.modifierCharacter];
        
        if (!self.isLeftTracking)
        {
            [self updateLeftViewWithPercentage:[self percentageFromValue:_leftValue]];
        }
        
        [self callCallback];
    }
}

- (void)setRightValue:(CGFloat)value
{
    if (value != _rightValue)
    {
        
        _rightValue = (value >= (self.leftValue + self.buffer) || value == self.maximumValue) ? round(value) : self.leftValue + self.buffer;
        if (_rightValue == self.leftValue + self.buffer)
        {
            [self updateRightViewWithPercentage:[self percentageFromValue:_rightValue] forced:YES];
        }
        self.rightValueLabel.text = [NSString stringWithFormat:@"%.0f%@", _rightValue, self.modifierCharacter];
    
        if (!self.isRightTracking)
        {
            [self updateRightViewWithPercentage:[self percentageFromValue:_rightValue]];
         }
        
        [self callCallback];
    }
}

- (void)setLeftValue:(CGFloat)value animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:animationModifier * .2 animations:^{
            self.leftValue = value;
        }];
    }
    else
    {
        self.leftValue = value;
    }
}

- (void)setRightValue:(CGFloat)value animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:animationModifier * .2 animations:^{
            self.rightValue = value;
        }];
    }
    else
    {
        self.rightValue = value;
    }
}

#pragma mark - Gesture Recognizers

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            if (self.isInScrollview)
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
            }
            
            CGRect leftHandle  = [self.leftThumb convertRect:self.leftThumbHandle.frame toView:self.track];
            CGRect rightHandle = [self.rightThumb convertRect:self.rightThumbHandle.frame toView:self.track];

            if ([self distanceBetweenRect:leftHandle andPoint:[gesture locationInView:self]] < [self distanceBetweenRect:rightHandle andPoint:[gesture locationInView:self]])
            {

                self.leftTracking = YES;
                
                [self updateLeftValueWithGesture:gesture];
                [self.leftThumbHandle setTransform:CGAffineTransformMakeScale(1.25, 1.25)];
            }
            else
            {
                self.rightTracking = YES;
                
                [self updateRightValueWithGesture:gesture];
                [self.rightThumbHandle setTransform:CGAffineTransformMakeScale(1.25, 1.25)];
            }
        }
        case UIGestureRecognizerStateChanged:
        {
            if (self.leftTracking)
            {
                [self updateLeftValueWithGesture:gesture];
            }
            else if (self.rightTracking)
            {
                [self updateRightValueWithGesture:gesture];
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if (self.leftTracking)
            {
                self.leftTracking = NO;
                
                [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:15 options:0 animations:^{
                    [self.leftThumbHandle setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
                } completion:nil];
            }
            else if (self.rightTracking)
            {
                self.rightTracking = NO;
                [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:15 options:0 animations:^{
                    [self.rightThumbHandle setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
                } completion:nil];
            }
            
            break;
    }
}

- (CGFloat)distanceBetweenRect:(CGRect)rect andPoint:(CGPoint)point
{
    if (CGRectContainsPoint(rect, point)) return 0.f;
    
    CGPoint closest = rect.origin;
    if (rect.origin.x + rect.size.width < point.x)
        closest.x += rect.size.width; // point is far right of us
    else if (point.x > rect.origin.x)
        closest.x = point.x; // point above or below us
    if (rect.origin.y + rect.size.height < point.y)
        closest.y += rect.size.height; // point is far below us
    else if (point.y > rect.origin.y)
        closest.y = point.y; // point is straight left or right

    CGFloat a = powf(closest.y - point.y, 2.f);
    CGFloat b = powf(closest.x - point.x, 2.f);
    
    return sqrtf(a + b);
}

- (void)callCallback
{
    if (self.callback)
    {
        self.callback(self);
    }
}

@end
