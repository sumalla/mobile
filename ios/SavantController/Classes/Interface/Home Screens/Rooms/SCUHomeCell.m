//
//  SCUHomeCell.m
//  SavantController
//
//  Created by Nathan Trapp on 6/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomeCellPrivate.h"
#import "SCUButtonContentView.h"
#import "SCUGradientView.h"
#import "SCUInterface.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUHomeCell () <UIGestureRecognizerDelegate>

@property (nonatomic) SAVKVORegistration *imageViewRegistration;
@property (nonatomic) SAVViewPositioningConfiguration *indicatorConfiguration;
@property (nonatomic) UIView *backgroundView;

@end

@implementation SCUHomeCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundView = [[UIView alloc] init];
        [self.contentView addSubview:self.backgroundView];
        [self.contentView sendSubviewToBack:self.backgroundView];

        self.backgroundImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
        self.backgroundImage.clipsToBounds = NO;
        [self.backgroundView addSubview:self.backgroundImage];
        [self.backgroundView sav_addFlushConstraintsForView:self.backgroundImage];

        self.gradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03] colorWithAlphaComponent:.6], [[[SCUColors shared] color03] colorWithAlphaComponent:.2], [[[SCUColors shared] color03] colorWithAlphaComponent:.8]]];
        self.gradient.locations = @[@(0), @(.65), @(1)];

        [self.backgroundView addSubview:self.gradient];
        [self.backgroundView sav_addFlushConstraintsForView:self.gradient];

        SAVWeakSelf;
        self.imageViewRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:self.backgroundImage selector:@selector(image) handler:^(NSDictionary *changeDictionary) {

            SAVStrongWeakSelf;

            if (sSelf.isDisplayingDefaultImage || !sSelf.backgroundImage.image)
            {
                sSelf.gradient.hidden = YES;
            }
            else
            {
                sSelf.gradient.hidden = NO;
            }
        }];

        self.serviceButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle2];
        self.serviceButton.hidden = YES;

        self.lightsButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle2 image:[UIImage sav_imageNamed:@"Lighting" tintColor:[[SCUColors shared] color04]]];
        self.lightsButton.tintImage = NO;
        self.lightsButton.hidden = YES;
        
        self.fanButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle2 image:[UIImage sav_imageNamed:@"Fan" tintColor:[[SCUColors shared] color04]]];
        self.fanButton.tintImage = NO;
        self.fanButton.hidden = YES;

        self.securityButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle2 image:[UIImage sav_imageNamed:@"SecurityUnlocked" tintColor:[[SCUColors shared] color04]]];
        self.securityButton.tintImage = NO;
        self.securityButton.hidden = YES;
        self.securityButton.selectedColor = [[SCUColors shared] color01];

        self.temperatureButton = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle2 title:@""];
        self.temperatureButton.hidden = YES;

        self.indicators = @[self.temperatureButton, self.serviceButton, self.lightsButton, self.fanButton, self.securityButton];

        for (UIView *view in self.indicators)
        {
            [self.contentView addSubview:view];
        }

        self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
        self.longPressGestureRecognizer.cancelsTouchesInView = NO;
        self.longPressGestureRecognizer.delegate = self;
        [self.contentView addGestureRecognizer:self.longPressGestureRecognizer];

        SAVViewPositioningConfiguration *indicatorConfiguration = [[SAVViewPositioningConfiguration alloc] init];

        CGFloat bottomOffest = -24;

        if ([UIDevice isPhone])
        {
            bottomOffest = -18;
        }

        indicatorConfiguration.position = CGRectMake(25, bottomOffest, 40, 35);
        indicatorConfiguration.interSpace = 2;
        self.indicatorConfiguration = indicatorConfiguration;
        self.clipsToBounds = YES;
    }
    return self;
}

- (CGFloat)shadowRadius
{
    return 0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self distributeIndicators];

    self.backgroundView.frame = self.bounds;
}

- (void)distributeIndicators
{
    SAVViewPositioningConfiguration *textLabelConfiguration = [[SAVViewPositioningConfiguration alloc] init];
    //-------------------------------------------------------------------
    // CBP TODO: Add support for negative width (calculate width on width - x - space).
    //-------------------------------------------------------------------
    CGRect textPosition = CGRectMake(25, 0, CGRectGetWidth(self.bounds) - 25, 35);

    self.indicatorConfiguration.relativeViewPosition = 0;
    self.indicatorConfiguration.relativeView = nil;

    for (UIView *view in self.indicators)
    {
        if (!view.isHidden)
        {
            CGRect position = self.indicatorConfiguration.position;
            position.size.width = view.intrinsicContentSize.width;
            self.indicatorConfiguration.position = position;
            [view sav_setPositionWithConfiguration:self.indicatorConfiguration];
            textLabelConfiguration.relativeView = view;
            self.indicatorConfiguration.relativeView = view;
            self.indicatorConfiguration.relativeViewPosition = SAVViewRelativePositionsX;
        }
    }

    if (textLabelConfiguration.relativeView && ![UIDevice isPad])
    {
        textLabelConfiguration.relativeViewPosition = SAVViewRelativePositionsY;
        textLabelConfiguration.interSpace = -1;
    }
    else
    {
        textPosition.origin.y = [UIDevice isPad] ? -55 : -18;
    }

    textLabelConfiguration.position = textPosition;
    [self.textLabel sav_setPositionWithConfiguration:textLabelConfiguration];
}

- (NSInteger)indicatorSpacing
{
    return 15;
}

- (void)configureWithInfo:(id)info
{
    [super configureWithInfo:info];

    SAVRoom *room = info[SCUDefaultCollectionViewCellKeyModelObject];

    self.textLabel.text = room.roomId;

    [self updateActiveService];
    [self updateLightsAreOn];
    [self updateFansAreOn];
    [self updateCurrentTemperature];
    [self updateSecurityAlert];
}

- (void)updateActiveService
{
    if (self.activeService)
    {
        self.serviceButton.hidden = NO;
        self.serviceButton.image = [UIImage sav_imageNamed:[self.activeService iconName] tintColor:[[SCUColors shared] color04]];
    }
    else
    {
        self.serviceButton.image = nil;
        self.serviceButton.hidden = YES;
    }
}

- (void)updateLightsAreOn
{
    if (self.lightsAreOn)
    {
        self.lightsButton.hidden = NO;
    }
    else
    {
        self.lightsButton.hidden = YES;
    }
}

- (void)updateFansAreOn
{
    if (self.fansAreOn)
    {
        self.fanButton.hidden = NO;
    }
    else
    {
        self.fanButton.hidden = YES;
    }
}

- (void)updateCurrentTemperature
{
    if (self.currentTemperature)
    {
        self.temperatureButton.hidden = NO;
        self.temperatureButton.title = self.currentTemperature;
        [self.temperatureButton sizeToFit];
        //-------------------------------------------------------------------
        // CBP TODO: Come back to this. This fixes truncation things for some reason.
        //-------------------------------------------------------------------
        self.temperatureButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    else
    {
        self.temperatureButton.hidden = YES;
    }
}

- (void)updateSecurityAlert
{
    if (self.hasSecurityAlert)
    {
        self.securityButton.hidden = NO;
    }
    else
    {
        self.securityButton.hidden = YES;
    }
}

- (void)setActiveService:(SAVService *)activeService
{
    _activeService = activeService;

    [self updateActiveService];
}

- (void)setLightsAreOn:(BOOL)lightsAreOn
{
    _lightsAreOn = lightsAreOn;

    [self updateLightsAreOn];
}

- (void)setFansAreOn:(BOOL)fansAreOn
{
    _fansAreOn = fansAreOn;
    [self updateFansAreOn];
}

- (void)setCurrentTemperature:(NSString *)currentTemperature
{
    _currentTemperature = currentTemperature;

    [self updateCurrentTemperature];
}

- (void)setHasSecurityAlert:(BOOL)hasSecurityAlert
{
    _hasSecurityAlert = hasSecurityAlert;

    [self updateSecurityAlert];
}

- (void)endUpdates
{
    [self setNeedsLayout];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldReceive = YES;

    if ([self.indicators containsObject:touch.view])
    {
        shouldReceive = NO;
    }
    
    return shouldReceive;
}

@end