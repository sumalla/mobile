//
//  SCURadioNavigationViewControllerPad.m
//  SavantController
//
//  Created by David Fairweather on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioNavigationViewControllerPad.h"
#import "SCURadioNavigationViewControllerPrivate.h"

@interface SCURadioNavigationViewControllerPad ()

@end

@implementation SCURadioNavigationViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView removeConstraints:self.contentView.constraints];
    [self.numberPadContainer removeConstraints:self.numberPadContainer.constraints];

    [self.sliderView addSubview:self.MHzLabel];
    [self.sliderView sendSubviewToBack:self.MHzLabel];

    [self.sliderView addConstraints:[NSLayoutConstraint
                                     sav_constraintsWithOptions:0
                                     metrics:nil
                                     views:@{@"MHzLabel":self.MHzLabel}
                                     formats:@[@"V:[MHzLabel]-|",
                                               @"|[MHzLabel]"]]];
    
    NSUInteger numberOfTuneViews = 0;
    
    NSMutableDictionary *tunerViews = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *tunerFormats = [[NSMutableArray alloc] init];
    
    NSMutableString *horizontalFormatString = [@"|" mutableCopy];
    if (self.AMButton)
    {
        [self.tunerStripView addSubview:self.AMButton];
        [horizontalFormatString appendString:@"-(edgePadding)-[AM(buttonWidth)]"];
        tunerViews[@"AM"] = self.AMButton;
        [tunerFormats addObject:@"V:|[AM]|"];
        numberOfTuneViews++;
    }
    if (self.FMButton)
    {
        [self.tunerStripView addSubview:self.FMButton];
        [horizontalFormatString appendString:@"-(edgePadding)-[FM(buttonWidth)]"];
        tunerViews[@"FM"] = self.FMButton;
        [tunerFormats addObject:@"V:|[FM]|"];
        numberOfTuneViews++;
    }
    
    if ([horizontalFormatString length] > 1)
    {
        [tunerFormats addObject:horizontalFormatString];
    }
    
    horizontalFormatString = [@"" mutableCopy];

    if (self.tunePicker)
    {
        [self.tunerStripView addSubview:self.tunePicker];
        [horizontalFormatString appendString:@"[tunePicker(pickerWidth)]-(buttonSpacing)-"];
        tunerViews[@"tunePicker"] = self.tunePicker;
        [tunerFormats addObject:@"V:|[tunePicker]|"];
        numberOfTuneViews++;
    }

    if (self.seekPicker)
    {
        [self.tunerStripView addSubview:self.seekPicker];
        [horizontalFormatString appendString:@"[seekPicker(pickerWidth)]-(buttonSpacing)-"];
        tunerViews[@"seekPicker"] = self.seekPicker;
        [tunerFormats addObject:@"V:|[seekPicker]|"];
        numberOfTuneViews++;
    }

    if (self.favoritesButton)
    {
        [self.tunerStripView addSubview:self.favoritesButton];
        [horizontalFormatString appendString:@"[favorite(buttonWidth)]-(buttonSpacing)-"];
        tunerViews[@"favorite"] = self.favoritesButton;
        [tunerFormats addObject:@"V:|[favorite]|"];
        numberOfTuneViews++;
    }
    if (self.scanButton)
    {
        [self.tunerStripView addSubview:self.scanButton];
        [horizontalFormatString appendString:@"[scanButton(buttonWidth)]-(edgePadding)-"];
        tunerViews[@"scanButton"] = self.scanButton;
        [tunerFormats addObject:@"V:|[scanButton]|"];
        numberOfTuneViews++;
    }

    if ([horizontalFormatString length] > 1)
    {
        [horizontalFormatString appendString:@"|"];
        [tunerFormats addObject:horizontalFormatString];
    }
    
    self.tunerStripHeight = (numberOfTuneViews > 0) ? 56.0f : 0.0f;
    self.pickerWidth = 120.0f;
    self.topPadding = 30.0f;
    self.buttonSpacing = 20.0f;
    self.buttonWidth = 100.0f;
    
    if ([self.model.numberPadCommands count] > 0)
    {
        self.numberPadWidth = 300.0f;
        self.numberPadHeight = 370.0f;
    }
    else
    {
        self.numberPadWidth = 0.0f;
        self.numberPadHeight = 0.0f;
    }
    self.OffsetFromFrequencyLabel_X = 15.0f;

    NSDictionary *metrics = @{@"stripHeight": @(self.tunerStripHeight),
                              @"numpadHeight": @(self.numberPadHeight),
                              @"numpadWidth": @(self.numberPadWidth),
                              @"sliderHeight": @(self.sliderView.minimumWidth),

                              @"offsetX": @(10),
                              @"offsetY": @(30),
                              @"amFmLabelCenterOffset": @(150),
                              @"topPadding": @(self.topPadding),

                              @"buttonWidth": @(self.buttonWidth),
                              @"pickerWidth": @(self.pickerWidth),
                              @"edgePadding": @(5.0),
                              @"buttonSpacing": @(self.buttonSpacing),
                              };
    
    if (numberOfTuneViews > 0)
    {
        [self.tunerStripView addConstraints:[NSLayoutConstraint
                                             sav_constraintsWithOptions:0
                                             metrics:metrics
                                             views:tunerViews
                                             formats:tunerFormats]];
    }
    
    UIView *topSpacerView = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *bottomSpacerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:topSpacerView];
    [self.contentView addSubview:bottomSpacerView];
    
    NSDictionary *views = @{
                            @"tunerStrip": self.tunerStripView,
                            @"topSpacerView": topSpacerView,
                            @"currentFrequencyLabel": self.currentFrequencyLabel,
                            @"bandLabel": self.bandLabel,
                            @"bottomSpacerView": bottomSpacerView,
                            @"slider": self.sliderView,
                            @"sliderBackground": self.sliderBackground,
                            @"numberPad": self.numberPad.view,
                            };
    
    [self.contentView addConstraints:[NSLayoutConstraint
                                      sav_constraintsWithOptions:0
                                      metrics:metrics
                                      views:views
                                      formats:@[
                                                @"|[sliderBackground]",
                                                @"V:|[tunerStrip(stripHeight)]-[topSpacerView]-[currentFrequencyLabel]-[bottomSpacerView(==topSpacerView)]-[slider(sliderHeight)]",
                                                @"sliderBackground.right = slider.right",
                                                @"sliderBackground.bottom = slider.bottom",
                                                @"sliderBackground.left = slider.left",
                                                
                                                @"tunerStrip.right = slider.right",
                                                @"tunerStrip.left = slider.left",
                                                
                                                @"bandLabel.centerY = currentFrequencyLabel.centerY + offsetY",
                                                @"bandLabel.centerX = slider.centerX + amFmLabelCenterOffset",
                                                @"[currentFrequencyLabel]-(offsetX)-[bandLabel]",
                                                @"[numberPad]|"
                                                ]]];
    
    self.landscapeConstraints = [NSLayoutConstraint
                                 sav_constraintsWithOptions:0
                                 metrics:metrics
                                 views:views
                                 formats:@[
                                           @"[slider]-[numberPad(numpadWidth)]",
                                           @"V:[slider]-topPadding-|",
                                           @"V:|[numberPad]",
                                           @"V:[numberPad]-topPadding-|",
                                           ]];
    
    self.portraitConstraints = [NSLayoutConstraint
                                sav_constraintsWithOptions:0
                                metrics:metrics
                                views:views
                                formats:@[
                                          @"[slider]|",
                                          @"|[numberPad]",
                                          @"V:[numberPad]|",
                                          @"V:[slider]-topPadding-[numberPad(numpadHeight)]",
                                          ]];
}

@end
