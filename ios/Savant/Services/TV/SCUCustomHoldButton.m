//
//  SCUChannelPageButton.m
//  SavantController
//
//  Created by Stephen Silber on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUCustomHoldButton.h"
#import "SCUButtonPrivate.h"

@interface SCUCustomHoldButton ()

@property (nonatomic) BOOL holdFired;
@property (nonatomic) NSTimer *customHoldTimer;

@end

@implementation SCUCustomHoldButton

- (void)handleTouchDownAction
{
    if (self.holdAction)
    {
        SAVWeakSelf;
        self.customHoldTimer = [NSTimer sav_scheduledBlockWithDelay:self.holdDelay block:^{
            wSelf.holdFired = YES;
        }];
    }
    else
    {
        [super handleTouchDownAction];
    }
}

- (void)handleRelease
{
    if (!self.holdFired)
    {
        [super handleTouchDownAction];
        [self.customHoldTimer invalidate];
    }
    else
    {
        self.holdFired = NO;
        [super handleRelease];
    }
}

@end
