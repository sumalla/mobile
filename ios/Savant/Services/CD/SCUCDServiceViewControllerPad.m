//
//  SCUCDServiceViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCDServiceViewControllerPad.h"
#import "SCUCDServiceViewControllerPrivate.h"

@implementation SCUCDServiceViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];


    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.progressLabel];
    [self.contentView addSubview:self.shuffleButton];
    [self.contentView addSubview:self.repeatButton];
    
    UIView *trackdiskContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [trackdiskContainer addSubview:self.diskLabel];
    [trackdiskContainer addSubview:self.diskPicker];
    [trackdiskContainer addSubview:self.trackLabel];
    [trackdiskContainer addSubview:self.trackPicker];

    [self.contentView addSubview:trackdiskContainer];

    UIView *buttonsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [buttonsContainer addSubview:self.openClose.view];
    [buttonsContainer addSubview:self.transportControls.view];

    [self.contentView addSubview:buttonsContainer];

    NSDictionary *views = @{@"progress": self.progressLabel,
                            @"trackdiskContainer": trackdiskContainer,
                            @"numberPad": self.numberPad.view,
                            @"repeat": self.repeatButton,
                            @"shuffle": self.shuffleButton,
                            @"buttons": buttonsContainer};

    NSDictionary *metrics = @{@"progressDistanceFromTop": @80,
                              @"progressDistanceFromLeft": @31,
                              @"trackDiskDistanceFromTop": @325,
                              @"trackDiskDistanceFromRight": @65,
                              @"trackDiskHeight": @85,
                              @"repeatDistanceFromTop": @16,
                              @"shuffleDistanceFromRepeat": @26,
                              @"toggleDistanceFromRight": @21,
                              @"landscapeNumPadWidth": @234,
                              @"portraitNumPadHeight": @255,
                              @"openCloseTransportsHeight": @75,
                              @"pickerSpacing": @38};

    [buttonsContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:@{@"transports": self.transportControls.view,
                                                                                      @"openClose": self.openClose.view}
                                                                            formats:@[@"|[openClose(234)]-[transports]|",
                                                                                      @"V:|[openClose(openCloseTransportsHeight)]|",
                                                                                      @"V:|[transports(openCloseTransportsHeight)]|"]]];

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
                                                                            formats:@[@"|-(progressDistanceFromLeft)-[progress]",
                                                                                      @"|[buttons]|",
                                                                                      @"V:|-(trackDiskDistanceFromTop)-[trackdiskContainer(trackDiskHeight)]",
                                                                                      @"V:|-(progressDistanceFromTop)-[progress]",
                                                                                      @"V:|-(repeatDistanceFromTop)-[repeat]-(shuffleDistanceFromRepeat)-[shuffle]"]]];

    self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                       metrics:metrics
                                                                         views:views
                                                                       formats:@[@"[trackdiskContainer]-(trackDiskDistanceFromRight)-[numberPad(landscapeNumPadWidth)]|",
                                                                                 @"[repeat]-(toggleDistanceFromRight)-[numberPad]|",
                                                                                 @"[shuffle]-(toggleDistanceFromRight)-[numberPad]|",
                                                                                 @"V:|[numberPad]-[buttons]|",
                                                                                 @"V:|[numberPad]-[buttons]|"]];

    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:metrics
                                                                        views:views
                                                                      formats:@[@"[trackdiskContainer]-(trackDiskDistanceFromRight)-|",
                                                                                @"[repeat]-(toggleDistanceFromRight)-|",
                                                                                @"[shuffle]-(toggleDistanceFromRight)-|",
                                                                                @"|[numberPad]|",
                                                                                @"V:[buttons]-[numberPad(portraitNumPadHeight)]|"]];

    [self setupConstraintsForOrientation:[UIDevice interfaceOrientation]];
}

@end
