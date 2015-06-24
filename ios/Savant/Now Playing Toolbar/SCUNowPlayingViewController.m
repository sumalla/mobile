//
//  SCUNowPlayingToolbar.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingViewController.h"
#import "SCUNowPlayingViewControllerPrivate.h"
#import "SCUPassthroughViewController.h"
#import "SCUMediaServiceViewController.h"
#import "SCUButton.h"
@import SDK;

@interface SCUNowPlayingViewController () <SCUArtworkImageViewDelegate>

@property (nonatomic) NSString *artist;
@property (nonatomic) NSString *song;
@property (nonatomic) NSString *album;
@property (nonatomic) BOOL hidden;
@property (nonatomic) SAVCoalescedTimer *labelTimer;
@property (nonatomic) NSString *lastArtworkValue;
@property (nonatomic) SAVKVORegistration *artworkWatch;
@property (nonatomic) BOOL paused;
@property (nonatomic) SAVKVORegistration *thumbsDownFrameRegistration;
@property (nonatomic) SAVKVORegistration *thumbsUpFrameRegistration;
@property (nonatomic) SCUButton *nowPlayingButton;

@end

@implementation SCUNowPlayingViewController

- (instancetype)initWithService:(SAVService *)service serviceGroup:(SAVServiceGroup *)serviceGroup
{
    self = [super init];

    if (self)
    {
        self.model = [[SCUNowPlayingModel alloc] initWithService:service serviceGroup:serviceGroup delegate:self];
        self.labelTimer = [[SAVCoalescedTimer alloc] init];
        self.labelTimer.timeInverval = 0.1;
    }

    return self;
}

- (SCUButton *)buttonWithTransportButtonType:(SCUNowPlayingModelTransportButtonType)buttonType
{
    NSString *imageName = nil;
    SCUButtonStyle style = SCUButtonStyleLight;

    switch (buttonType)
    {
        case SCUNowPlayingModelTransportButtonTypePrevious:
            imageName = @"Previous";
            break;
        case SCUNowPlayingModelTransportButtonTypeNext:
            imageName = @"Next";
            break;
        case SCUNowPlayingModelTransportButtonTypePlay:
        case SCUNowPlayingModelTransportButtonTypePlayStatic:
            imageName = @"Play";
            break;
        case SCUNowPlayingModelTransportButtonTypePause:
            imageName = @"Pause";
            break;
        case SCUNowPlayingModelTransportButtonTypePlayPause:
            imageName = @"PlayPause";
            break;
        case SCUNowPlayingModelTransportButtonTypeShuffle:
            imageName = @"shuffle";
            style = SCUButtonStyleLightAccent;
            break;
        case SCUNowPlayingModelTransportButtonTypeRepeat:
            imageName = @"repeat";
            style = SCUButtonStyleLightAccent;
            break;
        case SCUNowPlayingModelTransportButtonTypeFastForward:
            imageName = @"FastForward";
            break;
        case SCUNowPlayingModelTransportButtonTypeThumbsDown:
            imageName = @"ThumbsDown";
            break;
        case SCUNowPlayingModelTransportButtonTypeThumbsUp:
            imageName = @"ThumbsUp";
            break;
        case SCUNowPlayingModelTransportButtonTypeRewind:
            imageName = @"Rewind";
            break;
    }

    SCUButton *button = [[SCUButton alloc] initWithStyle:style image:[UIImage sav_imageNamed:imageName tintColor:[[SCUColors shared] color04]]];
    button.tag = buttonType;
    button.target = self;
    button.releaseAction = @selector(didTapTransportButton:);
    button.tintImage = NO;
    return button;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    self.artwork = [[SCUArtworkImageView alloc] initWithFrame:CGRectZero];
    self.artwork.image = [UIImage imageNamed:@"No_Album_Art"];
    self.artwork.delegate = self;

    self.elapsedTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.elapsedTimeLabel.textColor = [[SCUColors shared] color04];
    self.elapsedTimeLabel.font = [UIFont fontWithName:@"Gotham-Book" size:15.0f];
    self.elapsedTimeLabel.textAlignment = NSTextAlignmentCenter;

    self.progressSlider = [[SCUSlider alloc] initWithStyle:self.sliderStyle frame:CGRectZero];
    self.progressSlider.hidden = YES;
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 100;
    self.progressSlider.fillColor = [[SCUColors shared] color01];
    self.progressSlider.trackColor = [[SCUColors shared] color03shade04];
    self.progressSlider.continuous = NO;

    SAVWeakSelf;
    self.progressSlider.callback = ^(SCUSlider *slider) {
        [wSelf progressDidChange:slider.value];
    };

    self.remainingTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.remainingTimeLabel.textColor = [[SCUColors shared] color04];
    self.remainingTimeLabel.font = [UIFont fontWithName:@"Gotham-Book" size:15.0f];

    self.remainingTimeLabel.textAlignment = NSTextAlignmentCenter;

    self.label = [[SCUMarqueeLabel alloc] initWithFrame:CGRectZero];
    self.label.textColor = [[SCUColors shared] color01];

    if (self.wantsArtworkBorderAndGradient)
    {
        self.artworkGradient = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[UIColor clearColor], [[[SCUColors shared] color03] colorWithAlphaComponent:.8]]];
        self.artworkGradient.startPoint = CGPointMake(0.5, .6);
        self.artworkGradient.endPoint = CGPointMake(.5, 1);
        self.artworkGradient.borderWidth = [UIScreen screenPixel];
        self.artworkGradient.borderColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.15];
        [self.artwork addSubview:self.artworkGradient];

        UIImage *serviceIcon = [UIImage sav_imageNamed:self.model.service.iconName tintColor:[[SCUColors shared] color04]];

        self.servicesFirst = [[SCUButton alloc] initWithStyle:SCUButtonStyleLightAccent];
        self.servicesFirst.tintImage = NO;
        self.servicesFirst.target = self;
        self.servicesFirst.releaseAction = @selector(presentService);
        self.servicesFirst.hidden = !self.showServicesFirstButton;
        self.servicesFirst.frame = CGRectMake(0, 0, 32, 32);

        if (serviceIcon)
        {
            self.servicesFirst.image = serviceIcon;
        }
        else
        {
            self.servicesFirst.title = self.model.service.displayName;
        }

        [self.artwork addSubview:self.servicesFirst];

        SAVWeakSelf;
        self.artworkWatch = [[SAVKVORegistration alloc] initWithObserver:self target:self.artwork selector:@selector(image) handler:^(NSDictionary *changeDictionary) {
            [wSelf calculateArtworkDimensions];
        }];
    }

    self.shuffleButton = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeShuffle];
    self.repeatButton = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeRepeat];
    self.thumbsDown = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeThumbsDown];
    self.thumbsDown.hidden = YES;
    self.thumbsUp = [self buttonWithTransportButtonType:SCUNowPlayingModelTransportButtonTypeThumbsUp];
    self.thumbsUp.hidden = YES;
    self.nowPlayingButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleLightAccent image:[UIImage sav_imageNamed:@"security-list" tintColor:[[SCUColors shared] color04]]];
    self.nowPlayingButton.tintImage = NO;
    self.nowPlayingButton.hidden = !self._wantsNowPlayingButton;
    self.nowPlayingButton.target = self;
    self.nowPlayingButton.releaseAction = @selector(showNowPlaying);

    if (self._wantsNowPlayingButton)
    {
        [self.artwork addSubview:self.nowPlayingButton];
    }

    if (self.wantsShuffleAndRepeatInArtwork)
    {
        [self.artwork addSubview:self.shuffleButton];
        [self.artwork addSubview:self.repeatButton];
    }

    dispatch_async_main(^{
        if (self.matchThumbsToShuffleAndRepeat)
        {
            SAVWeakSelf;
            self.thumbsDownFrameRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:self.shuffleButton selector:@selector(frame) handler:^(NSDictionary *changeDictionary) {
                SAVStrongWeakSelf;
                sSelf.thumbsDown.frame = sSelf.shuffleButton.frame;
            }];

            self.thumbsUpFrameRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:self.shuffleButton selector:@selector(frame) handler:^(NSDictionary *changeDictionary) {
                SAVStrongWeakSelf;
                sSelf.thumbsUp.frame = sSelf.repeatButton.frame;
            }];
        }
    });

    self.views = @{@"elapsed": self.elapsedTimeLabel,
                   @"progress": self.progressSlider,
                   @"remaining": self.remainingTimeLabel,
                   @"label": self.label,
                   @"artwork": self.artwork,
                   @"shuffle": self.shuffleButton,
                   @"repeat": self.repeatButton};

    [self addSubviews];

    self.visibleConstraints = [self layoutViews];

    if ([self.visibleConstraints count])
    {
        [self.view addConstraints:self.visibleConstraints];
    }

    if (!self.visible)
    {
        [self toolbarShouldHide];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.wantsArtworkBorderAndGradient)
    {
        [self calculateArtworkDimensions];
    }
}

#pragma mark - Methods to subclass

- (void)calculateArtworkDimensions
{
    [self.view layoutIfNeeded];

    CGFloat padding = [UIDevice isPad] ? 25 : 15;

    CGRect nowPlayingFrame = self.servicesFirst.frame;
    nowPlayingFrame.origin.x = CGRectGetWidth(self.artwork.frame) - padding - CGRectGetHeight(nowPlayingFrame);
    nowPlayingFrame.origin.y = CGRectGetHeight(self.artwork.frame) - padding - CGRectGetHeight(nowPlayingFrame);

    CGRect shuffleFrame = self.shuffleButton.frame;
    shuffleFrame.size.height = nowPlayingFrame.size.height;
    shuffleFrame.size.width = nowPlayingFrame.size.width;
    shuffleFrame.origin.x = padding;

    CGRect repeatFrame = self.repeatButton.frame;
    repeatFrame.size.height = nowPlayingFrame.size.height;
    repeatFrame.size.width = nowPlayingFrame.size.width;
    repeatFrame.origin.x = padding + CGRectGetMaxX(shuffleFrame) + 8;

    CGRect nowPlayingButtonFrame = self.nowPlayingButton.frame;
    nowPlayingButtonFrame.size.height = nowPlayingFrame.size.height;
    nowPlayingButtonFrame.size.width = nowPlayingFrame.size.width;

    CGFloat widthPadding = 0;
    CGFloat heightPadding = 0;
    CGFloat artworkWidth = 0;
    CGFloat artworkHeight = 0;

    //-------------------------------------------------------------------
    // Position views relative to edge of artwork image
    //-------------------------------------------------------------------
    if (self.artwork.image)
    {
        CGFloat heightRatio = CGRectGetHeight(self.artwork.frame) / self.artwork.image.size.height;
        CGFloat widthRatio = CGRectGetWidth(self.artwork.frame) / self.artwork.image.size.width;
        CGFloat ratio = heightRatio > widthRatio ? widthRatio : heightRatio;

        artworkWidth = ratio * self.artwork.image.size.width;
        artworkHeight = ratio * self.artwork.image.size.height;

        widthPadding = (CGRectGetWidth(self.artwork.frame) - artworkWidth) / 2;
        heightPadding = (CGRectGetHeight(self.artwork.frame) - artworkHeight) / 2;

        CGRect artworkFrame = CGRectIntegral(CGRectMake(widthPadding, heightPadding, artworkWidth, artworkHeight));
        
        self.artworkGradient.frame = artworkFrame;
        self.artworkGradient.hidden = NO;
        [self.artworkGradient setNeedsDisplay];

        nowPlayingFrame.origin.y -= heightPadding;
        nowPlayingFrame.origin.x -= widthPadding;

        if (self.wantsShuffleAndRepeatInArtwork)
        {
            if (CGRectGetMaxX(nowPlayingFrame) > 0)
            {
                shuffleFrame.origin.x = CGRectGetMaxX(self.artwork.bounds) - ABS(CGRectGetMaxX(nowPlayingFrame));
                repeatFrame.origin.x = CGRectGetMaxX(shuffleFrame) + 8;
            }

            shuffleFrame.origin.y = nowPlayingFrame.origin.y;
            repeatFrame.origin.y = nowPlayingFrame.origin.y;
        }

        nowPlayingButtonFrame.origin.y = nowPlayingFrame.origin.y;

        if (self._wantsNowPlayingButton)
        {
            if (self.servicesFirst.hidden)
            {
                nowPlayingButtonFrame = nowPlayingFrame;
            }
            else
            {
                nowPlayingButtonFrame.origin.x = CGRectGetMinX(nowPlayingFrame) - CGRectGetWidth(nowPlayingButtonFrame) - 8;
            }
        }
    }
    else
    {
        self.artworkGradient.hidden = YES;
    }

    if ([self.artwork.image isEqual:[UIImage imageNamed:@"No_Album_Art"]])
    {
        self.artworkGradient.hidden = YES;
    }
    
    self.servicesFirst.frame = CGRectIntegral(nowPlayingFrame);
    self.shuffleButton.frame = CGRectIntegral(shuffleFrame);
    self.repeatButton.frame = CGRectIntegral(repeatFrame);
    self.nowPlayingButton.frame = CGRectIntegral(nowPlayingButtonFrame);
}

- (id<SCUViewModel>)viewModel
{
    return (id<SCUViewModel>)self.model;
}

- (void)addSubviews
{
    ;
}

- (NSArray *)layoutViews
{
    return nil;
}

- (BOOL)wantsSongInLabel
{
    return YES;
}

- (BOOL)wantsArtistInLabel
{
    return YES;
}

- (BOOL)wantsAlbumInLabel
{
    return YES;
}

- (UIFont *)labelFont
{
    return [UIFont fontWithName:@"Gotham" size:16];
}

- (BOOL)wantsArtworkBorderAndGradient
{
    return NO;
}

- (BOOL)wantsShuffleAndRepeatInArtwork
{
    return NO;
}

- (BOOL)matchThumbsToShuffleAndRepeat
{
    return NO;
}

- (BOOL)wantsNowPlayingButton
{
    return NO;
}

- (BOOL)_wantsNowPlayingButton
{
    BOOL wantsNowPlayingButton = [self wantsNowPlayingButton];

    if (wantsNowPlayingButton && (![self.service.serviceId containsString:@"LIVEMEDIAQUERY_SAVANTMEDIA"] || [Savant control].isDemoSystem))
    {
        wantsNowPlayingButton = NO;
    }

    return wantsNowPlayingButton;
}

- (SCUSliderStyle)sliderStyle
{
    return SCUSliderStylePlain;
}

#pragma mark - SCUNowPlayingModelDelegate methods

- (void)toolbarShouldHide
{
    [self toggleHidden:YES];
}

- (void)toolbarShouldShow
{
    [self toggleHidden:NO];
}

- (void)pauseStatusDidUpdateWithValue:(NSNumber *)value
{
    self.paused = [value boolValue];
}

- (void)artistDidUpdateWithValue:(NSString *)value
{
    self.artist = value;
    SAVWeakSelf;
    [self.labelTimer addWorkWithKey:@"label" work:^{
        [wSelf updateLabel];
    }];
}

- (void)songDidUpdateWithValue:(NSString *)value
{
    self.song = value;
    SAVWeakSelf;
    [self.labelTimer addWorkWithKey:@"label" work:^{
        [wSelf updateLabel];
    }];
}

- (void)albumDidUpdateWithValue:(NSString *)value
{
    self.album = value;
    SAVWeakSelf;
    [self.labelTimer addWorkWithKey:@"label" work:^{
        [wSelf updateLabel];
    }];
}

- (void)repeatDidUpdateWithValue:(NSNumber *)value
{
    self.repeatButton.selected = [value boolValue];
}

- (void)shuffleDidUpdateWithValue:(NSNumber *)value
{
    self.shuffleButton.selected = [value boolValue];
}

- (void)elapsedTimeDidUpdateWithValue:(NSString *)value
{
    self.elapsedTimeLabel.text = value;
}

- (void)progressTimeDidUpdateWithValue:(NSString *)value
{
    CGFloat progress = [value floatValue];

    if (progress <= 0)
    {
        self.progressSlider.hidden = YES;
    }
    else
    {
        self.progressSlider.hidden = NO;
    }

    self.progressSlider.value = [value floatValue];
}

- (void)remainingTimeDidUpdateWithValue:(NSString *)value
{
    self.remainingTimeLabel.text = value;
}

- (void)artworkURLDidUpdate:(NSString *)value
{
    if (![value isEqualToString:self.lastArtworkValue])
    {
        self.lastArtworkValue = value;

        [[Savant images] imageForKey:value
                                                         type:SAVImageTypeLMQNowPlayingArtwork
                                                         size:SAVImageSizeOriginal
                                                      blurred:NO
                                         requestingIdentifier:self
                                          componentIdentifier:self.model.service.component
                                            completionHandler:^(UIImage *image, BOOL isDefault) {
                                                self.artwork.image = image;
                                            }];
    }
}

- (void)playTypeDidUpdateWithValue:(NSNumber *)value
{
    if (self.matchThumbsToShuffleAndRepeat)
    {
        self.shuffleButton.hidden = [value boolValue];
        self.repeatButton.hidden = [value boolValue];
        self.thumbsDown.hidden = ![value boolValue];
        self.thumbsUp.hidden = ![value boolValue];

        self.thumbsDown.frame = self.shuffleButton.frame;
        self.thumbsUp.frame = self.repeatButton.frame;
    }
}

#pragma mark - SCUArtworkImageViewDelegate methods

- (void)artworkViewWasTapped:(SCUArtworkImageView *)artworkView
{
    if (self.artworkTappedBlock)
    {
        self.artworkTappedBlock();
    }
}

#pragma mark -

- (void)toggleHidden:(BOOL)hidden
{
    if (self.hidden != hidden)
    {
        self.hidden = hidden;

        if (self.hidden)
        {
            self.visible = NO;
        }
        else
        {
            self.visible = YES;
        }
    }
}

- (void)progressDidChange:(CGFloat)value
{
    [self.model sendCommand:@"Seek" withArguments:@{@"ProgressValue": @(value)}];
}

- (void)updateLabel
{
    NSMutableAttributedString *baseString = [[NSMutableAttributedString alloc] init];

    if ([self wantsSongInLabel] && [self.song length])
    {
        NSString *strippedSong = [self trimmedStringFromString:self.song];

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:strippedSong
                                                                           attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color01]}]];
    }

    if ([self wantsArtistInLabel] && [self.artist length])
    {
        NSString *strippedArtist = [self trimmedStringFromString:self.artist];
        NSString *artist = [baseString length] ? [NSString stringWithFormat:@" %@", strippedArtist] : strippedArtist;
        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:artist
                                                                           attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04]}]];
    }

    if ([self wantsAlbumInLabel] && [self.album length])
    {
        NSString *strippedAlbum = [self trimmedStringFromString:self.album];
        NSString *album = [baseString length] ? [NSString stringWithFormat:@" %@%@ ", (([self wantsArtistInLabel] && [self.artist length]) ? @"- " : @""), strippedAlbum] : strippedAlbum;

        [baseString appendAttributedString:[[NSAttributedString alloc] initWithString:album
                                                                           attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color04]}]];
    }

    [baseString addAttribute:NSFontAttributeName value:[self labelFont] range:NSMakeRange(0, [baseString length])];

    self.label.attributedText = [baseString copy];
}

- (void)didTapTransportButton:(SCUButton *)button
{
    BOOL state = button.selected;
    if (button.tag == SCUNowPlayingModelTransportButtonTypePlay)
    {
        state = self.paused;
    }

    [self.model sendCommandWithTransportButtonType:button.tag forState:state];
}

- (void)showNowPlaying
{
    SCUMediaServiceViewController *media = [[SCUMediaServiceViewController alloc] initWithService:self.service];
    media.nowPlaying = YES;
    SCUPassthroughViewController *passthrough = [[SCUPassthroughViewController alloc] initWithRootViewController:media];
    [self.navigationController pushViewController:passthrough animated:YES];
}

- (NSString *)trimmedStringFromString:(NSString *)string
{
    NSString *strippedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *components = [strippedString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if ([components count])
    {
        return [components componentsJoinedByString:@" "];
    }
    else
    {
        return strippedString;
    }
}

- (SAVService *)service
{
    return self.model.service;
}

#pragma mark - Show Service

- (void)setShowServicesFirstButton:(BOOL)showServicesFirstButton
{
    _showServicesFirstButton = showServicesFirstButton;

    self.servicesFirst.hidden = !showServicesFirstButton;
}

- (void)presentService
{
    //TODO: Present service
}

@end
