//
//  SCUSatelliteRadioNavigationViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSatelliteRadioNavigationViewModel.h"
#import "SCUStateReceiver.h"
#import "SCUButton.h"
@import SDK;

@interface SCUSatelliteRadioNavigationViewModel () <SCUStateReceiver>

@end

@implementation SCUSatelliteRadioNavigationViewModel

- (void)toggleScan:(SCUButton *)sender
{
    if (sender.selected)
    {
        [self sendCommand:@"FinishTP"];
    }
    else
    {
        [self sendCommand:@"ScanTP"];
    }

    sender.selected = !sender.selected;
}

#pragma mark - State Receiver

- (void)didReceiveStateUpdate:(SAVStateUpdate *)stateUpdate
{
    if ([stateUpdate.state hasSuffix:@"CurrentSatelliteCategoryName"])
    {
        [self.delegate categoryChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentSatelliteChannelName"])
    {
        [self.delegate channelChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentSatelliteAlbumName"])
    {
        [self.delegate albumChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentSatelliteArtistName"])
    {
        [self.delegate artistChanged:stateUpdate.value];
    }
    else if ([stateUpdate.state hasSuffix:@"CurrentSatelliteSongTitle"])
    {
        [self.delegate songChanged:stateUpdate.value];
    }
}

- (NSArray *)statesToRegister
{
    return @[[NSString stringWithFormat:@"%@.CurrentSatelliteCategoryName", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentSatelliteChannelName", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentSatelliteAlbumName", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentSatelliteArtistName", self.stateScope],
             [NSString stringWithFormat:@"%@.CurrentSatelliteSongTitle", self.stateScope]];
}

@end
