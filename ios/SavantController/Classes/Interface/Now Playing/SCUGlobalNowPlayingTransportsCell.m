//
//  SCUGlobalNowPlayingTransportsCell.m
//  SavantController
//
//  Created by Nathan Trapp on 10/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingTransportsCell.h"
#import "SCUGlobalNowPlayingNowPlayingViewController.h"

#import <SavantControl/SavantControl.h>

NSString *const SCUGlobalNowPlayingTransportsCellKeyServiceGroup = @"SCUGlobalNowPlayingCellKeyServiceGroup";

@interface SCUGlobalNowPlayingTransportsCell ()

@property SCUGlobalNowPlayingNowPlayingViewController *nowPlayingVC;
@property UIView *transportRow;
@property SAVServiceGroup *currentServiceGroup;

@end

@implementation SCUGlobalNowPlayingTransportsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (UIView *)transportRowForServiceGroup:(SAVServiceGroup *)serviceGroup
{
    UIView *transportRow = nil;

    if (self.transportRow)
    {
        if ([self.currentServiceGroup isEqualToServiceGroup:serviceGroup])
        {
            transportRow = self.transportRow;
        }
        else
        {
            [self.transportRow removeFromSuperview];
            self.transportRow = transportRow;
        }
    }

    if (!transportRow)
    {
        self.currentServiceGroup = serviceGroup;

        SCUGlobalNowPlayingNowPlayingViewController *nowPlayingVC = nil;

        BOOL willAppear = NO;
        if (![self.nowPlayingVC.serviceGroup isEqualToServiceGroup:serviceGroup])
        {
            [self.nowPlayingVC viewWillDisappear:NO];
            self.nowPlayingVC = nil;

            nowPlayingVC = [[SCUGlobalNowPlayingNowPlayingViewController alloc] initWithServiceGroup:serviceGroup];

            willAppear = YES;
        }
        else
        {
            nowPlayingVC = self.nowPlayingVC;
        }

        if ([nowPlayingVC.transportButtons count])
        {
            transportRow = nowPlayingVC.view;

            self.nowPlayingVC = nowPlayingVC;
        }

        self.transportRow = transportRow;

        [self.contentView addSubview:transportRow];
        if (willAppear)
        {
            [self.nowPlayingVC viewWillAppear:NO];
        }
    }

    return transportRow;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    SAVServiceGroup *serviceGroup = info[SCUGlobalNowPlayingTransportsCellKeyServiceGroup];

    UIView *transports = [self transportRowForServiceGroup:serviceGroup];
    if (transports)
    {
        [self.contentView sav_pinView:transports withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsVertically];
    }
}

@end
