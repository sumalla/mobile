//
//  SCUCDServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCDServiceViewController.h"
#import "SCUCDServiceViewControllerPrivate.h"
#import "SCUTransportButtonCollectionViewController.h"
#import "SCUButtonCollectionViewCell.h"

@interface SCUCDServiceViewController () <SCUPickerViewDelegate, SCUCDServiceViewModelDelegate, SCUButtonCollectionViewControllerDelegate>

@end

@implementation SCUCDServiceViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    if (self)
    {
        self.model = [[SCUCDServiceViewModel alloc] initWithService:service];
        self.model.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.diskPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsVertical];
    self.diskPicker.delegate = self;
    self.diskPicker.title = NSLocalizedString(@"Disk", nil);

    self.trackPicker = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsVertical];
    self.trackPicker.delegate = self;
    self.trackPicker.title = NSLocalizedString(@"Track", nil);

    self.numberPad = [[SCUNumberPadViewController alloc] initWithCommands:self.model.numberPadCommands];
    self.numberPad.delegate = self;
    [self addChildViewController:self.numberPad];

    self.transportControls = [[SCUButtonViewController alloc] initWithCollectionViewController:[[SCUTransportButtonCollectionViewController alloc] initWithGenericCommands:self.model.transportGenericCommands backCommands:self.model.transportBackCommands forwardCommands:self.model.transportForwardCommands]];
    self.transportControls.delegate = self;
    [(SCUTransportButtonCollectionViewController *)self.transportControls.collectionViewController setSingleRow:YES];
    [self addChildViewController:self.transportControls];

    self.openClose = [[SCUButtonViewController alloc] initWithCommands:@[@"TrayOpen", @"TrayClose"]];
    self.openClose.numberOfColumns = 2;
    self.openClose.numberOfRows = 1;
    self.openClose.delegate = self;
    [self addChildViewController:self.openClose];

    self.buttonPanel = [[SCUButtonViewController alloc] initWithCommands:@[@"TrayOpen", @"TrayClose", SCUEmptyButtonViewCellCommand, @"ToggleShuffle", @"ToggleRepeat"]];
    self.buttonPanel.numberOfRows = 2;
    self.buttonPanel.numberOfColumns = 5;
    self.buttonPanel.delegate = self;
    [self addChildViewController:self.buttonPanel];

    [self.buttonPanel.view addSubview:self.transportControls.view];
    [self.buttonPanel.view sav_pinView:self.transportControls.view withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToBottom];
    [self.buttonPanel.view sav_setHeight:.5 forView:self.transportControls.view isRelative:YES];

    self.diskLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.diskLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 109 : 90];
    [self setupLabel:self.diskLabel];

    self.trackLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.trackLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 109 : 90];
    [self setupLabel:self.trackLabel];

    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.progressLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 130 : 40];
    [self setupLabel:self.progressLabel];
    self.progressLabel.textColor = [[SCUColors shared] color04];

    self.shuffleButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"shuffle"]];
    self.shuffleButton.target = self.model;
    self.shuffleButton.releaseAction = @selector(toggleShuffle:);
    [self setupToggleButton:self.shuffleButton];

    self.repeatButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"repeat"]];
    self.repeatButton.target = self.model;
    self.repeatButton.releaseAction = @selector(toggleRepeat:);
    [self setupToggleButton:self.repeatButton];
}

- (void)setupLabel:(UILabel *)label
{
    label.textColor = [[SCUColors shared] color01];
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.textAlignment = NSTextAlignmentRight;
}

- (void)setupToggleButton:(SCUButton *)toggleButton
{
    toggleButton.backgroundColor = nil;
    toggleButton.color = [[SCUColors shared] color03shade04];
    toggleButton.selectedColor = [[SCUColors shared] color01];
    toggleButton.selectedBackgroundColor = nil;
}

#pragma mark - CD Model Delegate

- (void)diskChanged:(NSString *)disk
{
    self.diskLabel.text = disk;
}

- (void)trackChanged:(NSString *)track
{
    self.trackLabel.text = track;
}

- (void)progressChanged:(NSString *)progress
{
    self.progressLabel.text = progress;
}

#pragma mark - Picker View Delegate

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    if (direction == SCUPickerViewDirectionDown)
    {
        if (pickerView == self.diskPicker)
        {
            [self.model sendCommand:@"DiskDown"];
        }
        else
        {
            [self.model sendCommand:@"SkipDown"];
        }
    }
    else
    {
        if (pickerView == self.diskPicker)
        {
            [self.model sendCommand:@"DiskUp"];
        }
        else
        {
            [self.model sendCommand:@"SkipUp"];
        }
    }
}

# pragma mark - Button Pad Delegate

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([command isEqualToString:@"ToggleShuffle"])
    {
        [self.model toggleShuffle:button.cellButton];
    }
    else if ([command isEqualToString:@"ToggleRepeat"])
    {
        [self.model toggleRepeat:button.cellButton];
    }
    else
    {
        [self.model sendCommand:command];
    }
}

@end
