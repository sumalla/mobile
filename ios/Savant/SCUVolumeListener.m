//
//  SCUVolumeListener.m
//  SavantController
//
//  Created by Cameron Pulsford on 1/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUVolumeListener.h"
@import Extensions;
@import MediaPlayer;
@import AVFoundation;

@interface SCUVolumeListener ()

@property (nonatomic) MPVolumeView *volumeView;
@property (nonatomic) UISlider *hackSlider;
@property (nonatomic) SAVKVORegistration *volumeRegistration;
@property (nonatomic) id secondaryAudioObserver;
@property (nonatomic) float savedVolume;
@property (nonatomic) float initialVolume;
@property (nonatomic, weak) NSTimer *startTimer;

@end

@implementation SCUVolumeListener

- (void)dealloc
{
    [self stopListening];
}

- (void)setListening:(BOOL)listening
{
    if (![NSThread isMainThread])
    {
        [NSException raise:NSInternalInconsistencyException format:@"You may only interact with an SCUVolumeListener from the main thread"];
        return;
    }
    
    if (_listening != listening)
    {
        _listening = listening;
        
#if !TARGET_IPHONE_SIMULATOR
        if (listening)
        {
            [self startListening];
        }
        else
        {
            [self stopListening];
        }
#endif
    }
}

- (void)startListening
{
    [self refreshVolumeView];
    
    NSError *error = nil;
    
    if (![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&error])
    {
        return;
    }
    
    if (![[AVAudioSession sharedInstance] setActive:YES error:&error])
    {
        return;
    }
    
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 0, 0)];
    
    for (UISlider *slider in [self.volumeView sav_allSubviews])
    {
        if ([slider isKindOfClass:[UISlider class]])
        {
            self.hackSlider = slider;
            break;
        }
    }
    
    if (!self.hackSlider)
    {
        [self stopListening];
        return;
    }
    
    self.volumeView.showsRouteButton = NO;
    [[UIView sav_topView] addSubview:self.volumeView];
    self.volumeView.hidden = [AVAudioSession sharedInstance].secondaryAudioShouldBeSilencedHint;
    
    SAVWeakSelf;
    self.secondaryAudioObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        wSelf.volumeView.hidden = [[note userInfo][AVAudioSessionSilenceSecondaryAudioHintTypeKey] unsignedIntegerValue] == AVAudioSessionSilenceSecondaryAudioHintTypeBegin;
    }];
    
    self.startTimer = [NSTimer sav_scheduledBlockWithDelay:.5 block:^{
        SAVStrongWeakSelf;
        sSelf.savedVolume = [AVAudioSession sharedInstance].outputVolume;
        [sSelf prepareVolume];
        
        self.volumeRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:[AVAudioSession sharedInstance] selector:@selector(outputVolume) options:NSKeyValueObservingOptionNew handler:^(NSDictionary *changeDictionary) {
            [wSelf handleVolumeUpdate:[changeDictionary[NSKeyValueChangeNewKey] floatValue]];
        }];
    }];
}

- (void)stopListening
{
    if (self.secondaryAudioObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.secondaryAudioObserver];
    }
    
    [self.startTimer invalidate];
    self.startTimer = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:NULL];
    [self.volumeView removeFromSuperview];
    self.volumeView = nil;
    self.hackSlider = nil;
    self.savedVolume = 0;
    self.initialVolume = 0;
    self.volumeRegistration = nil;
}

- (void)prepareVolume
{
    if (self.savedVolume == 0)
    {
        self.initialVolume = 0.0001;
    }
    else if (self.savedVolume == 1)
    {
        self.initialVolume = 0.9999;
    }
    else
    {
        self.initialVolume = self.savedVolume;
    }
    
    self.hackSlider.value = self.initialVolume;
}

- (void)refreshVolumeView
{
    //fake moving to top view
    [self.volumeView willMoveToSuperview:[UIView sav_topView]];
    [self.volumeView didMoveToSuperview];
}

- (void)handleVolumeUpdate:(float)newVolume
{
    if ([AVAudioSession sharedInstance].secondaryAudioShouldBeSilencedHint)
    {
        return;
    }
    
    if (newVolume == self.initialVolume)
    {
        return;
    }
    
    BOOL volumeWentUp = YES;
    
    if (newVolume < self.initialVolume)
    {
        volumeWentUp = NO;
    }
    
    self.hackSlider.value = self.initialVolume;
    
    if (volumeWentUp)
    {
        [self.delegate volumeListenerDidIncrement:self];
    }
    else
    {
        [self.delegate volumeListenerDidDecrement:self];
    }
}

- (BOOL)isEnabled
{
    return self.volumeView.hidden ? NO : YES;
}

@end
