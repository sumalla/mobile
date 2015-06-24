//
//  SCUNowPlayingInlineViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNowPlayingInlineViewControllerPhone.h"
#import "SCUNowPlayingViewControllerPrivate.h"

@implementation SCUNowPlayingInlineViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SCUColors shared] color03];

    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.label];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCallback)];
    [self.label addGestureRecognizer:tapGesture];

    [self.view sav_addConstraintsForView:self.label withEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
}

- (BOOL)wantsAlbumInLabel
{
    return NO;
}

- (NSArray *)states
{
    return [self stateNamesEffectingVisibility];
}

- (NSArray *)stateNamesEffectingVisibility
{
    return @[@"CurrentArtistName", @"CurrentSongName"];
}

- (void)handleCallback
{
    if (self.labelTouchedCallback)
    {
        self.labelTouchedCallback();
    }
}

@end
