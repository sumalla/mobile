//
//  SCUSceneCreationDialog.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCreationDialog.h"
#import "SCUAlertViewPrivate.h"
#import "SCUButton.h"

@interface SCUSceneCreationContentView : UIView

- (instancetype)initWithImage:(NSString *)image title:(NSString *)title andSubtitle:(NSString *)subtitle;

@property (weak) UIImageView *imageView;
@property (weak) UIActivityIndicatorView *spinnerView;

@end

@implementation SCUSceneCreationContentView

- (instancetype)initWithImage:(NSString *)image title:(NSString *)title andSubtitle:(NSString *)subtitle
{
    self = [super init];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:image tintColor:[[SCUColors shared] color04]]];
        imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
        self.imageView = imageView;

        UIActivityIndicatorView *spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:spinnerView];
        spinnerView.alpha = 0;
        self.spinnerView = spinnerView;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.text = title;
        titleLabel.textColor = [[SCUColors shared] color04];
        titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
        [self addSubview:titleLabel];

        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.text = subtitle;
        subtitleLabel.textColor = [[SCUColors shared] color03shade06];
        subtitleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];
        [self addSubview:subtitleLabel];

        for (UILabel *label in @[titleLabel, subtitleLabel])
        {
            label.textAlignment = NSTextAlignmentCenter;
        }

        NSDictionary *metrics = @{@"imageSize": @44,
                                  @"buffer": @20,
                                  @"topPadding": @55,
                                  @"bottomPadding": @35};

        NSDictionary *views = @{@"image": imageView,
                                @"title": titleLabel,
                                @"subtitle": subtitleLabel,
                                @"spinner": spinnerView};

        [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                      views:views
                                                                    formats:@[@"[image(imageSize)]",
                                                                              @"image.centerX = super.centerX",
                                                                              @"spinner.centerX = image.centerX",
                                                                              @"spinner.centerY = image.centerY",
                                                                              @"|-[title]-|",
                                                                              @"|-[subtitle]-|",
                                                                              @"V:|-topPadding-[image(imageSize)]-buffer-[title]-[subtitle]-bottomPadding-|"]]];
    }
    return self;
}

- (void)startSpinner
{
    [self.spinnerView startAnimating];

    [UIView animateWithDuration:.2 animations:^{
        self.imageView.alpha = 0;
    }];

    [UIView animateWithDuration:.3
                          delay:.05
                        options:0
                     animations:^{
            self.spinnerView.alpha = 1;
                     }
                     completion:NULL];
}

- (void)stopSpinner
{
    [self.spinnerView stopAnimating];

    [UIView animateWithDuration:.2 animations:^{
        self.spinnerView.alpha = 0;
    }];

    [UIView animateWithDuration:.3
                          delay:.05
                        options:0
                     animations:^{
                         self.imageView.alpha = 1;
                     }
                     completion:NULL];
}

@end

@interface SCUSceneCreationDialog ()

@property (weak) SCUSceneCreationContentView *captureCreationView;

@end

@implementation SCUSceneCreationDialog

- (instancetype)init
{
    self = [super initWithTitle:nil contentView:[self createContentView] buttonTitles:nil];
    
    if (self)
    {
        SCUButton *closeButton = [[SCUButton alloc] initWithImage:[UIImage sav_imageNamed:@"x" tintColor:[[SCUColors shared] color04]]];
        closeButton.selectedBackgroundColor = [UIColor clearColor];
        closeButton.selectedColor = [[SCUColors shared] color01];
        closeButton.backgroundColor = [UIColor clearColor];

        closeButton.pressAction = @selector(hide:);
        closeButton.target = self;
        
        [self.maskingView addSubview:closeButton];
        
        [self.maskingView sav_pinView:closeButton withOptions:SAVViewPinningOptionsToLeft withSpace:15];
        [self.maskingView sav_pinView:closeButton withOptions:SAVViewPinningOptionsToTop withSpace:50];
    }
    
    return self;
}

- (void)hide:(id)sender
{
    [self hideWithCompletion:nil];
}

#pragma mark - Private

+ (UIColor *)defaultBackgroundColor
{
    return [UIColor sav_colorWithRGBValue:0x242424];
}

+ (UIColor *)defaultButtonSeparatorColor
{
    return [UIColor clearColor];
}

+ (CGFloat)cornerRadius
{
    return 0;
}

- (CGFloat)buttonWidth
{
    return 200;
}

- (CGFloat)contentPadding
{
    return 2;
}

#pragma mark -

- (UIView *)createContentView
{
    SCUButton *create = [[SCUButton alloc] initWithContentView:[self addView]];
    create.releaseAction = @selector(create:);

    SCUSceneCreationContentView *captureCreationView = [self captureView];
    SCUButton *capture = [[SCUButton alloc] initWithContentView:captureCreationView];
    capture.releaseAction = @selector(capture:);

    self.captureCreationView = captureCreationView;

    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.vertical = YES;
    configuration.interSpace = 2;

    for (SCUButton *button in @[capture, create])
    {
        button.target = self;
        UIColor *color = [[SCUColors shared] color03shade03];
        button.backgroundColor = color;
        button.selectedBackgroundColor = color;
    }

    return [UIView sav_viewWithEvenlyDistributedViews:@[capture, create] withConfiguration:configuration];
}

- (SCUSceneCreationContentView *)captureView
{
    return [[SCUSceneCreationContentView alloc] initWithImage:@"capture" title:NSLocalizedString(@"Capture", nil) andSubtitle:NSLocalizedString(@"CURRENT SETTINGS", nil)];
}

- (SCUSceneCreationContentView *)addView
{
    return [[SCUSceneCreationContentView alloc] initWithImage:@"create" title:NSLocalizedString(@"Create", nil) andSubtitle:NSLocalizedString(@"NEW SCENE", nil)];
}

- (void)capture:(SCUButton *)capture
{
    if (self.startCaptureCallback)
    {
        self.startCaptureCallback();
    }
    [self.captureCreationView startSpinner];
}

- (void)create:(SCUButton *)sender
{
    [self callCallbackWithAction:SCUSceneCreationDialogActionCreate scene:nil];
}

- (void)captureCompleteWithScene:(SAVScene *)scene
{
    [self.captureCreationView stopSpinner];

    [self callCallbackWithAction:SCUSceneCreationDialogActionCapture scene:scene];
}

- (void)callCallbackWithAction:(SCUSceneCreationDialogAction)action scene:(SAVScene *)scene
{
    SAVWeakSelf;
    [self hideWithCompletion:^{
        SAVStrongWeakSelf;
        if (sSelf.sceneCallback)
        {
            sSelf.sceneCallback(action, scene);
        }
    }];
}

@end
