//
//  SCUVolumeViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/11/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVolumeViewController.h"
#import "SCUVolumeModel.h"
#import "SCUButton.h"
#import "SCUSlider.h"
#import "SCUSlingshot.h"

@import SDK;

@interface SCUVolumeViewController () <SCUVolumeModelDelegate>

@property (nonatomic) SCUVolumeModel *model;
@property (nonatomic) SCUSlider *volumeSlider;
@property (nonatomic) SCUSlingshot *volumeSlingshot;
@property (nonatomic) SCUButton *incrementButton;
@property (nonatomic) SCUButton *decrementButton;
@property (nonatomic) SCUButton *muteButton;
@property (nonatomic) BOOL isTracking;
@property (nonatomic) SAVKVORegistration *tracking;
@property (nonatomic) SAVCoalescedTimer *slingshotTimer;
@property (nonatomic) BOOL showRoomVolume; // used to show the global volume as room based

@end

@implementation SCUVolumeViewController

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.model = [[SCUVolumeModel alloc] init];
    }

    return self;
}

- (instancetype)initWithServiceGroup:(SAVServiceGroup *)service
{
    self = [super init];

    if (self)
    {
        self.model = [[SCUVolumeModel alloc] initWithServiceGroup:service];
    }

    return self;
}

- (instancetype)initWithService:(SAVService *)service
{
    self = [super init];

    if (self)
    {
        self.model = [[SCUVolumeModel alloc] initWithService:service];
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.model.delegate = self;

    self.volumeSlider.fillColor = [[SCUColors shared] color01];
    self.volumeSlingshot.trackFillColor = [[SCUColors shared] color01];

    [self updateGlobalVolume];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.model.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.frame = CGRectZero;

    if (!self.model)
    {
        self.model = [[SCUVolumeModel alloc] init];
    }

    self.slingshotTimer = [[SAVCoalescedTimer alloc] init];

    self.model.delegate = self;

    UIImage *muteImage = [[UIImage sav_imageNamed:@"volumeMute" tintColor:[[SCUColors shared] color04]] scaleToSize:CGSizeMake(30, 30)];
    self.muteButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLightAccent image:muteImage];
    self.muteButton.tintImage = NO;
    self.muteButton.target = self.model;
    self.muteButton.contentMode = UIViewContentModeCenter;
    self.muteButton.releaseAction = @selector(mute);
    [self.view addSubview:self.muteButton];
    
    UIView *divider = [[UIView alloc] initWithFrame:CGRectZero];
    divider.backgroundColor = [[SCUColors shared] color03shade05];
    [self.view addSubview:divider];

    [self.view sav_pinView:divider withOptions:SAVViewPinningOptionsCenterY];
    [self.view sav_setHeight:.65 forView:divider isRelative:YES];
    [self.view sav_setWidth:[UIScreen screenPixel] forView:divider isRelative:NO];

    self.decrementButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLightAccent image:[UIImage sav_imageNamed:@"VolumeMinus" tintColor:[[SCUColors shared] color04]]];
    self.decrementButton.tintImage = NO;
    self.decrementButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:30];
    self.decrementButton.target = self.model;
    self.decrementButton.releaseAction = @selector(decreaseVolume);
    self.decrementButton.holdTime = 0.25;
    [self.view addSubview:self.decrementButton];

    self.incrementButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLightAccent image:[UIImage sav_imageNamed:@"VolumePlus" tintColor:[[SCUColors shared] color04]]];
    self.incrementButton.tintImage = NO;
    self.incrementButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:30];
    self.incrementButton.target = self.model;
    self.incrementButton.releaseAction = @selector(increaseVolume);
    self.incrementButton.holdTime = 0.25;
    [self.view addSubview:self.incrementButton];

    CGFloat sliderWidth = 300;

    if (self.isFullWidth && [UIDevice isPad])
    {
        sliderWidth = 850;
    }

    UIView *dumbView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:dumbView];

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"space": @9, @"smallSpace": @2, @"mediumSpace": @4, @"sliderWidth": @(sliderWidth)}
                                                                       views:@{@"increment": self.incrementButton, @"decrement": self.decrementButton, @"mute" : self.muteButton, @"divider" : divider, @"dumbView": dumbView}
                                                                     formats:@[@"|-space-[mute]-smallSpace-[divider]-smallSpace-[decrement]-(0)-[dumbView(>=20@1000,<=sliderWidth@1000,==sliderWidth@500)]-(0)-[increment]-mediumSpace-|",
                                                                               @"V:|[increment]|",
                                                                               @"V:|[decrement]|",
                                                                               @"V:|[mute]|"
                                                                               ]]];
}

- (void)setServiceGroup:(SAVServiceGroup *)serviceGroup
{
    self.globalVolume = YES;
    self.model.serviceGroup = serviceGroup;
    [self.volumeSlingshot updateService:self.model.service];
}

- (SAVServiceGroup *)serviceGroup
{
    return self.model.serviceGroup;
}

- (void)setService:(SAVService *)service
{
    self.globalVolume = service.zoneName ? NO : YES;
    self.model.service = service;
    [self.volumeSlingshot updateService:service];
}

- (SAVService *)service
{
    return self.model.service;
}

- (void)setGlobalVolume:(BOOL)globalVolume
{
    self.model.globalVolume = globalVolume;

    [self updateGlobalVolume];
}

- (BOOL)isGlobalVolume
{
    return self.model.isGlobalVolume;
}

- (id<SCUViewModel>)viewModel
{
    return (id<SCUViewModel>)self.model;
}

- (void)volumeChanged:(CGFloat)value
{
    [self.model setVolume:@(value)];
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.view.userInteractionEnabled = enabled;
    self.view.alpha = enabled ? 1 : .4;
}

#pragma mark - SCUVolumeModel Delegate

- (void)didUpdateVolume:(NSInteger)volume
{
    [self.volumeSlider setValue:volume animated:!self.ignoreFirstAnimation];
    self.ignoreFirstAnimation = NO;
}

- (void)didUpdateMuteStatus:(BOOL)muted
{
    self.muteButton.selected = muted;
}

- (void)didUpdateDiscreteVolumeStatus:(BOOL)discreteVolumeAvailable
{
    if (discreteVolumeAvailable == self.isDiscrete)
    {
        return;
    }
    else
    {
        self.isDiscrete = discreteVolumeAvailable;
    }

    [self showCorrectSlider];
}

- (void)updateGlobalVolume
{
    self.volumeSlingshot.master = self.isGlobalVolume;
    [self showCorrectSlider];
}

- (void)showGlobalRoomVolume
{
    self.showRoomVolume = YES;
}

- (void)hideGlobalRoomVolume
{
    self.showRoomVolume = NO;
}

- (void)setDisallowGlobalRoomVolume:(BOOL)disallowGlobalRoomVolume
{
    _disallowGlobalRoomVolume = disallowGlobalRoomVolume;

    [self hideGlobalRoomVolume];
}

- (void)setShowRoomVolume:(BOOL)showRoomVolume
{
    if (self.disallowGlobalRoomVolume)
    {
        showRoomVolume = NO;
    }

    _showRoomVolume = showRoomVolume;

    if (self.isGlobalVolume)
    {
        _showRoomVolume = showRoomVolume;

        if (self.showRoomVolume && [[self.model.serviceGroup.activeServices firstObject] discreteVolume])
        {
            [self showSlider];
        }
        else
        {
            [self showSlingshot];
        }
    }
}

- (void)showSlider
{
    [self initializeVolumeSliderIfNecessary];
    self.volumeSlider.hidden = NO;
    self.volumeSlingshot.hidden = YES;
}

- (void)showSlingshot
{
    [self initializeSlingshotIfNecessary];
    self.volumeSlider.hidden = YES;
    self.volumeSlingshot.hidden = NO;
}

- (void)initializeVolumeSliderIfNecessary
{
    if (!self.volumeSlider)
    {
        self.volumeSlider = [[SCUSlider alloc] initWithFrame:CGRectZero];
        self.volumeSlider.minimumValue = 0.0;
        self.volumeSlider.maximumValue = 50.0;
        self.volumeSlider.delta = 1;
        self.volumeSlider.trackColor = [[SCUColors shared] color03shade08];
        self.volumeSlider.callbackTimeInterval = .05;
        self.volumeSlider.showsIndicator = YES;

        SAVWeakSelf;
        self.volumeSlider.callback = ^(SCUSlider *slider) {
            SAVStrongWeakSelf;
            [sSelf volumeChanged:slider.value];
            [sSelf callInteractionHandler];
        };

        self.tracking = [[SAVKVORegistration alloc] initWithObserver:self target:self.volumeSlider selector:@selector(tracking) handler:^(NSDictionary *changeDictionary) {
            wSelf.isTracking = wSelf.volumeSlider.isTracking;
        }];

        [self.view addSubview:self.volumeSlider];

        [self.view sav_pinView:self.volumeSlider withOptions:SAVViewPinningOptionsToRight ofView:self.decrementButton withSpace:9];
        [self.view sav_pinView:self.volumeSlider withOptions:SAVViewPinningOptionsToLeft ofView:self.incrementButton withSpace:4];
        [self.view sav_setHeight:1 forView:self.volumeSlider isRelative:1];
    }
}

- (void)initializeSlingshotIfNecessary
{
    if (!self.volumeSlingshot)
    {
        self.volumeSlingshot = [[SCUSlingshot alloc] initWithFrame:CGRectZero andService:self.service];
        self.volumeSlingshot.callbackTimeInterval = 1.0;
        self.volumeSlingshot.minimumValue = 5;
        self.volumeSlingshot.maximumValue = 5;
        self.volumeSlingshot.trackColor = [[SCUColors shared] color03shade05];
        self.volumeSlingshot.showsIndicator = YES;

        SAVWeakSelf;
        self.volumeSlingshot.callback = ^(SCUSlingshot *slingshot, NSInteger value){
            SAVStrongWeakSelf;
            [sSelf.model sendCommandFromSlingshot:slingshot withValue:value];
            [sSelf callInteractionHandler];
        };

        self.volumeSlingshot.releaseCallback = ^(SCUSlingshot *slingshot) {
            [wSelf.model sendReleaseCommandFromSlingshot:slingshot];
        };
        
        [self.view addSubview:self.volumeSlingshot];

        [self.view sav_pinView:self.volumeSlingshot withOptions:SAVViewPinningOptionsToRight ofView:self.decrementButton withSpace:9];
        [self.view sav_pinView:self.volumeSlingshot withOptions:SAVViewPinningOptionsToLeft ofView:self.incrementButton withSpace:4];
        [self.view sav_setHeight:1 forView:self.volumeSlingshot isRelative:1];
    }
}

- (void)showCorrectSlider
{
    if (!self.forceSlingshot && ((self.isDiscrete && !self.isGlobalVolume) || (self.isDiscrete && self.showRoomVolume)))
    {
        [self showSlider];
    }
    else
    {
        [self showSlingshot];
    }
}

- (void)callInteractionHandler
{
    if (self.sliderInteractionHandler)
    {
        self.sliderInteractionHandler();
    }
}

@end
