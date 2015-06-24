//
//  SCUSatelliteRadioNavigationViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioNavigationViewControllerPad.h"
#import "SCUSatelliteRadioNavigationViewControllerPrivate.h"

@implementation SCUSatelliteRadioNavigationViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *topBar = [[UIView alloc] initWithFrame:CGRectZero];
    topBar.backgroundColor = [[SCUColors shared] color03shade01];
    [topBar addSubview:self.channelPicker];
    [topBar addSubview:self.categoryPicker];

    if ([self.model.serviceCommands containsObject:@"ScanTP"])
    {
        [topBar addSubview:self.scanButton];

        [topBar addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:nil
                                                                        views:@{@"channelPicker": self.channelPicker,
                                                                                @"categoryPicker": self.categoryPicker,
                                                                                @"scan": self.scanButton}
                                                                      formats:@[@"V:|[channelPicker]|",
                                                                                @"V:|[categoryPicker]|",
                                                                                @"V:|-(3)-[scan(50)]-(3)-|",
                                                                                @"[channelPicker]-[categoryPicker]-[scan(50)]-(3)-|"]]];
    }
    else
    {
        [topBar addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:nil
                                                                        views:@{@"channelPicker": self.channelPicker,
                                                                                @"categoryPicker": self.categoryPicker}
                                                                      formats:@[@"V:|[channelPicker]|",
                                                                                @"V:|[categoryPicker]|",
                                                                                @"[channelPicker]-[categoryPicker]-|"]]];
    }



    [self.contentView addSubview:topBar];
    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.channelLabel];
    [self.contentView addSubview:self.categoryLabel];
    [self.contentView addSubview:self.albumLabel];
    [self.contentView addSubview:self.artistLabel];
    [self.contentView addSubview:self.songLabel];

    NSDictionary *views = @{@"topBar": topBar,
                            @"numberPad": self.numberPad.view,
                            @"channelLabel": self.channelLabel,
                            @"categoryLabel": self.categoryLabel,
                            @"albumLabel": self.albumLabel,
                            @"artistLabel": self.artistLabel,
                            @"songLabel": self.songLabel};

    NSDictionary *metrics = @{@"spacer": @4,
                              @"barHeight": @56,
                              @"labelSpacer": @200,
                              @"landscapeNumPadWidth": @234,
                              @"portraitNumPadHeight": @255};

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:views
                                                                            formats:@[@"V:|[topBar(barHeight)]-(<=25@1000,>=5@1000,==10@500)-[songLabel]-(spacer)-[artistLabel]-(spacer)-[albumLabel]-(spacer)-[channelLabel]-(spacer)-[categoryLabel]"]]];

    self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                       metrics:metrics
                                                                         views:views
                                                                       formats:@[@"|[channelLabel]-(labelSpacer)-[numberPad]|",
                                                                                 @"|[categoryLabel]-(labelSpacer)-[numberPad]|",
                                                                                 @"|[albumLabel]-(labelSpacer)-[numberPad]|",
                                                                                 @"|[artistLabel]-(labelSpacer)-[numberPad]|",
                                                                                 @"|[songLabel]-(labelSpacer)-[numberPad]|",
                                                                                 @"|[topBar]-(spacer)-[numberPad(landscapeNumPadWidth)]|",
                                                                                 @"V:|[numberPad]|"]];

    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:metrics
                                                                        views:views
                                                                      formats:@[@"|[channelLabel]-(labelSpacer)-|",
                                                                                @"|[categoryLabel]-(labelSpacer)-|",
                                                                                @"|[albumLabel]-(labelSpacer)-|",
                                                                                @"|[artistLabel]-(labelSpacer)-|",
                                                                                @"|[songLabel]-(labelSpacer)-|",
                                                                                @"|[topBar]|",
                                                                                @"|[numberPad]|",
                                                                                @"V:[numberPad(portraitNumPadHeight)]|"]];

    [self setupConstraintsForOrientation:[UIDevice interfaceOrientation]];
}

@end
