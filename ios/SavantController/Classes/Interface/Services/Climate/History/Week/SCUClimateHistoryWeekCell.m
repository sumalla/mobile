//
//  SCUClimateHistoryWeekCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryWeekCell.h"
#import <SavantExtensions/SavantExtensions.h>


NSString *const SCUClimateHistoryWeekCellKeyCoolHours = @"SCUClimateHistoryWeekCellKeyCoolHours";
NSString *const SCUClimateHistoryWeekCellKeyHeatHours = @"SCUClimateHistoryWeekCellKeyHeatHours";
NSString *const SCUClimateHistoryWeekCellKeyDate      = @"SCUClimateHistoryWeekCellKeyDate";
NSString *const SCUClimateHistoryWeekCellKeyServicesFirst = @"SCUClimateHistoryWeekCellKeyServicesFirst";


#define kDeviceFontSize ([UIDevice isPad] ? 15 : 12)

@interface SCUClimateHistoryWeekCell ()

@property NSMutableArray *bars;
@property UILabel *dayDateLabel;
@property UILabel *todayLabel;
@property (getter = isServicesFirst) BOOL servicesFirst;

@end

@implementation SCUClimateHistoryWeekCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.dayDateLabel = [[UILabel alloc] initWithFrame:CGRectZero];

        self.todayLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.todayLabel.font = [UIFont fontWithName:@"Gotham" size:kDeviceFontSize];
        self.todayLabel.textColor = [UIColor sav_colorWithRGBValue:0xffc220];
        self.todayLabel.text = NSLocalizedString(@"Today", nil);
        self.todayLabel.hidden = YES;
    }
    return self;
}

- (void)setupDateString:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"M/d";

    NSString *dateString = [df stringFromDate:date];

    df.dateFormat = @"E";

    NSString *dayString = [df stringFromDate:date];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", dayString, dateString]
                                                                             attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04],
                                                                                          NSFontAttributeName: [UIFont fontWithName:@"Gotham-Light" size:kDeviceFontSize]}];

    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor sav_colorWithRGBValue:0x7b7b7b]
                 range:NSMakeRange(0, [dayString length])];

    self.dayDateLabel.attributedText = text;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    NSDate *date = info[SCUClimateHistoryWeekCellKeyDate];
    NSInteger coolHours = [info[SCUClimateHistoryWeekCellKeyCoolHours] integerValue];
    NSInteger heatHours = [info[SCUClimateHistoryWeekCellKeyHeatHours] integerValue];
    self.servicesFirst = [info[SCUClimateHistoryWeekCellKeyServicesFirst] boolValue];

    [self setupDateString:date];

    [self.bars makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.bars = [NSMutableArray array];

    UIView *coolBar = [self setupBarViewWithHours:coolHours andColor:[UIColor sav_colorWithRGBValue:0x0290aa]];
    UIView *heatBar = [self setupBarViewWithHours:heatHours andColor:[UIColor sav_colorWithRGBValue:0xfc7321]];

    NSMutableDictionary *landscapeMetrics = [@{@"halfBar": @25,
                                               @"inset": @18,
                                               @"spacer": @5} mutableCopy];

    if (self.isServicesFirst)
    {
        landscapeMetrics[@"halfBar"] = @17;
    }

    NSMutableDictionary *portraitMetrics = nil;
    if ([UIDevice isPad])
    {
        portraitMetrics = [@{@"halfBar": @19,
                            @"spacer": @5,
                            @"inset": @150,
                            @"dayDateWidth": @125} mutableCopy];
    }
    else
    {
        portraitMetrics = [@{@"halfBar": @10,
                            @"spacer": @0,
                            @"inset": @70,
                            @"dayDateWidth": @64} mutableCopy];
    }

    //-------------------------------------------------------------------
    // center the single bar if only one exists
    //-------------------------------------------------------------------
    if (!coolBar || !heatBar)
    {
        landscapeMetrics[@"halfBar"] = @0;
        portraitMetrics[@"halfBar"] = @0;
    }


    if (coolBar)
    {
        [self.bars addObject:coolBar];
        [self.contentView addSubview:coolBar];

        if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:landscapeMetrics
                                                                                      views:@{@"bar": coolBar}
                                                                                    formats:@[@"bar.centerX = super.centerX + halfBar",
                                                                                              @"V:[bar]|"]]];
        }
        else
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:portraitMetrics
                                                                                      views:@{@"bar": coolBar}
                                                                                    formats:@[@"bar.centerY = super.centerY - halfBar",
                                                                                              @"|-(inset)-[bar]"]]];
        }
    }

    if (heatBar)
    {
        [self.bars addObject:heatBar];
        [self.contentView addSubview:heatBar];

        if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:landscapeMetrics
                                                                                      views:@{@"bar": heatBar}
                                                                                    formats:@[@"bar.centerX = super.centerX - halfBar",
                                                                                              @"V:[bar]|"]]];
        }
        else
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:portraitMetrics
                                                                                      views:@{@"bar": heatBar}
                                                                                    formats:@[@"bar.centerY = super.centerY + halfBar",
                                                                                              @"|-(inset)-[bar]"]]];
        }
    }

    if ([date isToday])
    {
        self.backgroundColor = [UIColor sav_colorWithRGBValue:0x1e1e1e];
        self.todayLabel.hidden = NO;
    }
    else
    {
        self.backgroundColor = [UIColor sav_colorWithRGBValue:0x1e1e1e alpha:.49];
        self.todayLabel.hidden = YES;
    }

    NSDictionary *views = @{@"today": self.todayLabel,
                            @"dayDate": self.dayDateLabel};

    [self.todayLabel removeFromSuperview];
    [self.dayDateLabel removeFromSuperview];

    [self.contentView addSubview:self.todayLabel];
    [self.contentView addSubview:self.dayDateLabel];

    if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
    {

        self.todayLabel.textAlignment = NSTextAlignmentCenter;
        self.dayDateLabel.textAlignment = NSTextAlignmentCenter;

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:landscapeMetrics
                                                                                  views:views
                                                                                formats:@[@"V:|-(inset)-[dayDate]-(spacer)-[today]",
                                                                                          @"|[today]|",
                                                                                          @"|[dayDate]|"]]];
    }
    else
    {
        self.todayLabel.textAlignment = NSTextAlignmentRight;
        self.dayDateLabel.textAlignment = NSTextAlignmentRight;

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:portraitMetrics
                                                                                  views:views
                                                                                formats:@[@"V:[dayDate]-(spacer)-[today]",
                                                                                          @"dayDate.centerY = super.centerY",
                                                                                          @"|[dayDate(dayDateWidth)]",
                                                                                          @"|[today(dayDate)]"]]];
    }
}

- (UIView *)setupBarViewWithHours:(NSInteger)hours andColor:(UIColor *)color
{
    UIView *barView = nil;

    if (hours > 0)
    {
        barView = [[UIView alloc] initWithFrame:CGRectZero];

        CGFloat ratio = hours / 24.0;

        UIView *bar = [[UIView alloc] initWithFrame:CGRectZero];
        bar.backgroundColor = color;
        [barView addSubview:bar];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont fontWithName:@"Gotham" size:kDeviceFontSize];
        label.textColor = color;
        label.text = [NSString stringWithFormat:@"%ld%@", (long)hours, NSLocalizedString(@"hr", nil)];
        label.textAlignment = NSTextAlignmentCenter;
        [barView addSubview:label];

        NSDictionary *metrics = nil;
        if ([UIDevice isPad])
        {
            metrics =   @{@"barHeight": @((self.isServicesFirst ? 190 : 360) * ratio),
                          @"landscapeBar": self.isServicesFirst ? @34 : @50,
                          @"portraitBar": @38,
                          @"spacer": @17};
        }
        else
        {
            metrics =   @{@"barHeight": @(210 * ratio),
                          @"landscapeBar": @50,
                          @"portraitBar": @20,
                          @"spacer": @5};
        }

        NSDictionary *views = @{@"label": label,
                                @"bar": bar};

        if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
        {
            [barView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"|[bar(landscapeBar)]|",
                                                                                     @"|[label(landscapeBar)]|",
                                                                                     @"bar.bottom = super.bottom",
                                                                                     @"label.bottom = bar.top - spacer"]]];
        }
        else
        {
            [barView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"V:|[bar(portraitBar)]|",
                                                                                     @"V:|[label(portraitBar)]|",
                                                                                     @"bar.left = super.left",
                                                                                     @"label.left = bar.right + spacer"]]];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self layoutIfNeeded];
            [UIView animateWithDuration:[UIDevice rotationSpeed] animations:^{
                if (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]))
                {
                    [barView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                     views:views
                                                                                   formats:@[@"bar.height = barHeight"]]];
                }
                else
                {
                    [barView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                     views:views
                                                                                   formats:@[@"bar.width = barHeight"]]];
                }
                [self layoutIfNeeded];
            }];
        });

    }

    return barView;
}

@end
