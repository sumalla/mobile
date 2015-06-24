//
//  SCUAVEqualizerViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVEqualizerViewController.h"
#import "SCUAVSettingsEqualizerModel.h"
#import "SCUButton.h"
#import "SCUCenteredSlider.h"
#import "SCUVolumeViewController.h"
#import "SCUAVSettingsEqualizerPresetTableViewController.h"
#import "SCUThemedNavigationViewController.h"
#import "SCUAVSettingsEqualizerSendToTableViewController.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUAVEqualizerViewController () <SCUAVSettingsEqualizerModelDelegate, UIPopoverControllerDelegate>

@property (nonatomic) SCUAVSettingsEqualizerModel *model;

@property (nonatomic) UIView *volumeContainer;
@property (nonatomic) UILabel *volumeLabel;
@property (nonatomic) SCUVolumeViewController *volumeController;

@property (nonatomic) UIView *separator;

@property (nonatomic) UIView *actionsContainer;
@property (nonatomic) SCUButton *sendToButton;
@property (nonatomic) SCUButton *resetButton;
@property (nonatomic) SCUButton *presetPickerButton;
@property (nonatomic) SCUButton *addNewPresetButton;

@property (nonatomic) UIView *labelsContainer;
@property (nonatomic) UILabel *dbLabel1;
@property (nonatomic) UILabel *dbLabel2;
@property (nonatomic) UILabel *dbLabel3;
@property (nonatomic) UILabel *dbLabel4;
@property (nonatomic) UILabel *dbLabel5;
@property (nonatomic) UILabel *dbLabel6;
@property (nonatomic) UILabel *dbLabel7;
@property (nonatomic) SCUCenteredSlider *slider1;
@property (nonatomic) SCUCenteredSlider *slider2;
@property (nonatomic) SCUCenteredSlider *slider3;
@property (nonatomic) SCUCenteredSlider *slider4;
@property (nonatomic) SCUCenteredSlider *slider5;
@property (nonatomic) SCUCenteredSlider *slider6;
@property (nonatomic) SCUCenteredSlider *slider7;
@property (nonatomic) UILabel *hzLabel1;
@property (nonatomic) UILabel *hzLabel2;
@property (nonatomic) UILabel *hzLabel3;
@property (nonatomic) UILabel *hzLabel4;
@property (nonatomic) UILabel *hzLabel5;
@property (nonatomic) UILabel *hzLabel6;
@property (nonatomic) UILabel *hzLabel7;

@property (nonatomic) UIPopoverController *popController;
@property (nonatomic) SCUAVSettingsEqualizerPresetTableViewController *presetPickerViewController;
@property (nonatomic) SCUAVSettingsEqualizerSendToTableViewController *sendToViewController;

@end

@implementation SCUAVEqualizerViewController

- (instancetype)initWithModel:(SCUAVSettingsEqualizerModel *)model
{
    self = [super init];

    if (self)
    {
        self.model = model;
        self.model.delegate = self;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Equalizer Settings", nil);

    //-------------------------------------------------------------------
    // Setup the containers.
    //-------------------------------------------------------------------
    self.volumeContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.volumeContainer];

    self.separator = [[UIView alloc] initWithFrame:CGRectZero];
    self.separator.backgroundColor = [[SCUColors shared] color03shade07];
    [self.view addSubview:self.separator];

    self.actionsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.actionsContainer];

    self.labelsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.labelsContainer];

    {
        NSDictionary *metrics = @{@"volumeContainerHeight": [UIDevice isPad] ? @100 : @70,
                                  @"containerHeight": [UIDevice isPad] ? @80 : @60,
                                  @"separatorHeight": @([UIScreen screenPixel])};

        NSDictionary *views = @{@"volume": self.volumeContainer,
                                @"separator": self.separator,
                                @"actions": self.actionsContainer,
                                @"labels": self.labelsContainer};

        [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                         metrics:metrics
                                                                           views:views
                                                                         formats:@[@"|[volume]|",
                                                                                   @"|-[separator]-|",
                                                                                   @"|[actions]|",
                                                                                   @"|-[labels]-|",
                                                                                   @"V:|-[volume(volumeContainerHeight)][separator(separatorHeight)]-[actions(containerHeight)][labels]-|"]]];
    }

    //-------------------------------------------------------------------
    // Setup the volume container.
    //-------------------------------------------------------------------
    self.volumeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.volumeLabel.text = NSLocalizedString(@"Volume:", nil);
    self.volumeLabel.textColor = [[SCUColors shared] color04];
    [self.volumeContainer addSubview:self.volumeLabel];

    SAVService *service = [[SAVService alloc] initWithZone:self.model.room.roomId
                                                 component:nil
                                          logicalComponent:nil
                                                 variantId:nil
                                                 serviceId:@"SVC_SETTINGS_EQUALIZER"];
    
    self.volumeController = [[SCUVolumeViewController alloc] initWithService:service];
    self.volumeController.fullWidth = YES;
    [self addChildViewController:self.volumeController];
    [self.volumeContainer addSubview:self.volumeController.view];

    {
        NSDictionary *views = @{@"label": self.volumeLabel,
                                @"volume": self.volumeController.view};

        [self.volumeContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                    metrics:nil
                                                                                      views:views
                                                                                    formats:@[@"|-[label]",
                                                                                              @"|-[volume]-|",
                                                                                              @"V:|[label][volume]-|"]]];
    }

    //-------------------------------------------------------------------
    // Setup the actions container.
    //-------------------------------------------------------------------
    self.sendToButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"distribute"]];
    self.sendToButton.target = self.model;
    self.sendToButton.releaseAction = @selector(sendTo);

    self.resetButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Reset", nil)];
    self.resetButton.disabledColor = [[SCUColors shared] color03shade07];
    self.resetButton.userInteractionEnabled = NO;
    self.resetButton.target = self.model;
    self.resetButton.releaseAction = @selector(resetCurrentPreset);

    self.presetPickerButton = [[SCUButton alloc] initWithTitle:self.model.presetName];
    self.presetPickerButton.target = self.model;
    self.presetPickerButton.releaseAction = @selector(pickPreset);

    self.addNewPresetButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"VolumePlus"]];
    self.addNewPresetButton.userInteractionEnabled = NO;
    self.addNewPresetButton.target = self.model;
    self.addNewPresetButton.releaseAction = @selector(addPreset);

    for (SCUButton *button in @[self.sendToButton, self.resetButton, self.presetPickerButton, self.addNewPresetButton])
    {
        button.color = [[SCUColors shared] color01];
        button.backgroundColor = [UIColor clearColor];
        button.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:0.6];
        button.selectedBackgroundColor = [UIColor clearColor];
        [self.actionsContainer addSubview:button];
    }

    {
        NSDictionary *views = @{@"send": self.sendToButton,
                                @"refresh": self.resetButton,
                                @"preset": self.presetPickerButton,
                                @"add": self.addNewPresetButton};

        [self.actionsContainer addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                     metrics:nil
                                                                                       views:views
                                                                                     formats:@[@"|-[send]",
                                                                                               @"[add]-|",
                                                                                               @"refresh.centerX = super.centerX",
                                                                                               @"|[preset]|",
                                                                                               @"V:|[send]-[preset]|",
                                                                                               @"V:|[refresh]-[preset]|",
                                                                                               @"V:|[add]-[preset]|"]]];
    }

    //-------------------------------------------------------------------
    // Setup the labels container.
    //-------------------------------------------------------------------
    self.dbLabel1 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel3 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel4 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel5 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel6 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.dbLabel7 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel1 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel2 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel3 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel4 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel5 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel6 = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hzLabel7 = [[UILabel alloc] initWithFrame:CGRectZero];

    for (UILabel *label in @[self.dbLabel1, self.dbLabel2, self.dbLabel3, self.dbLabel4, self.dbLabel5, self.dbLabel6, self.dbLabel7, self.hzLabel1, self.hzLabel2, self.hzLabel3, self.hzLabel4, self.hzLabel5, self.hzLabel6, self.hzLabel7])
    {
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [[SCUColors shared] color04];
        label.font = [UIFont systemFontOfSize:[UIDevice isPad] ? 16 : 12];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = .3;
        [self.labelsContainer addSubview:label];
    }

    self.slider1 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider2 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider3 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider4 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider5 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider6 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    self.slider7 = [[SCUCenteredSlider alloc] initWithFrame:CGRectZero];
    
    NSUInteger sliderOrder = 1;
    NSArray *sliders = @[self.slider1, self.slider2, self.slider3, self.slider4, self.slider5, self.slider6, self.slider7];
    
    for (SCUCenteredSlider *slider in sliders)
    {
        slider.transform = CGAffineTransformMakeRotation(-M_PI_2);
        slider.fillColor = [[SCUColors shared] color01];
        [slider sav_setWidth:30 forView:slider isRelative:NO];
        slider.centerTapThreshold = 10;
        [self.labelsContainer addSubview:slider];
        [self.model registerSlider:slider withOrder:sliderOrder];
        sliderOrder++;
    }
    
    
    
    UIView *container1 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container2 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container3 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container4 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container5 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container6 = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *container7 = [[UIView alloc] initWithFrame:CGRectZero];
    
    NSArray *containers = @[@[container1, self.slider1, self.hzLabel1, self.dbLabel1],
                            @[container2, self.slider2, self.hzLabel2, self.dbLabel2],
                            @[container3, self.slider3, self.hzLabel3, self.dbLabel3],
                            @[container4, self.slider4, self.hzLabel4, self.dbLabel4],
                            @[container5, self.slider5, self.hzLabel5, self.dbLabel5],
                            @[container6, self.slider6, self.hzLabel6, self.dbLabel6],
                            @[container7, self.slider7, self.hzLabel7, self.dbLabel7]];
    
    for (NSArray *views in containers)
    {
        [views[0] addSubview:views[1]];
        [views[0] addSubview:views[2]];
        [views[0] addSubview:views[3]];
        
        [views[0] sav_pinView:views[1] withOptions:SAVViewPinningOptionsCenterX|SAVViewPinningOptionsCenterY];
        [views[0] sav_pinView:views[1] withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToBottom withSpace:30.0];
        [views[0] sav_pinView:views[3] withOptions:SAVViewPinningOptionsCenterX|SAVViewPinningOptionsToTop];
        [views[0] sav_pinView:views[2] withOptions:SAVViewPinningOptionsCenterX|SAVViewPinningOptionsToBottom withSpace:10];
    }
    
    NSArray *containersArray = @[container1, container2, container3, container4, container5, container6, container7];
    
    SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
    config.distributeEvenly = YES;
    
    UIView *slidersContainer = [UIView sav_viewWithEvenlyDistributedViews:containersArray withConfiguration:config];
    [self.labelsContainer addSubview:slidersContainer];
    [self.labelsContainer sav_addFlushConstraintsForView:slidersContainer];
    
}

#pragma mark - Methods to subclass

- (id<SCUViewModel>)viewModel
{
    return self.model;
}

#pragma mark - SCUAVSettingsEqualizerModelDelegate

- (void)updateCurrentPreset
{
    self.resetButton.userInteractionEnabled = self.model.isResetEnabled;
    self.addNewPresetButton.userInteractionEnabled = self.model.isAddPresetEnabled;
    self.presetPickerButton.title = self.model.presetName;

    [self.slider1 setValue:[self.model.amplitude1 floatValue] animated:YES];
    self.dbLabel1.text = self.model.amplitude1;
    self.hzLabel1.text = self.model.frequency1;

    [self.slider2 setValue:[self.model.amplitude2 floatValue] animated:YES];
    self.dbLabel2.text = self.model.amplitude2;
    self.hzLabel2.text = self.model.frequency2;

    [self.slider3 setValue:[self.model.amplitude3 floatValue] animated:YES];
    self.dbLabel3.text = self.model.amplitude3;
    self.hzLabel3.text = self.model.frequency3;

    [self.slider4 setValue:[self.model.amplitude4 floatValue] animated:YES];
    self.dbLabel4.text = self.model.amplitude4;
    self.hzLabel4.text = self.model.frequency4;

    [self.slider5 setValue:[self.model.amplitude5 floatValue] animated:YES];
    self.dbLabel5.text = self.model.amplitude5;
    self.hzLabel5.text = self.model.frequency5;

    [self.slider6 setValue:[self.model.amplitude6 floatValue] animated:YES];
    self.dbLabel6.text = self.model.amplitude6;
    self.hzLabel6.text = self.model.frequency6;
    
    [self.slider7 setValue:[self.model.amplitude7 floatValue] animated:YES];
    self.dbLabel7.text = self.model.amplitude7;
    self.hzLabel7.text = self.model.frequency7;
}

- (void)showPresetPickerWithModel:(SCUAVSettingsEqualizerPresetModel *)model
{
    self.presetPickerViewController = [[SCUAVSettingsEqualizerPresetTableViewController alloc] initWithModel:model];

    SAVWeakSelf;
    self.presetPickerViewController.sav_dismissalBlock = ^{
        SAVStrongWeakSelf;
        if ([UIDevice isPad])
        {
            [sSelf.popController dismissPopoverAnimated:YES];
        }
        else
        {
            [sSelf.presetPickerViewController dismissViewControllerAnimated:YES completion:NULL];
        }
    };

    [self showViewController:self.presetPickerViewController fromButton:self.presetPickerButton];
}

- (void)updatePresetPickerModel:(SCUAVSettingsEqualizerPresetModel *)model
{
    [self.presetPickerViewController updateModel:model];
}

- (void)showSendToWithModel:(SCUAVSettingsEqualizerSendToModel *)model
{
    self.sendToViewController = [[SCUAVSettingsEqualizerSendToTableViewController alloc] initWithModel:model];
    [self showViewController:self.sendToViewController fromButton:self.sendToButton];
}

- (void)updateSentToModel:(SCUAVSettingsEqualizerSendToModel *)model
{
    [self.sendToViewController updateModel:model];
}

- (void)showViewController:(UIViewController *)viewController fromButton:(SCUButton *)button
{
    SCUThemedNavigationViewController *navigationController = [[SCUThemedNavigationViewController alloc] initWithRootViewController:viewController];

    if ([UIDevice isPhone])
    {
        [self presentViewController:navigationController animated:YES completion:NULL];
    }
    else
    {
        self.popController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        self.popController.delegate = self;
        self.popController.backgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
        [self.popController presentPopoverFromRect:button.frame inView:self.actionsContainer permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popController = nil;
    self.presetPickerViewController = nil;
    self.sendToViewController = nil;
}

@end
