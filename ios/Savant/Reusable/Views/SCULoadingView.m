//
//  SCUFullscreenLoadingView.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULoadingView.h"
@import Extensions;

@interface SCULoadingView ()

@property (nonatomic) UIView *titleContainer;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *buttonContainer;
@property (nonatomic) UIView *buttonView;
@property (nonatomic) NSArray *buttons;
@property (nonatomic) UIImageView *centerImageView;
@property (nonatomic, weak) NSTimer *animationTimer;
@property (nonatomic) CAReplicatorLayer *animationLayer;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) UILabel *progressLabel;

@end

@implementation SCULoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.titleContainer = [[UIView alloc] initWithFrame:CGRectZero];
        self.titleContainer.hidden = YES;
        self.titleContainer.alpha = .8;
        [self addSubview:self.titleContainer];

        self.buttonContainer = [[UIView alloc] initWithFrame:CGRectZero];
        self.buttonContainer.hidden = YES;
        self.buttonContainer.alpha = .8;
        [self addSubview:self.buttonContainer];

        self.buttonContainer.cornerRadius = 2;
        self.buttonContainer.borderWidth = [UIScreen screenPixel];
        self.buttonContainer.borderColor = [[SCUColors shared] color04];

        if ([UIDevice isPhone])
        {
            [self sav_pinView:self.buttonContainer withOptions:SAVViewPinningOptionsToLeft | SAVViewPinningOptionsToRight withSpace:20];
        }
        else
        {
            [self sav_setWidth:384 forView:self.buttonContainer isRelative:NO];
            [self sav_pinView:self.buttonContainer withOptions:SAVViewPinningOptionsCenterX];
        }
        
        [self sav_pinView:self.buttonContainer withOptions:SAVViewPinningOptionsToBottom withSpace:20];
        [self sav_setHeight:60 forView:self.buttonContainer isRelative:NO];

        self.centerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.centerImageView.hidden = YES;
        self.centerImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.centerImageView];

        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.progressView.borderWidth = [UIScreen screenPixel];
        self.progressView.hidden = YES;
        [self addSubview:self.progressView];
        [self sav_pinView:self.progressView withOptions:SAVViewPinningOptionsCenterX];
        [self sav_pinView:self.progressView withOptions:SAVViewPinningOptionsToBottom ofView:self.centerImageView withSpace:SAVViewAutoLayoutStandardSpace];
        [self sav_setWidth:.5 forView:self.progressView isRelative:YES];

        self.progressLabel = [[UILabel alloc] init];
        self.progressLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.progressLabel];
        [self sav_pinView:self.progressLabel withOptions:SAVViewPinningOptionsHorizontally];
        [self sav_pinView:self.progressLabel withOptions:SAVViewPinningOptionsToBottom ofView:self.progressView withSpace:SAVViewAutoLayoutStandardSpace];

        NSDictionary *metrics = @{@"titleHeight": @50,
                                  @"buttonHeight": [UIDevice isPad] ? @50 : @44};

        NSDictionary *views = @{@"title": self.titleContainer,
                                @"image": self.centerImageView};

        [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:metrics
                                                                      views:views
                                                                    formats:@[@"|[title]|",
                                                                              @"V:|[title(titleHeight)]",
                                                                              @"image.centerY = super.centerY",
                                                                              @"image.centerX = super.centerX"]]];

        {
            self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
            [self.titleContainer addSubview:self.titleLabel];

            NSDictionary *metrics = @{@"padding": @4};

            NSDictionary *views = @{@"title": self.titleLabel};

            [self.titleContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:views
                                                                            formats:@[@"|[title]|",
                                                                                      @"V:[title]-padding-|"]]];
        }

        UIColor *backgroundTintColor = [UIColor sav_colorWithRGBValue:0x696057];
        self.backgroundView = [UIView sav_viewWithColor:backgroundTintColor];
        self.backgroundTintColor = backgroundTintColor;
        self.foregroundTintColor = [[SCUColors shared] color04];
        self.buttonColor = [UIColor clearColor];
        self.centerImage = [UIImage imageNamed:@"Launch"];
        self.progressTintColor = [[SCUColors shared] color04];
    }

    return self;
}

- (void)setBackgroundTintColor:(UIColor *)backgroundTintColor
{
    _backgroundTintColor = backgroundTintColor;
    self.titleContainer.backgroundColor = backgroundTintColor;
    self.buttonContainer.backgroundColor = backgroundTintColor;
}

- (void)setForegroundTintColor:(UIColor *)foregroundTintColor
{
    _foregroundTintColor = foregroundTintColor;
    self.titleLabel.textColor = foregroundTintColor;
    self.progressLabel.textColor = foregroundTintColor;

    for (UIButton *button in self.buttons)
    {
        button.tintColor = foregroundTintColor;
    }

    if (self.centerImageView.image)
    {
        self.centerImageView.image = [self.centerImageView.image tintedImageWithColor:foregroundTintColor];
    }
}

- (void)setButtonColor:(UIColor *)buttonColor
{
    _buttonColor = buttonColor;

    for (UIButton *button in self.buttons)
    {
        button.backgroundColor = buttonColor;
    }
}

- (void)setBackgroundView:(UIView *)backgroundView
{
    if (_backgroundView)
    {
        [_backgroundView removeFromSuperview];
    }

    _backgroundView = backgroundView;
    [self addSubview:backgroundView];
    [self sendSubviewToBack:backgroundView];
    [self sav_addFlushConstraintsForView:backgroundView];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleContainer.hidden = NO;
    self.titleLabel.text = title;
}

- (void)setButtonTitles:(NSArray *)buttonTitles
{
    self.buttons = nil;

    if (self.buttonView)
    {
        [self.buttonView removeFromSuperview];
    }

    _buttonTitles = buttonTitles;

    if (_buttonTitles)
    {
        self.buttonContainer.hidden = NO;

        __block NSUInteger index = 0;

        self.buttons = [buttonTitles arrayByMappingBlock:^id(NSString *title) {

            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.tag = index;
            button.layer.cornerRadius = 5;
            [button setTitle:title forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
            [button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
            button.tintColor = self.foregroundTintColor;
            index++;
            return button;

        }];

        SAVViewDistributionConfiguration *configration = [[SAVViewDistributionConfiguration alloc] init];
        configration.distributeEvenly = YES;
        configration.minimumWidth = 0;
        configration.interSpace = 5;

        self.buttonView = [UIView sav_viewWithEvenlyDistributedViews:self.buttons withConfiguration:configration];

        [self.buttonContainer addSubview:self.buttonView];
        [self.buttonContainer sav_addFlushConstraintsForView:self.buttonView withPadding:[UIDevice isPad] ? 7 : 4];
    }
    else
    {
        self.buttonContainer.hidden = YES;
    }
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
    _progressTintColor = progressTintColor;
    self.progressView.tintColor = progressTintColor;
    self.progressView.borderColor = progressTintColor;
}

- (void)setProgressViewLabel:(NSString *)progressViewLabel
{
    _progressViewLabel = progressViewLabel;
    self.progressLabel.text = progressViewLabel;
}

- (void)setCenterImage:(UIImage *)centerImage
{
    _centerImage = centerImage;
    self.centerImageView.image = [centerImage tintedImageWithColor:self.foregroundTintColor];

    if (centerImage)
    {
        self.centerImageView.hidden = NO;
    }
    else
    {
        self.centerImageView.hidden = YES;
    }
}

- (void)setAnimationEnabled:(BOOL)enabled
{
    [self.animationTimer invalidate];
    [self cleanupAnimationLayer];

    if (enabled)
    {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:4
                                                               target:self
                                                             selector:@selector(animate:)
                                                             userInfo:nil
                                                              repeats:YES];

        //-------------------------------------------------------------------
        // Kick the timer a little earlier the first time.
        //-------------------------------------------------------------------
        self.animationTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    }
}

#pragma mark -

- (void)didTapButton:(UIButton *)button
{
    if (self.callback)
    {
        self.callback((NSUInteger)button.tag);
    }
}

- (void)animate:(NSTimer *)timer
{
    CALayer *layer = [CALayer layer];
    layer.position = self.centerImageView.center;
    layer.bounds = CGRectMake(0, 0, 90, 90);
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.cornerRadius = 45;
    layer.borderWidth = [UIScreen screenPixel];
    layer.borderColor = [self.foregroundTintColor colorWithAlphaComponent:0.2].CGColor;

    CAReplicatorLayer *xLayer = [CAReplicatorLayer layer];
    xLayer.instanceCount = 3;
    xLayer.instanceDelay = [UIDevice isPad] ? .2 : .15;
    [xLayer addSublayer:layer];
    self.animationLayer = xLayer;
    [self.backgroundView.layer addSublayer:xLayer];

    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.delegate = self;
    scale.fromValue = @1;
    scale.toValue = [UIDevice isPad] ? @20 : @10;
    scale.duration = [UIDevice isPad] ? 3 : 2;
    scale.fillMode = kCAFillModeForwards;
    scale.removedOnCompletion = NO;
    [layer addAnimation:scale forKey:@"scale"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self cleanupAnimationLayer];
}

- (void)cleanupAnimationLayer
{
    [self.animationLayer removeAllAnimations];
    [self.animationLayer removeFromSuperlayer];
    self.animationLayer = nil;
}

@end
