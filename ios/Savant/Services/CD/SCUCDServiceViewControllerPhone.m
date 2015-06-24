//
//  SCUCDServiceViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCDServiceViewControllerPhone.h"
#import "SCUCDServiceViewControllerPrivate.h"

@implementation SCUCDServiceViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.progressLabel];
    [self.contentView addSubview:self.buttonPanel.view];

    UIView *trackdiskContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [trackdiskContainer addSubview:self.diskLabel];
    [trackdiskContainer addSubview:self.diskPicker];
    [trackdiskContainer addSubview:self.trackLabel];
    [trackdiskContainer addSubview:self.trackPicker];

    [self.contentView addSubview:trackdiskContainer];

    NSDictionary *views = @{@"progress": self.progressLabel,
                            @"trackdiskContainer": trackdiskContainer,
                            @"numberPad": self.numberPad.view,
                            @"buttons": self.buttonPanel.view};

    NSDictionary *metrics = @{@"largeSpacerMax": @18,
                              @"largeSpacerMin": @4,
                              @"spacer": @4,
                              @"trackDiskHeight": @78,
                              @"pickerSpacing": @38,
                              @"numberHeightMax": @318,
                              @"numberHeightMin": @180,
                              @"buttonsHeightMax": @127,
                              @"buttonsHeightMin": @75,
                              @"progressHeight": @32};

    [trackdiskContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                              metrics:metrics
                                                                                views:@{@"disk": self.diskLabel,
                                                                                        @"track": self.trackLabel,
                                                                                        @"diskPicker": self.diskPicker,
                                                                                        @"trackPicker": self.trackPicker}
                                                                              formats:@[@"|[disk]-[diskPicker]-(pickerSpacing)-[track]-[trackPicker]|",
                                                                                        @"V:|[disk]|",
                                                                                        @"V:|[diskPicker]|",
                                                                                        @"V:|[track]|",
                                                                                        @"V:|[trackPicker]|"]]];

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:views
                                                                            formats:@[@"|-[progress]",
                                                                                      @"|[buttons]|",
                                                                                      @"|[numberPad]|",
                                                                                      @"|-[trackdiskContainer]-|",
                                                                                      @"V:|-(<=largeSpacerMax,>=largeSpacerMin,==largeSpacerMax@100)-[progress(progressHeight)]-(<=largeSpacerMax,>=largeSpacerMin,==largeSpacerMax@100)-[trackdiskContainer(trackDiskHeight)]-(<=largeSpacerMax,>=largeSpacerMin,==largeSpacerMax@100)-[buttons(<=buttonsHeightMax,>=buttonsHeightMin,==buttonsHeightMax@500)]-(spacer)-[numberPad(<=numberHeightMax,>=numberHeightMin,==numberHeightMax@300)]|"]]];
}

@end
