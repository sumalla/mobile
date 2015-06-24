//
//  SCUSecurityChartViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityChartViewControllerPhone.h"
#import "SCUSecurityChartViewControllerPrivate.h"

@interface SCUSecurityChartViewControllerPhone ()

@end

@implementation SCUSecurityChartViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *topHeaderHalf = [[UIView alloc] initWithFrame:CGRectZero];

    {
        [topHeaderHalf addSubview:self.systemSelector];
        [topHeaderHalf addSubview:self.roomsSelector];

        NSDictionary *views = @{@"systems": self.systemSelector,
                                @"rooms": self.roomsSelector};

        NSDictionary *metrics = @{@"spacer": @5,
                                  @"buttonHeight": @35};

        [topHeaderHalf addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:views
                                                                          formats:@[@"|-(spacer)-[systems]-(spacer)-[rooms(==systems)]-(spacer)-|",
                                                                                    @"V:|[rooms(buttonHeight)]",
                                                                                    @"V:|[systems(==rooms)]|"]]];

    }

    UIView *bottomHeaderHalf = [[UIView alloc] initWithFrame:CGRectZero];

    {
        UIView *bottomSegment = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *topSegment = [[UIView alloc] initWithFrame:CGRectZero];

        NSDictionary *metrics = @{@"spacer": @5,
                                  @"largeSpacer": @15,
                                  @"buttonHeight": @35,
                                  @"buttonWidth": @100,
                                  @"leftSpacer": @45};

        [bottomSegment addSubview:self.readyButton];
        [bottomSegment addSubview:self.troubleButton];

        {
            NSDictionary *views = @{@"ready": self.readyButton,
                                    @"trouble": self.troubleButton};



            [bottomSegment addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                   views:views
                                                                                 formats:@[@"|-(spacer)-[trouble(buttonWidth)]-(largeSpacer)-[ready]-(spacer)-|",
                                                                                           @"trouble.centerY = super.centerY",
                                                                                           @"ready.centerY = super.centerY"]]];
        }

        [topSegment addSubview:self.criticalButton];
        [topSegment addSubview:self.unknownButton];

        {
            NSDictionary *views = @{@"critical": self.criticalButton,
                                    @"unknown": self.unknownButton};



            [topSegment addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                                views:views
                                                                              formats:@[@"|-(spacer)-[unknown(buttonWidth)]-(largeSpacer)-[critical]-(spacer)-|",
                                                                                        @"unknown.centerY = super.centerY",
                                                                                        @"critical.centerY = super.centerY"]]];
        }

        [bottomHeaderHalf addSubview:bottomSegment];
        [bottomHeaderHalf addSubview:topSegment];
        [bottomHeaderHalf addSubview:self.allButton];

        NSDictionary *views = @{@"all": self.allButton,
                                @"bottom": bottomSegment,
                                @"top": topSegment};

        [bottomHeaderHalf addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:views
                                                                          formats:@[@"|-(leftSpacer)-[all]-(largeSpacer)-[top]-(spacer)-|",
                                                                                    @"|-(leftSpacer)-[all]-(largeSpacer)-[bottom]-(spacer)-|",
                                                                                    @"all.centerY = super.centerY",
                                                                                    @"V:|[top(25)][bottom(25)]|"]]];
        
    }

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.2];

    [self.contentView addSubview:topHeaderHalf];
    [self.contentView addSubview:bottomHeaderHalf];
    [self.contentView addSubview:self.sensorTableViewController.view];
    [self.contentView addSubview:separator];

    NSDictionary *views = @{@"topHeader": topHeaderHalf,
                            @"bottomHeader": bottomHeaderHalf,
                            @"tableView": self.sensorTableViewController.view,
                            @"separator": separator};

    NSDictionary *metrics = @{@"spacer": @5,
                              @"midSpacing": @10,
                              @"separatorHeight": @2,
                              @"sidePadding": @122};

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                              views:views
                                                                            formats:@[@"|[topHeader]|",
                                                                                      @"|[bottomHeader]|",
                                                                                      @"|[tableView]|",
                                                                                      @"|[separator]|",
                                                                                      @"V:|-(spacer)-[topHeader]-(spacer)-[bottomHeader]-(spacer)-[separator(separatorHeight)][tableView]|"]]];
}

@end
