//
//  SCUClimateHistoryDayViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 7/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryDayViewController.h"
#import "SCUOnOffGraph.h"
#import "SCUPointGraph.h"
#import "SCUClimateHistoryModel.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUClimateHistoryDayViewController ()

@property (weak) SCUClimateHistoryModel *dataSource;
@property NSArray *charts;
@property UIView *cAxis;
@property UIView *fAxis;

@end

@implementation SCUClimateHistoryDayViewController

- (instancetype)initWithDataSource:(SCUClimateHistoryModel *)dataSource
{
    self = [super init];
    if (self)
    {
        self.dataSource = dataSource;
    }
    return self;
}

- (void)reloadData
{
    [self updateScale];

    for (SCUGraph *graph in self.charts)
    {
        [graph reloadData:YES];
    }
}

- (void)updateScale
{
    NSInteger minValue = 45;
    NSInteger maxValue = 90;

    if (self.dataSource.isCelsius)
    {
        minValue = 5;
        maxValue = 35;

        self.cAxis.hidden = NO;
        self.fAxis.hidden = YES;
    }
    else
    {
        self.cAxis.hidden = YES;
        self.fAxis.hidden = NO;
    }

    for (NSInteger i = 0; i < 4; i++)
    {
        if (i != SCUClimateHistoryDayPlotType_Humidity)
        {
            SCUGraph *graph = self.charts[i];
            graph.minimumValue = minValue;
            graph.maximumValue = maxValue;
        }
    }
}

- (void)toggleChart:(NSInteger)type
{
    SCUGraph *chart = self.charts[type];

    chart.hidden = !chart.hidden;

    if (!chart.hidden)
    {
        [chart reloadData:YES];
    }

    [[SAVSettings localSettings] setObject:@(chart.hidden) forKey:[@"hvacHistoryChartVisibility." stringByAppendingFormat:@"%ld", (long)type]];
    [[SAVSettings localSettings] synchronize];
}

- (BOOL)chartIsVisible:(NSInteger)type
{
    UIView *chart = self.charts[type];

    return !chart.hidden;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray *lineChartViews = [NSMutableArray array];

    UIView *lineChartContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:lineChartContainer];

    NSInteger minValue = 45;
    NSInteger maxValue = 90;

    if (self.dataSource.isCelsius)
    {
        minValue = 5;
        maxValue = 35;
    }

    //-------------------------------------------------------------------
    // Setup a plot for each line chart
    //-------------------------------------------------------------------
    for (NSInteger i = 0; i < 2; i++)
    {
        SCUGraph *graph = [[SCUGraph alloc] init];
        graph.dataSource = self.dataSource;
        graph.identifer = i;
        graph.smoothing = YES;
        graph.lineWidth = 8;

        graph.minimumValue = minValue;
        graph.maximumValue = maxValue;

        SCUClimateHistoryDayPlotType type = (SCUClimateHistoryDayPlotType)i;

        NSNumber *visibility = [[SAVSettings localSettings] objectForKey:[@"hvacHistoryChartVisibility." stringByAppendingFormat:@"%ld", (long)type]];

        switch (type)
        {
            case SCUClimateHistoryDayPlotType_IndoorTemp:
                graph.lineColor = [UIColor sav_colorWithRGBValue:0xed145b];
                graph.lineWidth = 4;
                break;
            case SCUClimateHistoryDayPlotType_Humidity:
                graph.lineWidth = 2;
                graph.lineStyle = SCUGraphStyle_Dashed;
                graph.lineColor = [UIColor sav_colorWithRGBValue:0x00cc00];
                graph.minimumValue = 0;
                graph.maximumValue = 100;

                //-------------------------------------------------------------------
                // Default to off.
                //-------------------------------------------------------------------
                if (!visibility)
                {
                    graph.hidden = YES;
                }
                break;
            case SCUClimateHistoryDayPlotType_HeatPoint:
            case SCUClimateHistoryDayPlotType_CoolPoint:
            case SCUClimateHistoryDayPlotType_Heating:
            case SCUClimateHistoryDayPlotType_Cooling:
            case SCUClimateHistoryDayPlotType_FanOn:
                break;
        }

        if (visibility)
        {
            graph.hidden = [visibility boolValue];
        }

        [lineChartContainer addSubview:graph];
        [lineChartContainer sav_addFlushConstraintsForView:graph];

        [lineChartViews addObject:graph];
    }

    //-------------------------------------------------------------------
    // Setup a plot for each point chart
    //-------------------------------------------------------------------
    for (NSInteger i = 2; i < 4; i++)
    {
        SCUPointGraph *graph = [[SCUPointGraph alloc] init];
        graph.identifer = i;
        graph.dataSource = self.dataSource;
        graph.minimumValue = minValue;
        graph.maximumValue = maxValue;
        graph.pointRadius = [UIDevice isPad] ? 10 : 8;
        graph.pointSize = [UIDevice isPad] ? CGSizeMake(20, 20) : CGSizeMake(16, 16);
        graph.displayLabel = YES;
        graph.labelColor = [[SCUColors shared] color04];
        graph.labelFont = [UIFont fontWithName:@"Gotham" size:[UIDevice isPad] ? 12 : 10];

        SCUClimateHistoryDayPlotType type = (SCUClimateHistoryDayPlotType)i;

        NSNumber *visibility = [[SAVSettings localSettings] objectForKey:[@"hvacHistoryChartVisibility." stringByAppendingFormat:@"%ld", (long)type]];

        switch (type)
        {
            case SCUClimateHistoryDayPlotType_HeatPoint:
                graph.pointColor = [UIColor sav_colorWithRGBValue:0xe46a08];
                break;
            case SCUClimateHistoryDayPlotType_CoolPoint:
                graph.pointColor = [UIColor sav_colorWithRGBValue:0x00b4d5];
                break;
            case SCUClimateHistoryDayPlotType_IndoorTemp:
            case SCUClimateHistoryDayPlotType_Heating:
            case SCUClimateHistoryDayPlotType_Cooling:
            case SCUClimateHistoryDayPlotType_FanOn:
            case SCUClimateHistoryDayPlotType_Humidity:
                break;
        }

        if (visibility)
        {
            graph.hidden = [visibility boolValue];
        }

        [lineChartContainer addSubview:graph];
        [lineChartContainer sav_addFlushConstraintsForView:graph];
        
        [lineChartViews addObject:graph];
    }

    NSMutableArray *onOffViews = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Setup a plot for each on/off chart
    //-------------------------------------------------------------------
    for (NSInteger i = 4; i < 7; i++)
    {
        SCUOnOffGraph *graph = [[SCUOnOffGraph alloc] init];
        graph.dataSource = self.dataSource;
        graph.identifer = i;
        graph.lineWidth = 8;

        [onOffViews addObject:graph];

        SCUClimateHistoryDayPlotType type = (SCUClimateHistoryDayPlotType)i;

        NSNumber *visibility = [[SAVSettings localSettings] objectForKey:[@"hvacHistoryChartVisibility." stringByAppendingFormat:@"%ld", (long)type]];

        switch (type)
        {
            case SCUClimateHistoryDayPlotType_IndoorTemp:
            case SCUClimateHistoryDayPlotType_HeatPoint:
            case SCUClimateHistoryDayPlotType_CoolPoint:
            case SCUClimateHistoryDayPlotType_Humidity:
                break;
            case SCUClimateHistoryDayPlotType_Heating:
                graph.lineColor = [UIColor sav_colorWithRGBValue:0xe46a08];
                break;
            case SCUClimateHistoryDayPlotType_FanOn:
                graph.lineColor = [UIColor sav_colorWithRGBValue:0x999999];

                //-------------------------------------------------------------------
                // Default to off.
                //-------------------------------------------------------------------
                if (!visibility)
                {
                    graph.hidden = YES;
                }

                break;
            case SCUClimateHistoryDayPlotType_Cooling:
                graph.lineColor = [UIColor sav_colorWithRGBValue:0x00b4d5];
                break;
        }

        if (visibility)
        {
            graph.hidden = [visibility boolValue];
        }
    }

    SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
    config.interSpace = 4;
    config.fixedHeight = 10;
    config.vertical = YES;

    UIView *onOffChartView = [UIView sav_viewWithEvenlyDistributedViews:onOffViews withConfiguration:config];

    UIView *onOffChartContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [onOffChartContainer addSubview:onOffChartView];
    [onOffChartContainer sav_addConstraintsForView:onOffChartView withEdgeInsets:UIEdgeInsetsMake(8, 0, 0, 0)];
    onOffChartContainer.layer.borderColor = [[SCUColors shared] color03].CGColor;
    onOffChartContainer.layer.borderWidth = 1;
    [self.view addSubview:onOffChartContainer];

    self.charts = [lineChartViews arrayByAddingObjectsFromArray:onOffViews];

    //-------------------------------------------------------------------
    // Setup y1 label (temperature)
    //-------------------------------------------------------------------
    UIView *tempAxis = [[UIView alloc] init];

    self.fAxis = [self setupAxis:NSLocalizedString(@"Temperature", nil) minText:@"45\u00B0" maxText:@"90\u00B0"];
    self.cAxis = [self setupAxis:NSLocalizedString(@"Temperature", nil) minText:@"5\u00B0" maxText:@"35\u00B0"];

    [tempAxis addSubview:self.fAxis];
    [tempAxis sav_addFlushConstraintsForView:self.fAxis];
    [tempAxis addSubview:self.cAxis];
    [tempAxis sav_addFlushConstraintsForView:self.cAxis];

    if (self.dataSource.isCelsius)
    {
        self.fAxis.hidden = YES;
        self.cAxis.hidden = NO;
    }
    else
    {
        self.fAxis.hidden = NO;
        self.cAxis.hidden = YES;
    }

    [self.view addSubview:tempAxis];

    //-------------------------------------------------------------------
    // Setup y2 label (humditiy)
    //-------------------------------------------------------------------
    UIView *humidityAxis = [self setupAxis:NSLocalizedString(@"Humidity", nil) minText:NSLocalizedString(@"0%", nil) maxText:NSLocalizedString(@"100%", nil)];
    [self.view addSubview:humidityAxis];

    UIView *ticks = [self setupTickMarks];
    [self.view addSubview:ticks];
    [self.view sendSubviewToBack:ticks];

    //-------------------------------------------------------------------
    // Setup overall constraints
    //-------------------------------------------------------------------
    NSDictionary *views = @{@"lines": lineChartContainer,
                            @"onOff": onOffChartContainer,
                            @"tempAxis": tempAxis,
                            @"humidityAxis": humidityAxis,
                            @"ticks": ticks};

    NSDictionary *metrics = nil;

    if ([UIDevice isPad])
    {
        metrics = @{@"edgePadding": @9,
                    @"axisWidth": @18};
    }
    else
    {
        metrics = @{@"edgePadding": @2,
                    @"axisWidth": @18};
    }

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                       views:views
                                                                     formats:@[@"|[tempAxis(axisWidth)]-(edgePadding)-[lines]-(edgePadding)-[humidityAxis(axisWidth)]|",
                                                                               @"|[tempAxis(axisWidth)]-(edgePadding)-[ticks]-(edgePadding)-[humidityAxis(axisWidth)]|",
                                                                               @"|[tempAxis(axisWidth)]-(edgePadding)-[onOff]-(edgePadding)-[humidityAxis(axisWidth)]|",
                                                                               @"V:|[lines][onOff]|",
                                                                               @"V:|[ticks]|",
                                                                               @"V:|[tempAxis(lines)]",
                                                                               @"V:|[humidityAxis(lines)]"]]];
}

- (UIView *)setupAxis:(NSString *)title minText:(NSString *)min maxText:(NSString *)max
{
    UIView *axis = [[UIView alloc] initWithFrame:CGRectZero];

    UIView *minLabelContainer = [[UIView alloc] initWithFrame:CGRectZero];

    UILabel *minLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    minLabel.text = min;
    minLabel.font = [UIFont fontWithName:@"Gotham" size:12];
    minLabel.textColor = [[SCUColors shared] color04];
    [minLabelContainer addSubview:minLabel];
    [axis addSubview:minLabelContainer];

    minLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);

    [minLabelContainer sav_addCenteredConstraintsForView:minLabel];

    UIView *maxLabelContainer = [[UIView alloc] initWithFrame:CGRectZero];

    UILabel *maxLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    maxLabel.text = max;
    maxLabel.font = [UIFont fontWithName:@"Gotham" size:12];
    maxLabel.textColor = [[SCUColors shared] color04];
    [maxLabelContainer addSubview:maxLabel];
    [axis addSubview:maxLabelContainer];

    maxLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);

    [maxLabelContainer sav_addCenteredConstraintsForView:maxLabel];

    UIView *titleLabelContainer = [[UIView alloc] initWithFrame:CGRectZero];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = [title uppercaseString];
    titleLabel.font = [UIFont fontWithName:@"Gotham" size:12];
    titleLabel.textColor = [[SCUColors shared] color04];
    [titleLabelContainer addSubview:titleLabel];
    [axis addSubview:titleLabelContainer];

    titleLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);

    [titleLabelContainer sav_addCenteredConstraintsForView:titleLabel];

    [axis addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                         views:@{@"min": minLabelContainer,
                                                                                 @"max": maxLabelContainer,
                                                                                 @"label": titleLabelContainer}
                                                                       formats:@[@"V:[min]-(15)-|",
                                                                                 @"V:|-(15)-[max]",
                                                                                 @"label.centerY = super.centerY",
                                                                                 @"|[min]|",
                                                                                 @"|[max]|",
                                                                                 @"|[label]|"]]];

    return axis;
}

- (UIView *)setupTickMarks
{
    UIView *tickContainer = [[UIView alloc] initWithFrame:CGRectZero];

    UIColor *tickColor = [UIColor sav_colorWithRGBValue:0x1e1e1e alpha:.61];

    NSMutableArray *ticks = [NSMutableArray array];

    //-------------------------------------------------------------------
    // Setup hour ticks
    //-------------------------------------------------------------------
    for (NSInteger i = 0; i < 24; i++)
    {
        UIView *tick = [[UIView alloc] initWithFrame:CGRectZero];
        tick.backgroundColor = tickColor;

        if (!(i % 2))
        {
            UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            timeLabel.textAlignment = NSTextAlignmentCenter;
            timeLabel.font = [UIFont fontWithName:@"Gotham" size:10];
            timeLabel.textColor = [UIColor sav_colorWithRGBValue:0x7b7b7b];

            NSInteger hour = i;

            //-------------------------------------------------------------------
            // Convert from 24-hour time
            //-------------------------------------------------------------------
            if (i == 0)
            {
                hour = 12;
            }
            else if (i > 12)
            {
                hour = hour - 12;
            }

            if ([UIDevice isPad])
            {
                timeLabel.text = [NSString stringWithFormat:@"%ld:00", (long)hour];
            }
            else
            {
                timeLabel.text = [NSString stringWithFormat:@"%ld", (long)hour];;
            }

            [tick addSubview:timeLabel];

            [tick sav_pinView:timeLabel withOptions:SAVViewPinningOptionsToTop | SAVViewPinningOptionsToLeft];

            if (i == 12)
            {
                timeLabel.numberOfLines = 2;
                timeLabel.text = [timeLabel.text stringByAppendingString:@"\nPM"];
            }
            else if (i == 0)
            {
                timeLabel.numberOfLines = 2;
                timeLabel.text = [timeLabel.text stringByAppendingString:@"\nAM"];
            }
        }

        [ticks addObject:tick];
    }

    SAVViewDistributionConfiguration *hourConfig = [[SAVViewDistributionConfiguration alloc] init];
    hourConfig.distributeEvenly = YES;
    hourConfig.interSpace = 2;
    hourConfig.minimumWidth = 0;

    UIView *hourTicks = [[UIView alloc] initWithFrame:CGRectZero];

    for (UIView *view in [ticks reverseObjectEnumerator])
    {
        [hourTicks addSubview:view];
    }

    [hourTicks sav_distributeViewsEvenly:ticks withConfiguration:hourConfig];

    [tickContainer addSubview:hourTicks];
    [tickContainer sav_addFlushConstraintsForView:hourTicks];

    //-------------------------------------------------------------------
    // Setup edge ticks
    //-------------------------------------------------------------------
    for (NSInteger i = 0; i < 3; i++)
    {
        UIView *tick = [[UIView alloc] initWithFrame:CGRectZero];
        tick.backgroundColor = [[SCUColors shared] color03];

        [tickContainer addSubview:tick];
        [tickContainer sav_setWidth:1 forView:tick isRelative:NO];
        [tickContainer sav_pinView:tick withOptions:SAVViewPinningOptionsVertically];

        switch (i)
        {
            case 0:
                [tickContainer sav_pinView:tick withOptions:SAVViewPinningOptionsToLeft];
                break;
            case 1:
                [tickContainer sav_addCenteredConstraintsForView:tick];
                break;
            case 2:
                [tickContainer sav_pinView:tick withOptions:SAVViewPinningOptionsToRight];
                break;
        }
    }

    return tickContainer;
}

@end
