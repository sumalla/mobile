//
//  SCUSwipeView2.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwipeView.h"
#import "SCUGradientView.h"
#import "SCUSwipeViewPrivate.h"
@import Extensions;
@import SDK;

@interface SCUSwipeView () <UIGestureRecognizerDelegate>

@property (nonatomic) SCUSwipeViewConfiguration configuration;
@property (nonatomic) UIView *arrowView;
@property (nonatomic) UIImageView *upArrow;
@property (nonatomic) UIImageView *downArrow;
@property (nonatomic) UIImageView *leftArrow;
@property (nonatomic) UIImageView *rightArrow;
@property (nonatomic) UILabel *centerLabel;
@property (nonatomic) SCUSwipeViewDirection lastDirection;
@property (nonatomic, weak) NSTimer *holdTimer;
@property (nonatomic) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, weak) NSTimer *textTimer;
@property (nonatomic) BOOL hasPresentedInitialText;
@property (nonatomic) SCUSwipeViewDirection swipedDirections;
@property (nonatomic) BOOL understandsSwipe;

@end

@implementation SCUSwipeView

- (void)dealloc
{
    if (self.textTimer.isValid)
    {
        [self.textTimer invalidate];
    }
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(SCUSwipeViewConfiguration)configuration
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.textFadeDelay = 2;
        self.initialText = NSLocalizedString(@"Swipe to control", nil);
        self.mainText = NSLocalizedString(@"Select", nil);
        self.arrowViewSize = 300;
        self.arrowSize = CGSizeMake(32, 32);
        self.holdDelay = .45;
        self.holdAnimationInterval = .6;
        self.allowsHolding = YES;
        self.configuration = configuration;
        [self setupArrowsWithConfiguration:configuration];
        [self setupGesturesWithConfiguration:configuration];
        [self setupCenterLabel];
        self.lastDirection = SCUSwipeViewDirectionUnknown;
        self.clipsToBounds = YES;

        self.understandsSwipe = [[[SAVSettings userSettings] objectForKey:@"understandsSwipe"] boolValue];
    }

    return self;
}

#pragma mark - Overrides

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.longPressGestureRecognizer.allowableMovement = hypot(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) * 1.05;

    CGRect arrowViewFrame = CGRectMake(0, 0, self.arrowViewSize, self.arrowViewSize);
    self.arrowView.frame = CGRectIntegral(arrowViewFrame);
    self.arrowView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) - (CGRectGetHeight(self.footerView.bounds) / 2));

    self.centerLabel.frame = CGRectInset(self.arrowView.frame, 14, 14);
    self.centerLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) - (CGRectGetHeight(self.footerView.bounds) / 2));
}

- (void)updateConstraints
{
    [super updateConstraints];

    [self setSize:self.arrowSize forView:self.upArrow];
    [self setSize:self.arrowSize forView:self.downArrow];
    [self setSize:self.arrowSize forView:self.leftArrow];
    [self setSize:self.arrowSize forView:self.rightArrow];
    
    if (self.footerView)
    {
        [self sav_setHeight:self.relativeFooterSize.height forView:self.footerView isRelative:YES];
        [self sav_pinView:self.footerView withOptions:SAVViewPinningOptionsCenterX];
        [self sav_pinView:self.footerView withOptions:SAVViewPinningOptionsHorizontally withSpace:8.0f];
        [self sav_pinView:self.footerView withOptions:SAVViewPinningOptionsToBottom withSpace:8.0f];
    }
}

#pragma mark - Property overrides

- (void)setArrowColor:(UIColor *)arrowColor
{
    _arrowColor = arrowColor;
    self.upArrow.image = [self.upArrow.image tintedImageWithColor:arrowColor];
    self.downArrow.image = [self.downArrow.image tintedImageWithColor:arrowColor];
    self.leftArrow.image = [self.leftArrow.image tintedImageWithColor:arrowColor];
    self.rightArrow.image = [self.rightArrow.image tintedImageWithColor:arrowColor];
}

- (void)setArrowViewSize:(CGFloat)arrowViewSize
{
    _arrowViewSize = arrowViewSize;
    [self setNeedsLayout];
}

- (void)setArrowSize:(CGSize)arrowSize
{
    _arrowSize = arrowSize;
    [self setNeedsUpdateConstraints];
}

- (void)setHoldDelay:(NSTimeInterval)holdDelay
{
    _holdDelay = holdDelay;
    self.longPressGestureRecognizer.minimumPressDuration = holdDelay;
}

- (void)setAllowsHolding:(BOOL)allowsHolding
{
    _allowsHolding = allowsHolding;
    self.longPressGestureRecognizer.enabled = allowsHolding;
}

// TODO: Why is this necessary? Breaks SCUButton long hold gesture
- (void)setFooterView:(UIView *)footerView
{
    [_footerView removeFromSuperview];

    _footerView = footerView;

    [self addSubview:footerView];

    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)setRelativeFooterSize:(CGSize)relativeFooterSize
{
    _relativeFooterSize = relativeFooterSize;

    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

#pragma mark - Setup

- (void)setupArrowsWithConfiguration:(SCUSwipeViewConfiguration)configuration
{
    UIView *arrowView = [[UIView alloc] initWithFrame:CGRectZero];

    NSString *imagePrefix = @"white_arrow";
    UIColor *tintColor = [[SCUColors shared] color04];

    if (configuration & SCUSwipeViewConfigurationHorizontal &&
        configuration & SCUSwipeViewConfigurationVertical)
    {
        imagePrefix = @"swipe_arrow";
        tintColor = [[SCUColors shared] color03shade05];
    }

    if (configuration & SCUSwipeViewConfigurationVertical)
    {
        UIImageView *upArrow = [self arrowImageViewWithImage:[imagePrefix stringByAppendingString:@"_up"]];
        [arrowView addSubview:upArrow];
        self.upArrow = upArrow;

        UIImageView *downArrow = [self arrowImageViewWithImage:[imagePrefix stringByAppendingString:@"_down"]];
        [arrowView addSubview:downArrow];
        self.downArrow = downArrow;

        [arrowView sav_pinView:upArrow withOptions:SAVViewPinningOptionsCenterX | SAVViewPinningOptionsToTop];
        [arrowView sav_pinView:downArrow withOptions:SAVViewPinningOptionsCenterX | SAVViewPinningOptionsToBottom];
    }
    if (configuration & SCUSwipeViewConfigurationHorizontal)
    {
        UIImageView *leftArrow = [self arrowImageViewWithImage:[imagePrefix stringByAppendingString:@"_left"]];
        [arrowView addSubview:leftArrow];
        self.leftArrow = leftArrow;

        UIImageView *rightArrow = [self arrowImageViewWithImage:[imagePrefix stringByAppendingString:@"_right"]];
        [arrowView addSubview:rightArrow];
        self.rightArrow = rightArrow;

        [arrowView sav_pinView:leftArrow withOptions:SAVViewPinningOptionsCenterY | SAVViewPinningOptionsToLeft];
        [arrowView sav_pinView:rightArrow withOptions:SAVViewPinningOptionsCenterY | SAVViewPinningOptionsToRight];
    }

    self.arrowColor = tintColor;

    [self addSubview:arrowView];
    self.arrowView = arrowView;
}

- (void)setupGesturesWithConfiguration:(SCUSwipeViewConfiguration)configuration
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = .5;
    [self addGestureRecognizer:longPress];
    self.longPressGestureRecognizer = longPress;

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = self;
    [tapGestureRecognizer requireGestureRecognizerToFail:longPress];
    [self addGestureRecognizer:tapGestureRecognizer];

    NSMutableArray *gestures = [NSMutableArray array];

    if (configuration & SCUSwipeViewConfigurationVertical)
    {
        [gestures addObject:[self swipeGestureWithDirection:UISwipeGestureRecognizerDirectionUp]];
        [gestures addObject:[self swipeGestureWithDirection:UISwipeGestureRecognizerDirectionDown]];
    }

    if (configuration & SCUSwipeViewConfigurationHorizontal)
    {
        [gestures addObject:[self swipeGestureWithDirection:UISwipeGestureRecognizerDirectionLeft]];
        [gestures addObject:[self swipeGestureWithDirection:UISwipeGestureRecognizerDirectionRight]];
    }

    for (UISwipeGestureRecognizer *recognizer in gestures)
    {
        recognizer.delegate = self;
        [self addGestureRecognizer:recognizer];
    }
}

- (void)setupCenterLabel
{
    UILabel *centerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    centerLabel.textColor = [[SCUColors shared] color04];
    centerLabel.textAlignment = NSTextAlignmentCenter;
    centerLabel.numberOfLines = 0;
    centerLabel.minimumScaleFactor = .7;
    centerLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:centerLabel];

    [self sav_pinView:centerLabel withOptions:SAVViewPinningOptionsCenterX];
    [self sav_pinView:centerLabel withOptions:SAVViewPinningOptionsCenterY withSpace:CGRectGetHeight(self.footerView.frame)];
    self.centerLabel = centerLabel;
}

- (UIImageView *)arrowImageViewWithImage:(NSString *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:image]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

- (void)setSize:(CGSize)size forView:(UIView *)view
{
    [view.superview sav_setSize:size forView:view isRelative:NO];
}

- (void)setRelativeSize:(CGSize)size forView:(UIView *)view
{
    [view.superview sav_setHeight:size.height forView:view isRelative:YES];
    [view.superview sav_setWidth:size.width forView:view isRelative:YES];
}

- (UISwipeGestureRecognizer *)swipeGestureWithDirection:(UISwipeGestureRecognizerDirection)direction
{
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    gesture.direction = direction;
    return gesture;
}

#pragma mark - Gesture handling

- (void)handleSwipe:(UISwipeGestureRecognizer *)recognizer
{
    if (!CGRectContainsPoint(self.footerView.frame, [recognizer locationInView:self]))
    {
        [self animateWithDirection:(SCUSwipeViewDirection)recognizer.direction];
        [self beginMoveInDirection:(SCUSwipeViewDirection)recognizer.direction isHold:NO];
        [self didSwipeWithDirection:(SCUSwipeViewDirection)recognizer.direction];
        [self.holdTimer invalidate];

        SAVWeakSelf;
        self.holdTimer = [NSTimer sav_scheduledBlockWithDelay:self.holdDelay + .1 block:^{
            wSelf.lastDirection = SCUSwipeViewDirectionUnknown;
        }];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if (!CGRectContainsPoint(self.footerView.frame, [recognizer locationInView:self]))
    {
        SCUSwipeViewDirection direction = SCUSwipeViewDirectionUnknown;

        if (self.configuration & SCUSwipeViewConfigurationCenter)
        {
            //-------------------------------------------------------------------
            // Center configurations are special cased.
            //-------------------------------------------------------------------
            direction = SCUSwipeViewDirectionCenter;
        }
        else
        {
            direction = [self directionFromLocation:[recognizer locationInView:self]];
        }

        if (direction != SCUSwipeViewDirectionUnknown)
        {
            [self animateWithDirection:direction];
            [self beginMoveInDirection:direction isHold:NO];
            self.lastDirection = SCUSwipeViewDirectionUnknown;
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint currentLocation = [recognizer locationInView:self];

    if (!CGRectContainsPoint(self.footerView.frame, currentLocation))
    {
        switch (recognizer.state)
        {
            case UIGestureRecognizerStateBegan:
            {
                [self.holdTimer invalidate];
                NSTimeInterval initialDelay = 0;

                if (self.lastDirection == SCUSwipeViewDirectionUnknown)
                {
                    self.lastDirection = [self directionFromLocation:currentLocation];
                }
                else
                {
                    if (self.holdAnimationInterval > self.holdDelay)
                    {
                        initialDelay = self.holdAnimationInterval - self.holdDelay;
                    }
                }

                [self beginMoveInDirection:self.lastDirection isHold:YES];

                SAVWeakSelf;

                if (initialDelay > 0)
                {
                    //-------------------------------------------------------------------
                    // Setup an initial delay so that the animations happen on a consistent
                    // interval.
                    //-------------------------------------------------------------------
                    self.holdTimer = [NSTimer sav_scheduledBlockWithDelay:initialDelay block:^{
                        wSelf.holdTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.holdAnimationInterval repeats:YES block:^{
                            [wSelf animateWithDirection:wSelf.lastDirection];
                        }];

                        [wSelf.holdTimer fire];
                    }];
                }
                else
                {
                    self.holdTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.holdAnimationInterval repeats:YES block:^{
                        [wSelf animateWithDirection:wSelf.lastDirection];
                    }];

                    [self.holdTimer fire];
                }

                break;
            }
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
            case UIGestureRecognizerStateFailed:
                [self.holdTimer invalidate];
                [self endHoldInDirection:self.lastDirection];
                self.lastDirection = SCUSwipeViewDirectionUnknown;
                break;
            default:
                break;
        }
    }
}

- (SCUSwipeViewDirection)directionFromLocation:(CGPoint)location
{
    SCUSwipeViewDirection direction = SCUSwipeViewDirectionUnknown;

    if (self.configuration & SCUSwipeViewConfigurationCenter && (self.configuration == SCUSwipeViewConfigurationCenter || CGRectContainsPoint(self.arrowView.frame, location)))
    {
        direction = SCUSwipeViewDirectionCenter;
    }
    else if (self.configuration & SCUSwipeViewConfigurationHorizontal && self.configuration & SCUSwipeViewConfigurationVertical)
    {
        if (self.configuration & SCUSwipeViewConfigurationCenter)
        {
            direction = SCUSwipeViewDirectionCenter;
        }
        else
        {
            //-------------------------------------------------------------------
            // *--------*
            // |L      R|
            // | \  * / |
            // |  \  /  |
            // | * \/   |
            // |   /\ * |
            // |  /  \  |
            // | / *  \ |
            // |/      \|
            // *--------*
            //
            // The left line moves from the top left to the bottom right.
            // The right line moves from the top right to the bottom left.
            //-------------------------------------------------------------------
            CGFloat minX = CGRectGetMinX(self.bounds);
            CGFloat maxX = CGRectGetMaxX(self.bounds);
            CGFloat minY = CGRectGetMinY(self.bounds);
            CGFloat maxY = CGRectGetMaxY(self.bounds);
            BOOL belowLeft = [self isPoint:location belowLineAtStartingPoint:CGPointMake(minX, minY) endingPoint:CGPointMake(maxX, maxY)];
            BOOL belowRight = [self isPoint:location belowLineAtStartingPoint:CGPointMake(maxX, minY) endingPoint:CGPointMake(minX, maxY)];

            if (belowLeft && belowRight)
            {
                direction = SCUSwipeViewDirectionDown;
            }
            else if (!belowLeft && !belowRight)
            {
                direction = SCUSwipeViewDirectionUp;
            }
            else if (belowLeft && !belowRight)
            {
                direction = SCUSwipeViewDirectionLeft;
            }
            else
            {
                direction = SCUSwipeViewDirectionRight;
            }
        }
    }
    else if (self.configuration & SCUSwipeViewConfigurationHorizontal)
    {
        if (location.x < CGRectGetMidX(self.bounds))
        {
            direction = SCUSwipeViewDirectionLeft;
        }
        else
        {
            direction = SCUSwipeViewDirectionRight;
        }
    }
    else if (self.configuration & SCUSwipeViewConfigurationVertical)
    {
        if (location.y < CGRectGetMidY(self.bounds))
        {
            direction = SCUSwipeViewDirectionUp;
        }
        else
        {
            direction = SCUSwipeViewDirectionDown;
        }
    }

    return direction;
}

- (BOOL)isPoint:(CGPoint)point belowLineAtStartingPoint:(CGPoint)startPoint endingPoint:(CGPoint)endPoint
{
    //-------------------------------------------------------------------
    // Find the slope and then calculate the y-intercept for the startPoint
    // and the new point. If the new y intercept is below the original
    // y intercept, the point is below the line.
    //-------------------------------------------------------------------
    CGFloat slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
    CGFloat originalYIntercept = (slope * startPoint.x) - startPoint.y;
    CGFloat newYIntercept = (slope * point.x) -  point.y;
    return newYIntercept < originalYIntercept;
}

#pragma mark - Delegate methods

- (void)beginMoveInDirection:(SCUSwipeViewDirection)direction isHold:(BOOL)isHold
{
    if ([self.delegate respondsToSelector:@selector(swipeView:didReceiveInteraction:isHold:)])
    {
        [self.delegate swipeView:self didReceiveInteraction:direction isHold:isHold];
    }
}

- (void)endHoldInDirection:(SCUSwipeViewDirection)direction
{
    if ([self.delegate respondsToSelector:@selector(swipeView:holdInteractionDidEnd:)])
    {
        [self.delegate swipeView:self holdInteractionDidEnd:direction];
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Animation

- (void)animateWithDirection:(SCUSwipeViewDirection)direction
{
    //-------------------------------------------------------------------
    // Assume the user knows how to swipe if they've tried all directions
    //-------------------------------------------------------------------
    if (!self.understandsSwipe)
    {
        self.swipedDirections |= direction;

        if (self.swipedDirections ==
            (SCUSwipeViewDirectionRight | SCUSwipeViewDirectionLeft | SCUSwipeViewDirectionUp | SCUSwipeViewDirectionDown | SCUSwipeViewDirectionCenter))
        {
            [[SAVSettings userSettings] setObject:@(YES) forKey:@"understandsSwipe"];
            [[SAVSettings userSettings] synchronize];
            self.understandsSwipe = YES;
        }
    }

    self.lastDirection = direction;

    if (direction == SCUSwipeViewDirectionUnknown)
    {
        return;
    }

    SCUGradientView *gradientView = [[SCUGradientView alloc] initWithFrame:CGRectZero
                                                                 andColors:@[[UIColor clearColor], self.swipeColor ? self.swipeColor : [[SCUColors shared] color01]]];

    gradientView.radial = YES;
    gradientView.clipsToBounds = YES;
    [self addSubview:gradientView];
    [self sendSubviewToBack:gradientView];

    CGFloat startingX = 0;
    CGFloat startingY = 0;
    CGFloat size = self.arrowViewSize + 60;

    switch (direction)
    {
        case SCUSwipeViewDirectionRight:
        {
            startingX = 0;
            startingY = CGRectGetMidY(self.bounds) - (CGRectGetHeight(self.footerView.bounds) / 2);
            break;
        }
        case SCUSwipeViewDirectionLeft:
        {
            startingX = CGRectGetMaxX(self.bounds);
            startingY = CGRectGetMidY(self.bounds) - (CGRectGetHeight(self.footerView.bounds) / 2);
            break;
        }
        case SCUSwipeViewDirectionUp:
        {
            startingX = CGRectGetMidX(self.bounds);
            startingY = CGRectGetMaxY(self.bounds);
            break;
        }
        case SCUSwipeViewDirectionDown:
        {
            startingX = CGRectGetMidX(self.bounds);
            startingY = 0;
            break;
        }
        case SCUSwipeViewDirectionCenter:
        {
            startingX = self.arrowView.center.x;
            startingY = self.arrowView.center.y;
            size = self.arrowViewSize;
            break;
        }
        default:
        {
            break;
        }
    }

    CGFloat maxSize = MAX(CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds)) * 2.5;
    CGFloat scale = (maxSize / size) + 1;

    gradientView.frame = CGRectMake(0, 0, size, size);
    gradientView.layer.cornerRadius = size / 2;
    gradientView.center = CGPointMake(startingX, startingY);

    CGFloat duration = scale / 10;

    if (duration > .6)
    {
        duration = .6;
    }

    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction animations:^{
        gradientView.transform = CGAffineTransformMakeScale(scale, scale);
    } completion:^(BOOL finished) {
        [gradientView removeFromSuperview];
    }];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];

    if (newWindow)
    {
        if (self.hasPresentedInitialText)
        {
            return;
        }

        self.hasPresentedInitialText = YES;

        if (self.initialText && !self.understandsSwipe)
        {
            self.centerLabel.text = self.initialText;

            if (self.mainText)
            {
                self.arrowView.alpha = 0;

                SAVWeakSelf;
                self.textTimer = [NSTimer sav_scheduledBlockWithDelay:self.textFadeDelay block:^{

                    wSelf.centerLabel.alpha = 0;
                    wSelf.centerLabel.text = wSelf.mainText;

                    [UIView animateWithDuration:1 animations:^{
                        wSelf.centerLabel.alpha = 1;
                        wSelf.arrowView.alpha = 1;
                    }];
                }];
            }
        }
        else
        {
            self.centerLabel.text = self.mainText;
        }
    }
    else
    {
        self.centerLabel.text = self.mainText;
        self.arrowView.alpha = 1;
        [self.textTimer invalidate];
        self.textTimer = nil;
    }
}

@end
