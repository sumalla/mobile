//
//  SCURadioNavigationViewControllerPhone.m
//  SavantController
//
//  Created by David Fairweather on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioNavigationViewControllerPhone.h"
#import "SCURadioNavigationViewControllerPrivate.h"

@interface SCURadioNavigationViewControllerPhone ()

@end

@implementation SCURadioNavigationViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat numberFontSize = 52;
    CGFloat amFMCenterOffset = 70;
    if ([UIDevice isPhablet])
    {
        numberFontSize = 104;
        amFMCenterOffset = 140;
    }
    else if ([UIDevice isBigPhone])
    {
        numberFontSize = 70;
        amFMCenterOffset = 92;
    }
    CGFloat amFmFontSize = numberFontSize / 2;

    [self.contentView addSubview:self.MHzLabel];
    [self.contentView sendSubviewToBack:self.MHzLabel];
    self.currentFrequencyLabel.textAlignment = NSTextAlignmentCenter;
    self.currentFrequencyLabel.font = [UIFont fontWithName:@"Gotham-ExtraLight" size:numberFontSize];
    self.bandLabel.font = [UIFont fontWithName:@"Gotham-Light" size:amFmFontSize];
    self.numberPadDefaultVisableTime = 2.0f;

    
    NSUInteger numberOfTuneViews = (self.AMButton ? 1 : 0) + (self.FMButton ? 1 : 0) +
                                    (self.scanButton ? 1 : 0) + (self.favoritesButton ? 1 : 0) +
                                    (self.tunePicker ? 2 : 0) + (self.seekPicker ? 2 : 0);
    
    NSUInteger addedTunerViews = 0;

    NSMutableDictionary *tunerViews = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *tunerFormats = [[NSMutableArray alloc] init];
    
    NSMutableString *horizontalFormatString = [@"|-" mutableCopy];

    if (self.tunePicker)
    {
        [self.tunerStripView addSubview:self.tunePicker];
        [horizontalFormatString appendString:@"[tunePicker(pickerWidth)]-(buttonSpacing)-"];
        tunerViews[@"tunePicker"] = self.tunePicker;
        [tunerFormats addObject:@"V:|[tunePicker]|"];
        addedTunerViews += 2;
    }
    if (self.seekPicker)
    {
        [self.tunerStripView addSubview:self.seekPicker];
        [horizontalFormatString appendString:@"[seekPicker(pickerWidth)]-(buttonSpacing)-"];
        tunerViews[@"seekPicker"] = self.seekPicker;
        [tunerFormats addObject:@"V:|[seekPicker]|"];
        addedTunerViews += 2;
    }
    
    self.buttonSpacing = 5.0f;
    self.pickerWidth = 152.0f;
    NSMutableDictionary *tunePickerMetrics = [@{
                                                @"buttonSpacing": @(self.buttonSpacing),
                                                @"pickerWidth":@(self.pickerWidth)
                                                } mutableCopy];
    
    UIView *tuneStrip2;
    if (numberOfTuneViews > 4 || addedTunerViews == 4)
    {
        if (addedTunerViews == 4)
        {
            UIView *rightPad = [[UIView alloc] initWithFrame:CGRectZero];
            UIView *leftPad = [[UIView alloc] initWithFrame:CGRectZero];
            UIView *centerRightPad = [[UIView alloc] initWithFrame:CGRectZero];
            UIView *centerLeftPad = [[UIView alloc] initWithFrame:CGRectZero];
            tunerViews[@"rightPad"] = rightPad;
            tunerViews[@"leftPad"] = leftPad;
            tunerViews[@"centerRightPad"] = centerRightPad;
            tunerViews[@"centerLeftPad"] = centerLeftPad;
            [self.tunerStripView addSubview:rightPad];
            [self.tunerStripView addSubview:leftPad];
            [self.tunerStripView addSubview:centerRightPad];
            [self.tunerStripView addSubview:centerLeftPad];
            
            [tunerFormats addObjectsFromArray:@[@"|[leftPad(==rightPad)][tunePicker(pickerWidth)][centerLeftPad(==rightPad)][centerRightPad(==rightPad)][seekPicker(pickerWidth)][rightPad]|"]];
        }
        else
        {
            [horizontalFormatString replaceOccurrencesOfString:@"-(buttonSpacing)-" withString:@"" options:NSBackwardsSearch range:NSMakeRange(0, [horizontalFormatString length])];
            [tunerFormats addObject:horizontalFormatString];
        }
        horizontalFormatString = [@"|-(buttonSpacing)-" mutableCopy];
        
        [self.tunerStripView addConstraints:[NSLayoutConstraint
                                             sav_constraintsWithOptions:0
                                             metrics:tunePickerMetrics
                                             views:tunerViews
                                             formats:tunerFormats]];
        tunerViews = [[NSMutableDictionary alloc] init];
        
        tunerFormats = [[NSMutableArray alloc] init];
        
        tuneStrip2 = [[UIView alloc] init];
        [self.contentView addSubview:tuneStrip2];
        addedTunerViews = 0;
    }
    else
    {
        tuneStrip2 = self.tunerStripView;
    }

    NSString *firstItem = nil;

    if (self.favoritesButton)
    {
        [tuneStrip2 addSubview:self.favoritesButton];
        [horizontalFormatString appendString:@"[favorite]-(buttonSpacing)-"];
        tunerViews[@"favorite"] = self.favoritesButton;
        [tunerFormats addObject:@"V:|[favorite]|"];
        firstItem = @"favorite";
        addedTunerViews++;
    }
    
    if (self.scanButton)
    {
        [tuneStrip2 addSubview:self.scanButton];
        NSString *appendString = (firstItem ? [NSString stringWithFormat:@"[scanButton(==%@)]-(buttonSpacing)-", firstItem]: @"[scanButton]-(buttonSpacing)-");
        [horizontalFormatString appendString:appendString];
        [horizontalFormatString appendString:@"[scanButton]-(buttonSpacing)-"];
        tunerViews[@"scanButton"] = self.scanButton;
        [tunerFormats addObject:@"V:|[scanButton]|"];
        firstItem = @"scanButton";
        addedTunerViews++;
    }

    if (self.AMButton)
    {
        [tuneStrip2 addSubview:self.AMButton];
        NSString *appendString = (firstItem ? [NSString stringWithFormat:@"[AM(==%@)]-(buttonSpacing)-", firstItem]: @"[AM]-(buttonSpacing)-");
        [horizontalFormatString appendString:appendString];
        tunerViews[@"AM"] = self.AMButton;
        [tunerFormats addObject:@"V:|[AM]|"];
        firstItem = @"AM";
        addedTunerViews++;
    }

    if (self.FMButton)
    {
        [tuneStrip2 addSubview:self.FMButton];
        NSString *appendString = (firstItem ? [NSString stringWithFormat: @"[FM(==%@)]-(buttonSpacing)-", firstItem]: @"[FM]-(buttonSpacing)-");
        [horizontalFormatString appendString:appendString];
        tunerViews[@"FM"] = self.FMButton;
        [tunerFormats addObject:@"V:|[FM]|"];
        addedTunerViews++;
    }
    
    if (addedTunerViews > 0)
    {
        if ([horizontalFormatString length] > 1)
        {
            if ((self.tunePicker || self.seekPicker) && numberOfTuneViews == 2)
            {
                NSString *centerPicker = nil;
                if (self.tunePicker)
                {
                    centerPicker = @"tunePicker";
                }
                else if (self.seekPicker)
                {
                    centerPicker = @"seekPicker";
                }

                UIView *rightPad = [[UIView alloc] initWithFrame:CGRectZero];
                UIView *leftPad = [[UIView alloc] initWithFrame:CGRectZero];
                tunerViews[@"rightPad"] = rightPad;
                tunerViews[@"leftPad"] = leftPad;
                [self.tunerStripView addSubview:rightPad];
                [self.tunerStripView addSubview:leftPad];
                
                [tunerFormats addObjectsFromArray:@[]];
                if (centerPicker)
                {
                    horizontalFormatString = [[NSString stringWithFormat:@"|[leftPad(==rightPad)][%@(pickerWidth)][rightPad]|", centerPicker] mutableCopy];
                }
                else
                {
                    horizontalFormatString = nil;
                }
            }
            else
            {
                [horizontalFormatString appendString:@"|"];
            }
            if (horizontalFormatString)
            {
                [tunerFormats addObject:horizontalFormatString];
            }
        }
        [tuneStrip2 addConstraints:[NSLayoutConstraint
                                    sav_constraintsWithOptions:0
                                    metrics:tunePickerMetrics
                                    views:tunerViews
                                    formats:tunerFormats]];
    }

    
    self.tunerStripHeight = 36.0f;
    
    self.topPadding = 5.0f;
    self.OffsetFromFrequencyLabel_X = 5.0f;
    self.OffsetFromFrequencyLabel_Y = (numberFontSize - amFmFontSize) / 2.6;

    CGFloat sliderPadding = 15.0f;
    
    if ([self.model.numberPadCommands count] > 0)
    {
        if ([UIDevice isShortPhone])
        {
            self.numberPadHeight = 155;
        }
        else if ([UIDevice isTallPhone])
        {
            self.numberPadHeight = 240;
        }
        else if ([UIDevice isBigPhone] || [UIDevice isPhablet])
        {
            self.numberPadHeight = 300;
        }
    }
    else
    {
        self.numberPadHeight = 0.0f;
    }
    [self.MHzLabel sizeToFit];
    
    NSDictionary *contentViewMetrics = @{@"topPadding": @(self.topPadding),
                                         @"sliderBottomPadding": @(sliderPadding),
                                         @"hzLabelBottomSpace": @(self.MHzLabel.frame.size.height - 6),
                                         @"sliderRightPadding": @(self.MHzLabel.frame.size.width - 2),
                                         @"numPadHeight": @(self.numberPadHeight),
                                         @"offsetX": @(self.OffsetFromFrequencyLabel_X),
                                         @"offsetY": @(self.OffsetFromFrequencyLabel_Y),
                                         @"amFmLabelCenterOffset": @(amFMCenterOffset),
                                         @"sliderHeight": @(self.sliderView.minimumWidth),
                                         @"stripHeight1" : @(((numberOfTuneViews > 0) ?
                                                              self.tunerStripHeight : 0)),
                                         @"stripHeight2" : @(((numberOfTuneViews > 4) ?
                                                              self.tunerStripHeight : 0)),
                                         };
    
    NSDictionary *contentViews = @{
                                   @"tunerStrip": self.tunerStripView,
                                   @"currentFrequencyLabel": self.currentFrequencyLabel,
                                   @"bandLabel": self.bandLabel,
                                   @"slider": self.sliderView,
                                   @"tunerStrip2": tuneStrip2,
                                   @"numberPad": self.numberPad.view,
                                   @"MHzLabel": self.MHzLabel
                                   };
    
    NSMutableArray *formats = [@[
                                 @"|[MHzLabel]",
                                 @"|-sliderRightPadding-[slider]|",
                                 @"|[tunerStrip]|",
                                 @"|[numberPad]|",
                                 
                                 @"bandLabel.centerY = currentFrequencyLabel.centerY + offsetY",
                                 @"bandLabel.centerX = slider.centerX + amFmLabelCenterOffset",
                                 
                                 @"[currentFrequencyLabel]-(offsetX)-[bandLabel]",
                                 
                                 @"V:|-topPadding-[tunerStrip(stripHeight1)][currentFrequencyLabel][slider(sliderHeight)]",
                                 ] mutableCopy];
    NSArray *addFormats;
    if (tuneStrip2 == self.tunerStripView)
    {
        addFormats = @[@"V:[MHzLabel]-hzLabelBottomSpace-[numberPad]",
                       @"V:[slider]-sliderBottomPadding-[numberPad(numPadHeight)]|"];
        
    }
    else
    {
        addFormats = @[@"V:[MHzLabel]-hzLabelBottomSpace-[tunerStrip2]",
                       @"V:[slider]-sliderBottomPadding-[tunerStrip2(stripHeight2)]-topPadding-[numberPad(numPadHeight)]|",
                       @"|[tunerStrip2]|"];
    }
    
    [formats addObjectsFromArray:addFormats];

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:contentViewMetrics
                                                                              views:contentViews
                                                                            formats:formats]];
}

@end
