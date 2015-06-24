//
//  SCUCameraFullScreenViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraFullScreenViewControllerPad.h"
#import "SCUCameraFullScreenViewControllerPrivate.h"

@interface SCUCameraFullScreenViewControllerPad ()

@property NSArray *ptzPortraitConstraints;
@property NSArray *ptzLandscapeConstraints;

@property (weak) UIView *ptzContainer;

@end

@implementation SCUCameraFullScreenViewControllerPad

- (NSUInteger)ptzImageOffset
{
    return self.entity.hasPTZ ? (UIInterfaceOrientationIsLandscape([UIDevice deviceOrientation]) ? 256 : 113) : 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.contentView addSubview:self.dismissButton];
    [self.contentView addSubview:self.zoneName];
    [self.contentView addSubview:self.cameraName];
    [self.contentView addSubview:self.imageView];
	
    UIView *ptzContainer = [[UIView alloc] initWithFrame:CGRectZero];

    [ptzContainer addSubview:self.panTiltControls];
    [ptzContainer addSubview:self.zoomBrightnessControls];

    self.ptzContainer = ptzContainer;


    {
        NSDictionary *views = @{@"panTilt": self.panTiltControls,
                                @"zoomBrightness": self.zoomBrightnessControls};

        self.ptzPortraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                         metrics:nil
                                                                           views:views
                                                                         formats:@[@"|-(50)-[panTilt]-(>=50)-[zoomBrightness(300)]-(50)-|",
                                                                                   @"V:|[panTilt(175)]-(50)-|",
                                                                                   @"panTilt.width = panTilt.height",
                                                                                   @"V:|[zoomBrightness]-(50)-|"]];

        [self.contentView addSubview:ptzContainer];

        if (!self.entity.hasPTZ)
        {
            ptzContainer.hidden = YES;
            self.ptzPortraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0 metrics:nil views:views formats:@[@"|[panTilt][zoomBrightness]|",
                                                                                                                @"V:|[panTilt(0)]|"]];
        }

        self.ptzLandscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                             metrics:nil
                                                                               views:views
                                                                             formats:@[@"V:|[zoomBrightness(175)]-(50)-[panTilt(175)]|",
                                                                                       @"|[zoomBrightness]-(35)-|",
                                                                                       @"|[panTilt]-(35)-|",
                                                                                       @"panTilt.width = panTilt.height"]];
    }

    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                      metrics:@{@"ptzOffset": @([self ptzImageOffset])}
                                                                        views:@{@"dismiss": self.dismissButton,
                                                                                @"imageView": self.imageView,
                                                                                @"zoneName": self.zoneName,
                                                                                @"cameraName": self.cameraName,
                                                                                @"ptz": ptzContainer}
                                                                      formats:@[@"[dismiss]-(15)-|",
                                                                                @"|-(15)-[zoneName]",
                                                                                @"|-(20)-[cameraName]",
                                                                                @"|[imageView]|",
                                                                                @"|[ptz]|",
                                                                                @"V:|-(35)-[dismiss(25)]",
                                                                                @"V:|-(35)-[zoneName]-(2)-[cameraName]",
                                                                                @"V:[ptz]|",
                                                                                @"imageView.top = super.top",
                                                                                @"imageView.height = super.height - ptzOffset"]];

    if (self.entity.hasPTZ)
    {
        self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                           metrics:nil
                                                                             views:@{@"dismiss": self.dismissButton,
                                                                                     @"imageView": self.imageView,
                                                                                     @"zoneName": self.zoneName,
                                                                                     @"cameraName": self.cameraName,
                                                                                     @"ptz": ptzContainer}
                                                                           formats:@[@"[dismiss]-(15)-|",
                                                                                     @"V:|-(35)-[dismiss(25)]",
                                                                                     @"|-(15)-[zoneName]",
                                                                                     @"|-(20)-[cameraName]",
                                                                                     @"[ptz]|",
                                                                                     @"V:|-(192)-[ptz]",
                                                                                     @"V:|-(35)-[zoneName]-(2)-[cameraName]",
                                                                                     @"imageView.left = super.left",
                                                                                     @"imageView.width = 768",
                                                                                     @"imageView.top = super.top",
                                                                                     @"imageView.height = super.height + 75"]];
    }
    else
    {
        self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                           metrics:nil
                                                                             views:@{@"dismiss": self.dismissButton,
                                                                                     @"imageView": self.imageView,
                                                                                     @"zoneName": self.zoneName,
                                                                                     @"cameraName": self.cameraName}
                                                                           formats:@[@"[dismiss]-(15)-|",
                                                                                     @"V:|-(35)-[dismiss(25)]",
                                                                                     @"|-(15)-[zoneName]",
                                                                                     @"|-(20)-[cameraName]",
                                                                                     @"V:|-(35)-[zoneName]-(2)-[cameraName]",
                                                                                     @"imageView.centerX = super.centerX",
                                                                                     @"imageView.width = 768",
                                                                                     @"imageView.top = super.top",
                                                                                     @"imageView.height = super.height + 75"]];
    }


    [self setupConstraintsForOrientation:[UIDevice deviceOrientation]];
}

- (void)setupConstraintsForOrientation:(UIInterfaceOrientation)orientation
{
    [super setupConstraintsForOrientation:orientation];

    [self.ptzContainer removeConstraints:self.ptzPortraitConstraints];
    [self.ptzContainer removeConstraints:self.ptzLandscapeConstraints];

    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        [self.ptzContainer addConstraints:self.ptzPortraitConstraints];
    }
    else
    {
        [self.ptzContainer addConstraints:self.ptzLandscapeConstraints];
    }
}

@end
