//
//  SCUSatelliteRadioNavigationViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioNavigationViewController.h"
#import "SCUSatelliteRadioNavigationViewModel.h"
#import "SCUSatelliteRadioNavigationViewControllerPrivate.h"

@interface SCUSatelliteRadioNavigationViewController () <SCUPickerViewDelegate, SCUSatelliteRadioNavigationViewModelDelegate, SCUButtonCollectionViewControllerDelegate>

@property (nonatomic) SCUSatelliteRadioNavigationViewModel *model;

@end

@implementation SCUSatelliteRadioNavigationViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUSatelliteRadioNavigationViewModel alloc] initWithService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.channelPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
    self.channelPicker.delegate = self;
    self.channelPicker.title = NSLocalizedString(@"Channel", nil);
    self.channelPicker.holdDelay = 1.0;
    self.channelPicker.holdTime = .5;

    self.categoryPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsHorizontal];
    self.categoryPicker.delegate = self;
    self.categoryPicker.title = NSLocalizedString(@"Category", nil);

    self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:[self.model.numberPadCommands arrayByAddingObject:@"Enter"]];
    self.numberPad.delegate = self;
    [self addChildViewController:self.numberPad];

    self.channelLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self setupLabel:self.channelLabel];

    self.categoryLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self setupLabel:self.categoryLabel];

    self.albumLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self setupLabel:self.albumLabel];

    self.artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self setupSubtitleLabel:self.artistLabel];

    self.songLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self setupTitleLabel:self.songLabel];

    self.scanButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Scan", nil)];
    self.scanButton.target = self.model;
    self.scanButton.selectedBackgroundColor = nil;
    self.scanButton.selectedColor = [[SCUColors shared] color01];
    self.scanButton.borderWidth = [UIScreen screenPixel];
    self.scanButton.borderColor = [[SCUColors shared] color03shade04];

    self.scanButton.releaseAction = @selector(toggleScan:);
}

- (void)setupTitleLabel:(UILabel *)label
{
    label.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPad] ? 80 : 24];
    label.textColor = [[SCUColors shared] color01];
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .75;

    if ([UIDevice isPad])
    {
        label.textAlignment = NSTextAlignmentRight;
    }
}

- (void)setupSubtitleLabel:(UILabel *)label
{
    label.font = [UIFont fontWithName:@"Gotham-Thin" size:[UIDevice isPad] ? 80 : 20];
    label.textColor = [[SCUColors shared] color01];
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .75;

    if ([UIDevice isPad])
    {
        label.textAlignment = NSTextAlignmentRight;
    }
}

- (void)setupLabel:(UILabel *)label
{
    label.font = [UIFont fontWithName:@"Gotham-Thin" size:[UIDevice isPad] ? 80 : 17];
    label.textColor = [[SCUColors shared] color04];
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .75;

    if ([UIDevice isPad])
    {
        label.textAlignment = NSTextAlignmentRight;
    }
}

#pragma mark - SCUSatelliteRadio Model Delegate

- (void)categoryChanged:(NSString *)category
{
    self.categoryLabel.text = category;
}

- (void)channelChanged:(NSString *)channel
{
    self.channelLabel.text = channel;
}

- (void)albumChanged:(NSString *)album
{
    self.albumLabel.text = album;
}

- (void)artistChanged:(NSString *)artist
{
    self.artistLabel.text = artist;
}

- (void)songChanged:(NSString *)song
{
    self.songLabel.text = song;
}

#pragma mark - Picker View Delegate

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    if (direction == SCUPickerViewDirectionLeft)
    {
        if (pickerView == self.channelPicker)
        {
            [self.model sendCommand:@"DecrementChannel"];
        }
        else
        {
            [self.model sendCommand:@"DecrementCategory"];
        }
    }
    else
    {
        if (pickerView == self.channelPicker)
        {
            [self.model sendCommand:@"IncrementChannel"];
        }
        else
        {
            [self.model sendCommand:@"IncrementCategory"];
        }
    }
}

# pragma mark - Number Pad Delegate

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([command containsString:@"Enter"])
    {
        [self.model sendCommand:@"SetChannel" withArguments:@{@"ChannelNumber": self.numberPad.labelText}];
    }
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"navigation"];
}

@end
