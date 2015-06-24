//
//  SCURadioServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURadioNavigationViewController.h"
#import "SCURadioNavigationViewModel.h"
#import "SCUSliderView.h"
#import "SCUPickerView.h"
#import "SCUGradientView.h"
#import "SCUButton.h"
#import "SCUNumberPadViewController.h"
#import "SCURadioNavigationViewControllerPrivate.h"

@import Extensions;

@interface SCURadioNavigationViewController () <SCUSliderViewDelegate, SCUButtonCollectionViewControllerDelegate, SCUPickerViewDelegate, SCURadioModelDelegate>

@property (weak) NSTimer *holdTimer;
@property (nonatomic) CGFloat pingTime;
@property (nonatomic) BOOL isHeld;

@end

@implementation SCURadioNavigationViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCURadioNavigationViewModel alloc] initWithService:service];
        self.model.delegate = self;
        self.pingTime = 1.0f;
        self.holdTimer = nil;
    }
    return self;
}

- (BOOL)showfavorites
{
    return [self.model radioContainsCommand:@"SetRadioFrequency"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tunerStripView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tunerStripView.backgroundColor = [[SCUColors shared] color03shade01];
    [self.contentView addSubview:self.tunerStripView];
    
    if (self.model.isMultiBand && [self.model radioContainsCommand:@"ToggleBand"])
    {
        self.AMButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"AM", nil)];
        self.AMButton.target = self;
        self.AMButton.releaseAction = @selector(changeFrequencies:);
        self.AMButton.borderWidth = [UIScreen screenPixel];
        self.AMButton.borderColor = [[SCUColors shared] color03shade04];
        
        self.FMButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"FM", nil)];
        self.FMButton.target = self;
        self.FMButton.releaseAction = @selector(changeFrequencies:);
        self.FMButton.borderWidth = [UIScreen screenPixel];
        self.FMButton.borderColor = [[SCUColors shared] color03shade04];
    }
    
    if ([self.model radioContainsCommand:@"ScanTP"])
    {
        self.scanButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Scan", nil)];
        self.scanButton.target = self;
        self.scanButton.releaseAction = @selector(changeFrequencies:);
        self.scanButton.borderWidth = [UIScreen screenPixel];
        self.scanButton.borderColor = [[SCUColors shared] color03shade04];
    }
    
    if ([self.model radioContainsCommand:@"SeekUp"])
    {
        self.seekPicker = [[SCUPickerView alloc] initWithFrame:CGRectZero andConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
        self.seekPicker.delegate = self;
        self.seekPicker.title = NSLocalizedString(@"Seek", nil);
    }
    
    if ([self.model radioContainsCommand:@"IncrementRadioFrequency"])
    {
        self.tunePicker = [[SCUPickerView alloc] initWithFrame:CGRectZero andConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
        self.tunePicker.delegate = self;
        self.tunePicker.title = NSLocalizedString(@"Tune", nil);
        [self.tunePicker setHoldTime:0.2f];
        [self.tunePicker setHoldDelay:0.8f];
    }
    
//-------------------------------------------------------------------
//  favorites button
//-------------------------------------------------------------------
//    self.favoritesButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"favorites"]];
//    self.favoritesButton.backgroundColor = [UIColor sav_colorWithRGBValue:0x3d3d3d];
//    self.favoritesButton.target = self;
//    self.favoritesButton.releaseAction = @selector(toggleFavorite:);
//    self.favoritesButton.borderWidth = [UIScreen screenPixel];
//    self.favoritesButton.borderColor = [[SCUColors shared] color03shade04];

    
    self.sliderView = [[SCUSliderView alloc] initWithFrame:CGRectZero andConfiguration:SCUSliderViewConfigurationHorizontal];
    [self.sliderView setScaleOfSliderFrom:self.model.minFrequency To:self.model.maxFrequency];
    [self.sliderView setColorOfMainHandle:[[SCUColors shared] color01]];
    self.sliderView.delegate = self;
    self.sliderView.longPress.minimumPressDuration = 0.001f;
    
    self.MHzLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.MHzLabel setText:NSLocalizedString(@"MHz", nil)];
    [self.MHzLabel setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
    self.MHzLabel.font = [UIFont fontWithName:@"Gotham" size:([UIDevice isPad] ? 15.0f : 12.0f)];
    self.MHzLabel.textColor = [UIColor sav_colorWithRGBValue:0xABABAB];
    [self.MHzLabel sizeToFit];
    
    self.sliderBackground = [[UIView alloc] initWithFrame:CGRectZero];
    self.sliderBackground.backgroundColor = [[SCUColors shared] color03shade01];
    
    self.currentFrequencyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.currentFrequencyLabel.textColor = [[SCUColors shared] color01];
    self.currentFrequencyLabel.font = [UIFont fontWithName:@"Gotham-Extra-light-Savant" size:130.0f];
    
    self.bandLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bandLabel.textColor = [[SCUColors shared] color01];
    self.bandLabel.font = [UIFont fontWithName:@"Gotham-Light" size:65.0f];
    self.bandLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.contentView addSubview:self.sliderBackground];
    [self.contentView addSubview:self.sliderView];
    [self.sliderView addSubview:self.currentFrequencyLabel];
    [self.contentView addSubview:self.bandLabel];

    //-------------------------------------------------------------------
    // Sets the visibility of the slider view. May not be applicable for
    // some radios
    //-------------------------------------------------------------------
    [self setSliderVisibility:NO];
    if ([self.model radioContainsCommand:@"SetRadioFrequency"])
    {
        [self setSliderVisibility:YES];
        self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:[self.model.numberPadCommands arrayByAddingObject:@"NumberEnter"]];
    }
    else if ([self.model.numberPadCommands count] > 9)
    {
        self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:self.model.numberPadCommands];
        [((SCUNumberPadViewController *)self.numberPad) setIsPresetOnly:YES];
    }
    else
    {
        NSInteger totalItems = [self.model.numberPadCommands count];
        
        self.numberPad = [[SCUButtonViewController alloc] initWithCommands:self.model.numberPadCommands];
        self.numberPad.numberOfColumns = 3;
        self.numberPad.numberOfRows = (totalItems + 2) / 3;
    }
    [self addChildViewController:self.numberPad];
    self.numberPad.delegate = self;
    
    [self.contentView addSubview:self.numberPad.view];
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"navigation"];
}

#pragma mark - SCUMainToolbarManager methods

- (void)setSliderVisibility:(BOOL)visible
{
    if (!visible)
    {
        [self.sliderView setSliderVisibility:NO];
    }
    else
    {
        [self.sliderView setSliderVisibility:YES];
        self.sliderView.userInteractionEnabled = YES;
        self.bandLabel.hidden = NO;
        self.currentFrequencyLabel.hidden = NO;
    }
}

//-------------------------------------------------------------------
// changes over the frequencies of the radio from AM to PM and sends
// scan command
//-------------------------------------------------------------------
- (void)changeFrequencies:(SCUButton *)button
{
//-------------------------------------------------------------------
// values need to be changed and updated when switching between bands.
//-------------------------------------------------------------------
    
    if ((button == self.AMButton) || (button == self.FMButton))
    {
        if (button == self.AMButton)
        {
            self.bandLabel.text = NSLocalizedString(@"AM", nil);
            [self.model changeBandTo:SCURadioTypeAM];
        }
        else if(button == self.FMButton)
        {
            self.bandLabel.text = NSLocalizedString(@"FM", nil);
            [self.model changeBandTo:SCURadioTypeFM];
        }
        [self.bandLabel sizeToFit];
        
        [self.sliderView setScaleOfSliderFrom:self.model.minFrequency To:self.model.maxFrequency];
    }
    else
    {
        if (!self.model.isScanning)
        {
            self.scanButton.selected = YES;
            [self.model scanTP];
        }
        else
        {
            self.scanButton.selected = NO;
            [self.model finishScan];
        }
    }
}

//-------------------------------------------------------------------
// takes the current frequency and either adds/removes it from the
// list of favorites for the favorites view
//-------------------------------------------------------------------
- (void)toggleFavorite:(SCUButton *)button
{
    //insert favorites stuff here
}

//-------------------------------------------------------------------
// constraints are deleted and updated to match the orientation
//-------------------------------------------------------------------
- (void)viewWillLayoutSubviews
{
//    self.sliderView.longPressControlRange = CGRectGetWidth(self.view.bounds);
}

//-------------------------------------------------------------------
// Handle Slider View Delegate
//-------------------------------------------------------------------
- (void)sliderView:(SCUSliderView *)sliderView didChangeValueWithDesiredValue:(CGFloat)value andHeldDown:(BOOL)hold
{
    [self.sliderView setSliderVisibility:YES];
    self.isHeld = hold;
    
    BOOL fmValue = value < 200;
    
    if ((self.model.currentBand == SCURadioTypeFM) != fmValue)
    {
        return;
    }
    CGFloat significance = fmValue ? self.model.fmSignificance : self.model.amSignificance;
    
    CGFloat stationFrequency = floorf(value * (1 / significance)) / (1 / significance);

    if (fmValue)
    {
//-------------------------------------------------------------------
// Converts the slider's value into frequency, then rounds it to the
// nearest tenth
//-------------------------------------------------------------------
        if (significance > 0.15)
        {
            stationFrequency += 0.1f;
        }
        if (significance > 0.08)
        {
            self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%.1f", stationFrequency];
        }
        else
        {
            self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%.2f", stationFrequency];
        }
        self.bandLabel.text = @"FM";
    }
    else
    {
        self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%ld", (long)stationFrequency];
        self.bandLabel.text = @"AM";
    }
    
    self.currentSliderFrequency = stationFrequency;
//    [self.currentFrequencyLabel sizeToFit];
    [self.bandLabel sizeToFit];
    
//-------------------------------------------------------------------
// Does not send command unless the slider handle is no longer held down or
// tapped.
//-------------------------------------------------------------------
    if (hold)
    {
        if (!self.holdTimer)
        {
            self.holdTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.pingTime repeats:YES block:^{
                [self.model setFrequency:self.currentSliderFrequency];
            }];
        }
    }
    else
    {
        if (self.holdTimer)
        {
            [self.holdTimer invalidate];
            self.holdTimer = nil;
        }
        [self.model setFrequency:stationFrequency];
    }
}

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    if (direction == SCUPickerViewDirectionLeft)
    {
        if (pickerView == self.tunePicker)
        {
            [self.model tuneDownFrequency];
        }
        else
        {
            [self.model seekDown];
        }
    }
    else
    {
        if (pickerView == self.tunePicker)
        {
            [self.model tuneUpFrequency];
        }
        else
        {
            [self.model seekUp];
        }
    }
}

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([command containsString:@"Enter"] && [self.model radioContainsCommand:@"SetRadioFrequency"])
    {
        CGFloat frequency = -1;
        if ([self.numberPad isKindOfClass:[SCUNumberPadViewController class]])
        {
            frequency = [((SCUNumberPadViewController *)self.numberPad).labelText floatValue];
        }

        if (frequency >= self.model.minFrequency && frequency <= self.model.maxFrequency)
        {
            [self.model setFrequency:frequency];
        }
        else if (frequency >= self.model.minFrequency * 10 && frequency <= self.model.maxFrequency * 10 && self.model.currentBand == SCURadioTypeFM)
        {
            [self.model setFrequency:frequency / 10];
        }
    }
    else if (![command containsString:@"Number"] || ![self.model radioContainsCommand:@"SetRadioFrequency"])
    {
        [self.model sendCommand:command];
    }
}

- (void)didReceiveCurrentFrequency:(CGFloat)frequency
{
    if (self.currentFrequencyLabel.hidden)
    {
        [self setSliderVisibility:YES];
    }
    BOOL notFound = ((NSNotFound - frequency) < 1);

    if (!self.isHeld)
    {
        switch (self.model.currentBand)
        {
            case SCURadioTypeFM:
            {
                self.bandLabel.text = @"FM";
                if (notFound)
                {
                    self.currentFrequencyLabel.text = @"--.-";
                }
                else
                {
                    if (self.model.fmSignificance > 0.08)
                    {
                        self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%.1f", frequency];
                    }
                    else
                    {
                        self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%.2f", frequency];
                    }
                }
                break;
            }
            case SCURadioTypeAM:
            {
                self.bandLabel.text = @"AM";
                if (notFound)
                {
                    self.currentFrequencyLabel.text = @"---";
                }
                else
                {
                    self.currentFrequencyLabel.text = [NSString stringWithFormat:@"%ld", (long)frequency];
                }
                break;
            }
            default:
                break;
        }
        [self.bandLabel sizeToFit];
        [self.currentFrequencyLabel sizeToFit];
    }
    [self.sliderView changeValueOfHandleToValue:frequency];
}

- (NSDictionary *)getCurrentSetPoints
{
    NSMutableDictionary *setPoints = [@{} mutableCopy];
    
    if (self.model.CurrentTunerFrequency != NSNotFound)
    {
        [setPoints setObject:@(self.model.CurrentTunerFrequency) forKey:SCUSliderMiddleSetPoint];
    }    
    return setPoints;
}

@end
