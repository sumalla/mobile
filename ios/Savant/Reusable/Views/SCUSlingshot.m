//
//  SCUSlingshot.m
//  CAPractice
//
//  Created by Stephen Silber on 8/1/14.
//  Copyright (c) 2014 SavantSystems. All rights reserved.
//

#import "SCUSlingshot.h"
#import "SCUButton.h"
#import "SCUGradientView.h"

@import SDK;
@import Extensions;
//#import <pop/POP.h>

@interface SCUSlingshotManager ()

@property (nonatomic) NSMutableDictionary *slingshots;

@end

@implementation SCUSlingshotManager

+ (instancetype)sharedInstance
{
    static SCUSlingshotManager *sharedInstance;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCUSlingshotManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.slingshots = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)updateService:(SAVService *)service forSlingshot:(SCUSlingshot *)slingshot
{
    NSMutableArray *slingshots = self.slingshots[service.identifier];
    
    if ([slingshots containsObject:slingshot])
    {
        [slingshots removeObject:slingshot];
    }
    
    [self insertSlingshot:slingshot forKey:service.identifier];
}

- (void)insertSlingshot:(SCUSlingshot *)slingshot forKey:(NSString *)key
{
    // If we get a nil key, then the slingshot does not need to be grouped with other slingshots
    if (key)
    {
        NSHashTable *weakObjects = self.slingshots[key];

        if (!weakObjects)
        {
            weakObjects = [NSHashTable weakObjectsHashTable];
            self.slingshots[key] = weakObjects;
        }

        [weakObjects addObject:slingshot];
    }
}

@end

@interface SCUSlingshot ()// <POPAnimatorObserving>

@property (nonatomic) UIView *thumb;
@property (nonatomic) UIView *track;
@property (nonatomic) UIView *trackFill;
@property (nonatomic) SAVService *service;

@property (nonatomic, weak) NSTimer *callbackTimer;

@property (nonatomic) BOOL animating;
@property (nonatomic) BOOL onlyVisual;

@property (nonatomic) NSInteger value;
@property (nonatomic) NSInteger oldValue;
@property (nonatomic) NSInteger releaseValue;

@property (nonatomic) id animator;
//@property (nonatomic) POPAnimator *animator;
@property (nonatomic) NSString *currentAnimationKey;

@property (nonatomic) SCUSlingshotDirection currentAnimationDirection;
@property (nonatomic) SCUSlingshotDirection lastDirection;
@property (nonatomic) SCUSlingshotDirection currentDirection;

@property (nonatomic, getter = isTracking) BOOL tracking;

@property (nonatomic) NSTimer *interactionTimer;
@property (nonatomic) NSTimer *initialTimer;
@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic) UIView *indicatorTab;
@property (nonatomic) UILabel *indicatorLabel;

@end

@implementation SCUSlingshot

- (void)dealloc
{
	NSMutableArray *slingshots = [[SCUSlingshotManager sharedInstance] slingshots][self.service.identifier];
	if (slingshots)
	{
		for (SCUSlingshot *slingshot in slingshots)
		{
			if ([slingshot isEqual:self])
			{
				[slingshots removeObject:self];
				break;
			}
		}
		[[SCUSlingshotManager sharedInstance] slingshots][self.service.identifier] = slingshots;
	}
    
    [self.indicatorTab removeFromSuperview];
}

- (instancetype)initWithFrame:(CGRect)frame andService:(SAVService *)service
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
//        self.animator = [POPAnimator sharedAnimator];

        self.minimumValue = -5;
        self.maximumValue = 5;
        self.delta = 1;
        self.service = service;
        
        self.backgroundColor = [UIColor clearColor];
        self.trackFillColor = [[SCUColors shared] color01];
        
        [self setupSlingshotControls];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        [[SCUSlingshotManager sharedInstance] insertSlingshot:self forKey:service.identifier];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andService:nil];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 24);
}

- (void)updateService:(SAVService *)service
{
    self.service = service;
    [[SCUSlingshotManager sharedInstance] updateService:service forSlingshot:self];
}

- (void)setupSlingshotControls
{
    CGFloat thumbHeight = 20;
    CGFloat thumbWidth  = thumbHeight * 2.5;

    self.thumb = [[UIView alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, thumbHeight)];
    self.thumb.backgroundColor = [[SCUColors shared] color04];
    self.thumb.layer.cornerRadius = thumbHeight / 2;

    UIImageView *handleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    handleImageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *handle = [UIImage sav_imageNamed:@"Grip" tintColor:[[SCUColors shared] color03shade07]];
    handleImageView.image = handle;
    
    [self.thumb addSubview:handleImageView];
    [self.thumb sav_addFlushConstraintsForView:handleImageView withPadding:4.0f];

    self.track = [[UIView alloc] initWithFrame:CGRectZero];
    self.track.backgroundColor = [[SCUColors shared] color03shade08];
    self.track.layer.masksToBounds = YES;
    
    self.trackFill = [[UIView alloc] initWithFrame:CGRectZero];
    self.trackFill.backgroundColor = [[SCUColors shared] color01];
    self.trackFill.clipsToBounds = YES;
    
    [self addSubview:self.track];
    [self.track addSubview:self.trackFill];
    [self addSubview:self.thumb];

    [self sav_pinView:self.track withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsCenterY];
 
    [self sav_setHeight:[UIScreen screenPixel] * 4 forView:self.track isRelative:NO];
    self.track.layer.cornerRadius = [UIScreen screenPixel] * 2;
    
    self.indicatorTab = [[UIView alloc] initWithFrame:CGRectZero];
    self.indicatorTab.backgroundColor = [[SCUColors shared] color04];
    self.indicatorTab.alpha = 0.85;
    self.indicatorTab.layer.cornerRadius = 4.0f;
    
    self.indicatorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.indicatorLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h8];
    self.indicatorLabel.textColor = [[SCUColors shared] color01];
    self.indicatorLabel.textAlignment = NSTextAlignmentCenter;
    self.indicatorLabel.text = @"0";

    [self.indicatorTab addSubview:self.indicatorLabel];
    [self.indicatorTab sav_addFlushConstraintsForView:self.indicatorLabel withPadding:5.0f];
    
    self.indicatorTab.hidden = YES;
    
    UIView *topView = [UIApplication sharedApplication].keyWindow;
    [topView addSubview:self.indicatorTab];
    [self drawIndicatorArrow];
}

- (void)layoutSubviews
{
    if (!self.isTracking)
    {
        [super layoutSubviews];

        [self updateThumbWithPercentage:0.5];
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

- (void)setThumbColor:(UIColor *)thumbColor
{
    _thumbColor = thumbColor;
    self.thumb.backgroundColor = thumbColor;
}

- (void)setTrackFillColor:(UIColor *)trackFillColor
{
    _trackFillColor = trackFillColor;
    self.trackFill.backgroundColor = trackFillColor;
}

- (void)setTracking:(BOOL)tracking
{
    if (tracking != _tracking)
    {
        _tracking = tracking;

        if (!tracking)
        {
            [self.interactionTimer invalidate];
            self.interactionTimer = nil;
        }
        else
        {
            self.interactionTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(callInteractionCallback) userInfo:nil repeats:YES];
            [self.interactionTimer fire];
        }
    }
}

//========================================================================
// Bring thumb back to the center
//========================================================================
- (void)snapBackToCenterWithGesture:(UIPanGestureRecognizer *)gesture
{
    self.releaseValue = self.value;
    self.value    = 0;
    self.oldValue = 0;
    self.tracking = NO;
    
//    [self.trackFill pop_removeAllAnimations];

    self.animating = NO;

    [self hideTrackFillFromDirection:self.currentDirection];
    
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:.70 initialSpringVelocity:30 options:0 animations:^{
        [self updateViewWithPercentage:0.5];
    } completion:^ (BOOL finished) {
        [self.animator removeObserver:self];
        self.indicatorLabel.text = @"0";

    }];
}

//========================================================================
// Update all views on percentage update
//========================================================================
- (void)updateViewWithPercentage:(CGFloat)percentage
{
    [self updateThumbWithPercentage:percentage];
    if (!self.onlyVisual && self.showsIndicator)
    {
        [self updateIndicatorTab];
    }
}

- (void)updateIndicatorTab
{
        CGRect thumbFrame = [self convertRect:self.thumb.frame toView:[UIApplication sharedApplication].keyWindow];
        CGRect frame = CGRectMake(CGRectGetMidX(thumbFrame) - 30.0f, CGRectGetMinY(thumbFrame) - CGRectGetHeight(thumbFrame) - 25.0f, 60.0f, self.indicatorLabel.intrinsicContentSize.height + 10.0f);
        self.indicatorTab.frame = frame;
}

- (void)updateThumbWithPercentage:(CGFloat)percentage
{
    CGRect thumbFrame = self.thumb.frame;

    thumbFrame.size.height = 20;
    thumbFrame.size.width = 50;

    thumbFrame.origin.x = (CGRectGetWidth(self.track.frame) * percentage) + self.track.frame.origin.x - (thumbFrame.size.width / 2);
    thumbFrame.origin.y = self.track.center.y - (CGRectGetHeight(thumbFrame) / 2);

    if (isnan(thumbFrame.origin.x))
    {
        thumbFrame.origin.x = 0;
    }

    if (isnan(thumbFrame.origin.y))
    {
        thumbFrame.origin.y = 0;
    }

    self.thumb.frame = thumbFrame;
}

- (void)updateValueWithGesture:(UIPanGestureRecognizer *)gesture
{
    [self updateValueWithGesture:gesture initial:NO];
}

- (void)updateValueWithGesture:(UIPanGestureRecognizer *)gesture initial:(BOOL)initial
{
    CGFloat percentage = [self percentageFromLocation:[gesture locationInView:self.track]];

    self.oldValue = self.value;
    self.value = [self valueFromPercentage:percentage];
    
    // Send a callback when the value changes so that the slingshot is more responsive
    // SRS TODO: This demo system check is ugly.
    if (self.value != self.oldValue)
    {
        if (!self.onlyVisual && self.showsIndicator)
        {
            self.indicatorLabel.text = self.value < 1 ? [NSString stringWithFormat:@"%li", (long)self.value] : [NSString stringWithFormat:@"+%li", (long)self.value];
        }
        if (self.callbackTimer && self.callback && ![[Savant control] isDemoSystem])
        {
            [self callCallback];
        }
    }
    
    // Check our initial velocity based on location to detect user starting from the wrong side
    if (initial)
    {
        CGPoint velocity = [gesture velocityInView:self];
        
        if (velocity.x < 0 && percentage > .45)
        {
            if (self.value > 0)
            {
                self.value = [self valueFromPercentage:0.4];
            }
        }
        else if(velocity.x > 0 && percentage < .55)
        {
            if (self.value < 0)
            {
                self.value = [self valueFromPercentage:0.6];
            }
        }
    }

    self.lastDirection = self.currentDirection;
    
    if (percentage < 0.5)
    {
        self.currentDirection = SCUSlingshotDirectionLeft;
    }
    else if (percentage > 0.5)
    {
        self.currentDirection = SCUSlingshotDirectionRight;
    }

    if (self.value != 0 && self.tracking && !self.animating && self.callbackTimer)
    {
        self.animating = YES;
        
        [self animate];
    }
    
    [self updateViewWithPercentage:percentage];
}

#pragma mark - Current values and percentages

- (CGFloat)percentageFromLocation:(CGPoint)location
{
    CGFloat percentage = location.x / CGRectGetWidth(self.track.frame);

    if (percentage <= 0)
    {
        percentage = 0;
    }
    else if (percentage > 1)
    {
        percentage = 1;
    }

    return percentage;
}

- (CGFloat)valueFromPercentage:(CGFloat)percentage
{
    CGFloat minimumValue = ABS(self.minimumValue);
    CGFloat maximumValue = ABS(self.maximumValue) + minimumValue;
    CGFloat value = (percentage * maximumValue) - minimumValue;

    return round(value);
}

- (CGFloat)percentageFromValue:(CGFloat)value
{
    CGFloat minimumValue = ABS(self.minimumValue);
    CGFloat maximumValue = ABS(self.maximumValue) + minimumValue;
    
    return (value + minimumValue) / maximumValue;
}

#pragma mark - Gesture handling

- (void)handlePan:(UIPanGestureRecognizer *)gesture onlyVisually:(BOOL)visually
{
    self.onlyVisual = visually;
    
    if (self.isMaster)
    {
        // Forward pan to children slingshots. This should only happen on the masterVolume slingshot
        NSArray *slingshots = [[SCUSlingshotManager sharedInstance] slingshots][self.service.identifier];
        if (slingshots)
        {
            for (SCUSlingshot *slingshot in slingshots)
            {
                if (!slingshot.isMaster && slingshot.superview != nil)
                {
                    [slingshot handlePan:gesture onlyVisually:YES];
                }
            }
        }
    }
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        {
            self.initialTimer = [NSTimer sav_scheduledTimerWithTimeInterval:0.15 repeats:NO block:^{

                if (self.callbackTimeInterval > 0)
                {
                    self.callbackTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.callbackTimeInterval repeats:YES block:^{
                        [self callCallback];
                    }];
                    
                    [self.callbackTimer fire];
                }
                self.initialTimer = nil;
            }];
            
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
            
//            [self.animator addObserver:self];

            [self updateValueWithGesture:gesture initial:YES];
            
            if (!visually && self.showsIndicator)
            {
                self.indicatorTab.hidden = NO;
                self.indicatorTab.layer.opacity = 0;
                [UIView animateWithDuration:0.20 animations:^{
                    self.indicatorTab.layer.opacity = 1.0;
                }];
            }

            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            [self updateValueWithGesture:gesture];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            [self snapBackToCenterWithGesture:gesture];
            [self.callbackTimer invalidate];
            
            if (self.initialTimer)
            {
                [self.initialTimer invalidate];
                [self callInitialCallback];
            }
            else
            {
                [self callCallback];
                [self callReleaseCallback];
            }

            self.tracking = NO;
            
            if (!visually && self.showsIndicator)
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
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    [self handlePan:gesture onlyVisually:NO];
}

#pragma mark - Callbacks

- (void)callCallback
{
    if (self.callback && self.tracking && !self.onlyVisual)
    {
        self.callback(self, self.value);
    }
}

- (void)callInitialCallback
{
    if (self.callback && !self.onlyVisual)
    {
        NSInteger value = (self.releaseValue < 0) ? -1 : 1;
        self.callback(self, value);
    }
}

- (void)callInteractionCallback
{
    if (self.interactionCallback)
    {
        self.interactionCallback();
    }
}

- (void)callReleaseCallback
{
    if (self.releaseCallback && !self.onlyVisual)
    {
        self.releaseCallback(self);
    }
}

#pragma mark - Animation

- (NSString *)generateAnimationKeyWithTitle:(NSString *)title
{
    NSString *key = [NSString stringWithFormat:@"%@:%@", title, [[NSUUID UUID] UUIDString]];
    self.currentAnimationKey = key;
    
    return key;
}

- (void)hideTrackFillFromDirection:(SCUSlingshotDirection)direction
{
    CGRect fillFrame = self.trackFill.frame;
    if (direction == SCUSlingshotDirectionRight)
    {
        fillFrame.origin.x = 0;
        fillFrame.size.width = 0;
    }
    else
    {
        fillFrame.size.width = 0;
        fillFrame.origin.x = CGRectGetWidth(self.track.bounds);
    }
    
    SAVWeakSelf;
    [UIView animateWithDuration:0.20 animations:^{
        wSelf.trackFill.frame = fillFrame;
    } completion:^(BOOL finished) {
        if (self.animating)
        {
            [wSelf animate];
        }
        
    }];
}

- (void)animate
{
    if (self.tracking)
    {
        CGRect fillFrame = CGRectZero;
        fillFrame.origin.y = 0;
        fillFrame.size.height = CGRectGetHeight(self.track.frame);

        if (self.currentDirection == SCUSlingshotDirectionRight)
        {
            fillFrame.origin.x = 0;
            fillFrame.size.width = 0;
        }
        else
        {
            fillFrame.origin.x = CGRectGetMaxX(self.track.bounds);
            fillFrame.size.width = CGRectGetWidth(self.track.bounds);
        }
        
        self.trackFill.frame = fillFrame;
        
        CGRect endFrame = fillFrame;
        
        if (self.currentDirection == SCUSlingshotDirectionRight)
        {
            endFrame.size.width = CGRectGetWidth(self.track.bounds) + 5;
        }
        else
        {
            endFrame.origin.x = -5;
        }
        
        self.trackFill.layer.opacity = 1.0;
        
        if (self.value != 0)
        {
//            POPSpringAnimation *moveFillFrame = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
//            moveFillFrame.toValue = [NSValue valueWithCGRect:endFrame];
//            moveFillFrame.dynamicsFriction = 80 / labs(self.value);
//            moveFillFrame.dynamicsMass     = 80 / labs(self.value);
//            
//            [self.trackFill pop_addAnimation:moveFillFrame forKey:[self generateAnimationKeyWithTitle:@"moveFillFrame"]];
            self.currentAnimationDirection = self.currentDirection;
        }
        else
        {
            self.animating = NO;
        }
        
    }
}

- (void)endAnimation
{
//    [self.trackFill pop_removeAnimationForKey:self.currentAnimationKey];
    [self animate];
}

//- (void)animatorWillAnimate:(POPAnimator *)animator
//{
//    CGRect fillFrame = ((CALayer *)self.trackFill.layer.presentationLayer).frame;
//    CGRect thumbFrame = ((CALayer *)self.thumb.layer.presentationLayer).frame;
//    
//    if (self.currentAnimationDirection == self.currentDirection)
//    {
//        if (self.currentDirection == SCUSlingshotDirectionRight)
//        {
//            if (CGRectGetWidth(fillFrame) > CGRectGetMidX(thumbFrame))
//            {
//                [self endAnimation];
//            }
//        }
//        else
//        {
//            if (CGRectGetMinX(fillFrame) < CGRectGetMidX(thumbFrame) && CGRectGetMinX(fillFrame) != 0.00)
//            {
//                [self endAnimation];
//            }
//        }
//    }
//    else
//    {
//        if (self.currentAnimationDirection == SCUSlingshotDirectionRight)
//        {
//            if (CGRectGetWidth(fillFrame) > CGRectGetMidX(thumbFrame))
//            {
//                [self endAnimation];
//            }
//        }
//        else
//        {
//            if (CGRectGetMinX(fillFrame) < CGRectGetMidX(thumbFrame) && CGRectGetMinX(fillFrame) != 0.00)
//            {
//                [self endAnimation];
//            }
//        }
//    }
//}

@end
