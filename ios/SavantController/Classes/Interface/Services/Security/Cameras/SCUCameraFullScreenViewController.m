//
//  SCUCameraFullScreenViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraFullScreenViewControllerPrivate.h"
#import "SCUBackgroundHandler.h"
#import "SCUButtonViewController.h"
#import "SCUPickerView.h"

#import <SavantControl/SavantControl.h>

@interface SCUCameraFullScreenViewController () <SCUPickerViewDelegate, SAVCameraEntityDelegate, SCUButtonCollectionViewControllerDelegate>

@end

@implementation SCUCameraFullScreenViewController

- (instancetype)initWithCameraEntity:(SAVCameraEntity *)entity
{
    self = [super initWithService:entity.service];
    if (self)
    {
        self.entity = entity;
        [self.entity addObserver:self];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	if (![UIDevice isPad])
    {
		SAVExchangeWithMethod([self class], @selector(supportedInterfaceOrientations), @selector(sav_supportedInterfaceOrientations), NO);
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (![UIDevice isPad])
    {
		SAVExchangeWithMethod([self class], @selector(sav_supportedInterfaceOrientations), @selector(supportedInterfaceOrientations), NO);
    }
}

- (NSUInteger)sav_supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.dismissButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"x"]];
    self.dismissButton.target = self;
    self.dismissButton.releaseAction = @selector(dismissButtonPressed:);
    self.dismissButton.selectedBackgroundColor = nil;
    self.dismissButton.backgroundColor = nil;
    self.dismissButton.selectedColor = [[SCUColors shared] color01];

    self.zoneName = [[UILabel alloc] init];
    self.zoneName.font = [UIFont fontWithName:@"Gotham-Light" size:32];
    self.zoneName.textColor = [UIColor sav_colorWithRGBValue:0x909090];
    self.zoneName.text = self.entity.zoneName;

    self.cameraName = [[UILabel alloc] init];
    self.cameraName.font = [UIFont fontWithName:@"Gotham-Light" size:19];
    self.cameraName.textColor = [[SCUColors shared] color04];
    self.cameraName.text = self.entity.label;
    self.cameraName.lineBreakMode = NSLineBreakByTruncatingTail;

    if ([self.entity.service.commands containsObject:@"TiltUp"])
    {
        SCUPickerView *panTiltControls = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationFourArrows];
        panTiltControls.selectedTintColor = [[SCUColors shared] color01];
        panTiltControls.holdTime = .1;
        panTiltControls.delegate = self;
        self.panTiltControls = panTiltControls;
    }
    else
    {
        self.panTiltControls = [[UIView alloc] init];
    }

    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    self.zoomBrightnessControls = [[UIView alloc] initWithFrame:CGRectZero];

    UIViewController *brightnessButtons = nil;

    if ([self.entity.service.commands containsObject:@"IrisOpen"])
    {
        SCUButtonViewController *buttons = [[SCUButtonViewController alloc] initWithCommands:@[@"CameraBrightnessDown", @"CameraBrightnessUp"]];
        buttons.delegate = self;
        brightnessButtons = buttons;
    }
    else
    {
        brightnessButtons = [[UIViewController alloc] init];
    }

    [self addChildViewController:brightnessButtons];
    [self.zoomBrightnessControls addSubview:brightnessButtons.view];

    UIViewController *zoomButtons = nil;

    if ([self.entity.service.commands containsObject:@"ZoomOut"])
    {
        SCUButtonViewController *buttons = [[SCUButtonViewController alloc] initWithCommands:@[@"CameraZoomOut", @"CameraZoomIn"]];
        buttons.delegate = self;
        buttons.tintColor = [[SCUColors shared] color01];
        zoomButtons = buttons;
    }
    else
    {
        zoomButtons = [[UIViewController alloc] init];
    }

    [self addChildViewController:zoomButtons];
    [self.zoomBrightnessControls addSubview:zoomButtons.view];

    [self.zoomBrightnessControls addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                       metrics:nil
                                                                                         views:@{@"brightness": brightnessButtons.view,
                                                                                                 @"zoom": zoomButtons.view}
                                                                                       formats:@[@"|[brightness]|",
                                                                                                 @"|[zoom]|",
                                                                                                 @"V:|[brightness(66)]-(10)-[zoom(66)]|"]]];
	
	
}

- (NSInteger)contentViewPadding
{
    return 0;
}

- (void)dismissButtonPressed:(SCUButton *)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.entity removeObserver:self];
}

#pragma mark - SCUButtonCollectionViewControllerDelegate

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    SAVServiceRequest *request = nil;

    if ([command hasSuffix:@"BrightnessDown"])
    {
        request = [self.entity requestForEvent:SAVEntityEvent_IrisClose value:nil];
    }
    else if ([command hasSuffix:@"BrightnessUp"])
    {
        request = [self.entity requestForEvent:SAVEntityEvent_IrisOpen value:nil];
    }
    else if ([command hasSuffix:@"ZoomOut"])
    {
        request = [self.entity requestForEvent:SAVEntityEvent_ZoomOut value:nil];
    }
    else if ([command hasSuffix:@"ZoomIn"])
    {
        request = [self.entity requestForEvent:SAVEntityEvent_ZoomIn value:nil];
    }

    if (request)
    {
        [self.model sendServiceRequest:request];
    }
}

- (NSUInteger)ptzImageOffset
{
    return 0;
}

- (BOOL)hasPTZ
{
    return self.entity.hasPTZ;
}

#pragma mark - PickerViewDelegate

- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction
{
    SAVServiceRequest *request = nil;
    switch (direction)
    {
        case SCUPickerViewDirectionUp:
            request = [self.entity requestForEvent:SAVEntityEvent_TiltUp value:nil];
            break;
        case SCUPickerViewDirectionDown:
            request = [self.entity requestForEvent:SAVEntityEvent_TiltDown value:nil];
            break;
        case SCUPickerViewDirectionLeft:
            request = [self.entity requestForEvent:SAVEntityEvent_PanLeft value:nil];
            break;
        case SCUPickerViewDirectionRight:
            request = [self.entity requestForEvent:SAVEntityEvent_PanRight value:nil];
            break;
    }

    if (request)
    {
        [self.model sendServiceRequest:request];
    }
}

#pragma mark - SAVCameraEntityDelegate

- (void)receivedImage:(UIImage *)image ofScale:(SAVCameraEntityScale)scale fromEntity:(SAVCameraEntity *)entity
{
    if (scale & SAVCameraEntityScale_Fullscreen)
    {
        self.imageView.image = image;
    }
}

@end
