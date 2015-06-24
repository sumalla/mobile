//
//  SCUHomePageCell.m
//  SavantController
//
//  Created by Nathan Trapp on 4/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHomePageCell.h"
#import "SCUHomeCellPrivate.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUHomePageCell ()

@property (nonatomic) SAVViewPositioningConfiguration *indicatorConfiguration;

@end

@implementation SCUHomePageCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        if ([UIDevice isPad])
        {
            self.gradient.locations = @[@(.5), @(1)];
            self.gradient.colors = @[[UIColor clearColor], [[[SCUColors shared] color03] colorWithAlphaComponent:.8]];
        }
        else
        {
            self.gradient.colors = @[[[[SCUColors shared] color03] colorWithAlphaComponent:.6], [[[SCUColors shared] color03] colorWithAlphaComponent:.2], [[[SCUColors shared] color03] colorWithAlphaComponent:.8]];
        }

        self.textLabel.textColor = [[SCUColors shared] color04];
        self.textLabel.minimumScaleFactor = 0.75;

        self.temperatureButton.color = [[SCUColors shared] color04];

        self.lightsButton.image = [UIImage sav_imageNamed:@"Lighting" tintColor:[[SCUColors shared] color04]];
        self.fanButton.image = [UIImage sav_imageNamed:@"Fan" tintColor:[[SCUColors shared] color04]];
        self.securityButton.image = [UIImage sav_imageNamed:@"SecurityUnlocked" tintColor:[[SCUColors shared] color04]];

        if ([UIDevice isPhone])
        {
            self.textLabel.font = [UIFont fontWithName:@"Gotham-ExtraLight" size:50];
            self.textLabel.textAlignment = NSTextAlignmentCenter;
            self.temperatureButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:30];
        }
        else
        {
            self.textLabel.font = [UIFont fontWithName:@"Gotham-ExtraLight" size:84];
            self.temperatureButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:45];
            
            SAVViewPositioningConfiguration *indicatorConfiguration = [[SAVViewPositioningConfiguration alloc] init];
            indicatorConfiguration.position = CGRectMake(50, -75, 71, 80);
            indicatorConfiguration.interSpace = 10;
            self.indicatorConfiguration = indicatorConfiguration;
        }

        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = .75;

        self.temperatureButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.temperatureButton.titleLabel.minimumScaleFactor = .75;
        self.temperatureButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    }

    return self;
}

- (CGFloat)shadowRadius
{
    return [UIDevice isPad] ? 2 : 1;
}

- (NSInteger)indicatorSpacing
{
    return [UIDevice isPhone] ? 20 : 40;
}

- (void)updateActiveService
{
    [super updateActiveService];

    if (self.activeService)
    {
        self.serviceButton.image = [UIImage sav_imageNamed:[self.activeService iconName] tintColor:[[SCUColors shared] color04]];
    }
}

- (void)distributeIndicators
{
    if ([UIDevice isPhone])
    {
        CGRect textLabelFrame = CGRectMake(10, 52, CGRectGetWidth(self.bounds) - 20, 60);
        self.textLabel.frame = textLabelFrame;

        NSArray *indicators = [self.indicators filteredArrayUsingBlock:^BOOL(UIView *view) {
            return !view.isHidden;
        }];

        CGFloat indicatorWidth = 55;

        CGFloat spacing = [self indicatorSpacing] * ([indicators count] - 1);
        CGFloat width = [indicators count] * indicatorWidth;
        CGFloat totalWidth = spacing + width;

        CGRect frame = CGRectMake(CGRectGetMidX(self.bounds) - (totalWidth / 2),
                                  CGRectGetHeight(self.bounds) - 100,
                                  indicatorWidth,
                                  48);

        for (UIView *view in indicators)
        {
            indicatorWidth = view.intrinsicContentSize.width;
            CGRect newFrame = frame;
            newFrame.size.width = indicatorWidth;
            view.frame = newFrame;
            frame.origin.x += (indicatorWidth + [self indicatorSpacing]);
        }
    }
    else
    {
        SAVViewPositioningConfiguration *textLabelConfiguration = [[SAVViewPositioningConfiguration alloc] init];
        //-------------------------------------------------------------------
        // CBP TODO: Add support for negative width (calculate width on width - x - space).
        //-------------------------------------------------------------------
        CGRect textPosition = CGRectMake(50, 0, CGRectGetWidth(self.bounds) - 50, 100);
        
        self.indicatorConfiguration.relativeViewPosition = 0;
        self.indicatorConfiguration.relativeView = nil;
        
        for (UIView *view in self.indicators)
        {
            if (!view.isHidden)
            {
                CGRect position = self.indicatorConfiguration.position;
                position.size.width = view.intrinsicContentSize.width;

                if (position.size.width < 100)
                {
                    position.size.width = 100;
                }

                self.indicatorConfiguration.position = position;
                [view sav_setPositionWithConfiguration:self.indicatorConfiguration];
                textLabelConfiguration.relativeView = view;
                self.indicatorConfiguration.relativeView = view;
                self.indicatorConfiguration.relativeViewPosition = SAVViewRelativePositionsX;
            }
        }
        
        if (textLabelConfiguration.relativeView)
        {
            textLabelConfiguration.relativeViewPosition = SAVViewRelativePositionsY;
            textLabelConfiguration.interSpace = -1;
        }
        else
        {
            textPosition.origin.y = -100;
        }
        
        textLabelConfiguration.position = textPosition;
        [self.textLabel sav_setPositionWithConfiguration:textLabelConfiguration];
    }
}

@end
