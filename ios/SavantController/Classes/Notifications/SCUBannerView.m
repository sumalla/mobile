//
//  SCUBannerView.m
//  SavantController
//
//  Created by Julian Locke on 2/9/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUBannerView.h"
#import "SCUCascadingTimer.h"
#import "SCUMainViewController.h"
#import <SavantExtensions/SavantExtensions.h>

static NSString *const SAVNotificationPayloadDataKey = @"data";
static NSString *const SAVNotificationPayloadMessageKey = @"message";
static NSString *const SAVNotificationPayloadRoomKey = @"room";
static NSString *const SAVNotificationPayloadZoneKey = @"zone";
static NSString *const SAVNotificationPayloadTimeKey = @"time";
static NSString *const SAVNotificationPayloadServiceKey = @"service";
static NSString *const SAVNotificationPayloadServiceAliasKey = @"serviceAlias";
static NSString *const SAVNotificationPayloadHomeIDKey = @"homeID";
static NSString *const SAVNotificationPayloadTypeKey = @"type";
static NSString *const SAVNotificationPayloadStateKey = @"state";

static NSString *const SAVNotificationPayloadEntertainment = @"entertainment";
static NSString *const SAVNotificationPayloadLighting      = @"lighting";
static NSString *const SAVNotificationPayloadTemperature   = @"temperature";
static NSString *const SAVNotificationPayloadHumidity      = @"humidity";

@interface SCUBannerView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *detailLabel;
@property (nonatomic) UIImageView *iconView;
@property (nonatomic, weak) NSTimer *dismissTimer;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGRect upFrame;
@property (nonatomic) CGRect downFrame;

@property (nonatomic) UIWindow *window;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) CGFloat startingHeight;

@end

@implementation SCUBannerView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text
{
    self = [super initWithFrame:frame];

    if (self)
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        keyWindow.windowLevel = UIWindowLevelStatusBar;
        keyWindow.hidden = NO;
        [keyWindow addSubview:self];
        self.window = keyWindow;

        self.backgroundColor = [[SCUColors shared] color04];
        self.clipsToBounds = YES;

        //-------------------------------------------------------------------
        // Setup title label.
        //-------------------------------------------------------------------
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [[SCUColors shared] color03];
        self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];;
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.text = @"";
        [self addSubview:self.titleLabel];

        //-------------------------------------------------------------------
        // Setup detail label.
        //-------------------------------------------------------------------
        self.detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.detailLabel.textAlignment = NSTextAlignmentCenter;
        self.detailLabel.textColor = [[SCUColors shared] color03shade08];
        self.detailLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];;
        self.detailLabel.numberOfLines = 0;
        self.detailLabel.text = @"";
        self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        [self addSubview:self.detailLabel];

        //-------------------------------------------------------------------
        // Setup image view.
        //-------------------------------------------------------------------
        self.iconView = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"Lighting" tintColor:[[SCUColors shared] color03shade06]]];
        self.iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.iconView];

        //-------------------------------------------------------------------
        // Setup autolayout.
        //-------------------------------------------------------------------
        CGFloat topPadding = 15;
        CGFloat middlePadding = -1.5;
        CGFloat backPadding = 10;
        
        NSDictionary *metrics = @{@"topPadding": @(topPadding),
                               @"middlePadding": @(middlePadding),
                                 @"backPadding": @(backPadding)};


        NSDictionary *views = @{@"title": self.titleLabel,
                                @"detail": self.detailLabel,
                                @"image": self.iconView};

        [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:metrics
                                                                      views:views
                                                                    formats:@[@"|-topPadding-[image(==34)]-topPadding-[title]",
                                                                              @"|-topPadding-[image(==34)]-topPadding-[detail]-backPadding-|",
                                                                              @"V:|-topPadding-[title]-middlePadding-[detail]",
                                                                              @"V:|-topPadding-[image(==34)]",
                                                                              ]]];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        //-------------------------------------------------------------------
        // Setup image and text.
        //-------------------------------------------------------------------
        self.iconView.image = image;

        NSArray *textWords = [text componentsSeparatedByString:@" "];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = .75;

        if ([textWords count] > 4)
        {
            NSInteger topLineWordCount = 4;
            NSRange topLineRange = NSMakeRange(0, topLineWordCount);
            NSRange bottomLineRange = NSMakeRange(topLineWordCount, [textWords count] - (topLineWordCount));

            NSArray *topLine = [textWords subarrayWithRange:topLineRange];
            NSArray *bottomLine = [textWords subarrayWithRange:bottomLineRange];
            
            NSMutableAttributedString *bottomLineAttr = [[NSMutableAttributedString alloc] initWithString:[bottomLine componentsJoinedByString:@" "]];
            [bottomLineAttr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [bottomLineAttr length])];
            
            self.titleLabel.text = [topLine componentsJoinedByString:@" "];
            self.detailLabel.attributedText = bottomLineAttr;
        }
        else
        {
            self.titleLabel.text = text;
            self.detailLabel.text = @"";
        }

        //-------------------------------------------------------------------
        // Setup gestures.
        //-------------------------------------------------------------------
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [self addGestureRecognizer:tap];
        self.tapGesture = tap;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(viewPanned:)];
        [self addGestureRecognizer:pan];
        self.panGesture = pan;
        
        CGFloat height = 64.5;
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGRect detailFrame = [self.detailLabel.text boundingRectWithSize:CGSizeMake((CGRectGetWidth(self.bounds) - (2 * topPadding) - 34 - backPadding), CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:attributes
                                          context:nil];
        
        CGRect referenceFrame = [@"single line" boundingRectWithSize:CGSizeMake((CGRectGetWidth(self.bounds) - (2 * topPadding) - 34 - backPadding), CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:attributes
                                                context:nil];
        
        if (CGRectGetHeight(detailFrame) > CGRectGetHeight(referenceFrame))
        {
            height = CGRectGetHeight(detailFrame) + 50;
        }
        
        CGRect upFrame = frame;
        upFrame.origin.y = -height;
        upFrame.size.height = height;
        self.upFrame = upFrame;

        CGRect downFrame = frame;
        downFrame.origin.y = 0;
        downFrame.size.height = upFrame.size.height;
        self.downFrame = downFrame;
    }

    return self;
}

- (void)showAnimated:(BOOL)animated withVelocity:(CGFloat)velocity withCompletionHandler:(dispatch_block_t)completionHandler
{
    NSTimeInterval duration = .3;

    if (velocity > 0)
    {
        duration = fabs(CGRectGetMaxY(self.frame) - CGRectGetMaxY(self.downFrame)) / velocity;
    }
    
    if (duration > 1.5)
    {
        duration = 1.5;
    }
    
    if (animated)
    {
        [UIView animateWithDuration:duration animations:^{
            CGRect downFrame = self.downFrame;
            downFrame.size.width = self.frame.size.width;
            
            self.frame = downFrame;
        } completion:^(BOOL finished) {
            if (completionHandler)
            {
                completionHandler();
            }

            SAVWeakSelf;
            self.dismissTimer = [NSTimer sav_scheduledBlockWithDelay:6 block:^{
                
                __block BOOL forcedHidden = (self.frame.origin.y < 0);
                
                [wSelf hideAnimated:YES withVelocity:0.f withCompletionHandler:^{
                    if (!forcedHidden)
                    {
                        self.window.windowLevel = UIWindowLevelNormal;
                    }
                }];
            }];
        }];
    }
    else
    {
        self.frame = self.downFrame;

        if (completionHandler)
        {
            completionHandler();
        }

        SAVWeakSelf;
        self.dismissTimer = [NSTimer sav_scheduledBlockWithDelay:3 block:^{
            
            __block BOOL forcedHidden = (self.frame.origin.y < 0);
            
            [wSelf hideAnimated:YES withVelocity:0.f withCompletionHandler:^{
                if (!forcedHidden)
                {
                    self.window.windowLevel = UIWindowLevelNormal;
                }
            }];
        }];
    }
}

- (void)hideAnimated:(BOOL)animated withVelocity:(CGFloat)velocity withCompletionHandler:(dispatch_block_t)completionHandler
{
    self.tapGesture.enabled = NO;
    self.panGesture.enabled = NO;
    
    NSTimeInterval duration = .3;
    
    if (velocity > 0)
    {
        duration = fabs(CGRectGetMaxY(self.frame) - CGRectGetMaxY(self.upFrame)) / velocity;
    }
    
    if (duration > 1.5)
    {
        duration = 1.5;
    }

    if (animated)
    {
        [UIView animateWithDuration:duration animations:^{
            CGRect upFrame = self.upFrame;
            upFrame.size.width = self.frame.size.width;
            
            self.frame = upFrame;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            if (completionHandler)
            {
                completionHandler();
            }
        }];
    }
    else
    {
        self.frame = self.upFrame;
        [self removeFromSuperview];

        if (completionHandler)
        {
            completionHandler();
        }
    }

    if (self.dismissHandler)
    {
        self.dismissHandler(self);
    }
}

- (void)viewTapped:(UITapGestureRecognizer *)recognizer
{
    [self hideAnimated:YES withVelocity:0.f withCompletionHandler:^{
        self.window.windowLevel = UIWindowLevelNormal;
        if (self.tapHandler)
        {
            self.tapHandler();
        }
    }];
}

- (void)viewPanned:(UIPanGestureRecognizer *)recognizer
{
    self.tapGesture.enabled = NO;
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;

    CGPoint translation = [recognizer translationInView:self.superview];
    CGFloat yMinBoundary = -100.f;
    CGFloat yMaxBoundary = 0.f;
    CGFloat height = self.startingHeight;
    CGFloat maxHeight = self.detailLabel.frame.origin.y + self.detailLabel.frame.size.height + 15;
    
    CGFloat velocity = [recognizer velocityInView:self].y;
    CGFloat absoluteVelocity = fabs(velocity);
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.startingHeight = self.frame.size.height;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat y = translation.y;
        CGFloat maxY = CGRectGetMaxY(self.frame);
        
        if ((y > yMaxBoundary) || (maxY > yMaxBoundary))
        {
            height += y;
            
            if (height > maxHeight)
            {
                height = maxHeight - ((maxHeight - height) * .05);
            }
            
            CGRect frame = self.frame;
            frame.size.height = height;
            self.frame = frame;
        }
        else
        {
            if (y < yMinBoundary)
            {
                y = yMinBoundary;
            }
            else if (y > yMaxBoundary)
            {
                y = yMaxBoundary;
            }

            CGRect frame = self.frame;
            frame.origin.y = y;
            self.frame = frame;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGFloat y = CGRectGetMaxY(self.frame);
        
        CGFloat slidingClosedBoundary = 35.f;
        CGFloat dragClosedVelocityThreshold = 75.f;
        
        if ((y < slidingClosedBoundary || absoluteVelocity > dragClosedVelocityThreshold) && velocity < 0)
        {
            [self hideAnimated:YES withVelocity:absoluteVelocity withCompletionHandler:^{
                self.window.windowLevel = UIWindowLevelNormal;
            }];
        }
        else
        {
            [self showAnimated:YES withVelocity:125.f withCompletionHandler:NULL];
        }
    }
}

@end
