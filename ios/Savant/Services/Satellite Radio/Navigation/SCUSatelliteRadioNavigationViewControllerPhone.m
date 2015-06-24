//
//  SCUSatelliteRadioNavigationViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 8/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioNavigationViewControllerPhone.h"
#import "SCUSatelliteRadioNavigationViewControllerPrivate.h"

@implementation SCUSatelliteRadioNavigationViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *topBar = [[UIView alloc] initWithFrame:CGRectZero];
    topBar.backgroundColor = [[SCUColors shared] color03shade01];
    [topBar addSubview:self.channelPicker];
    [topBar addSubview:self.categoryPicker];

    UIView *rightPad = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *centerRightPad = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *centerLeftPad = [[UIView alloc] initWithFrame:CGRectZero];
    [topBar addSubview:rightPad];
    [topBar addSubview:leftPad];
    [topBar addSubview:centerRightPad];
    [topBar addSubview:centerLeftPad];
    
    NSDictionary *topBarViews = @{@"channelPicker": self.channelPicker,
                                  @"categoryPicker": self.categoryPicker,
                                  @"rightPad": rightPad,
                                  @"leftPad": leftPad,
                                  @"centerRightPad": centerRightPad,
                                  @"centerLeftPad": centerLeftPad
                                  };
    
    NSMutableArray *topBarFormats = [@[@"V:|[channelPicker]|",
                                       @"V:|[categoryPicker]|",
                                       @"|[leftPad(==rightPad)][channelPicker][centerLeftPad(==rightPad)][centerRightPad(==rightPad)][categoryPicker][rightPad]|",
                                       ] mutableCopy];
    
    [topBar addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                  metrics:nil
                                                                    views:topBarViews
                                                                  formats:topBarFormats]];
    
    [self.contentView addSubview:topBar];
    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.channelLabel];
    [self.contentView addSubview:self.categoryLabel];
    [self.contentView addSubview:self.albumLabel];
    [self.contentView addSubview:self.artistLabel];
    [self.contentView addSubview:self.songLabel];
    
    NSMutableDictionary *views = [@{@"topBar": topBar,
                                    @"numberPad": self.numberPad.view,
                                    @"channelLabel": self.channelLabel,
                                    @"categoryLabel": self.categoryLabel,
                                    @"albumLabel": self.albumLabel,
                                    @"artistLabel": self.artistLabel,
                                    @"songLabel": self.songLabel} mutableCopy];
    CGFloat numberHeightMax = 218;
    if ([UIDevice isBigPhone])
    {
        numberHeightMax = 280;
    }
    
    NSDictionary *metrics = @{@"spacer": @4,
                              @"largeSpacer": @100,
                              @"barHeight": @35,
                              @"labelSpacer": @20,
                              @"numberHeightMax": @(numberHeightMax),
                              @"numberHeightMin": @180};
    
    NSMutableArray *formats = [@[
                                 @"|-(labelSpacer)-[channelLabel]-|",
                                 @"|-(labelSpacer)-[categoryLabel]-|",
                                 @"|-(labelSpacer)-[albumLabel]-|",
                                 @"|-(labelSpacer)-[artistLabel]-|",
                                 @"|-(labelSpacer)-[songLabel]-|",
                                 @"|[topBar]|",
                                 ]mutableCopy];


    UIView *bottomBar;
    if ([UIDevice isShortPhone])
    {
        [formats addObjectsFromArray:@[@"V:|[topBar(barHeight)]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[songLabel]-(spacer)-[artistLabel]-(spacer)-[albumLabel]-(spacer)-[channelLabel]-(spacer)-[categoryLabel]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[numberPad(<=numberHeightMax,>=numberHeightMin,==numberHeightMax@300)]|",
                                       @"|[numberPad]|"]];
        if ([self.model.serviceCommands containsObject:@"ScanTP"])
        {
            views[@"scan"] = self.scanButton;
            [self.contentView addSubview:self.scanButton];
            [formats addObjectsFromArray:@[
                                           @"[scan(70)]-(8)-|",
                                           @"V:[scan(barHeight)]-(2)-[numberPad]"
                                           ]];
        }
    }
    else
    {
        [formats addObjectsFromArray:@[
                                       @"V:|[topBar(barHeight)]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[songLabel]-(spacer)-[artistLabel]-(spacer)-[albumLabel]-(spacer)-[channelLabel]-(spacer)-[categoryLabel]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[numberPad(<=numberHeightMax,>=numberHeightMin,==numberHeightMax@500)]|",
                                       @"|[numberPad]|",
                                       ]];

        if ([self.model.serviceCommands containsObject:@"ScanTP"])
        {
            bottomBar = [[UIView alloc] initWithFrame:CGRectZero];
            bottomBar.backgroundColor = [[SCUColors shared] color03shade01];
            [bottomBar addSubview:self.scanButton];
            
            [bottomBar addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                             metrics:nil
                                                                               views:@{@"scan": self.scanButton}
                                                                             formats:@[@"V:|[scan]|", @"|[scan]|"]]];
            [self.contentView addSubview:bottomBar];
            
            views[@"bottomBar"] = bottomBar;
            
            [formats addObjectsFromArray:@[@"|-(8)-[bottomBar]-(8)-|",
                                           @"V:[bottomBar(barHeight)]-(2)-[numberPad]",
                                           ]];
        }
    }
    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                            metrics:metrics
                                                                              views:views
                                                                            formats:formats]];
}

@end
