//
//  SCUGlobalNowPlayingCell.h
//  SavantController
//
//  Created by Nathan Trapp on 8/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUGlobalNowPlayingCellKeyRooms;
extern NSString *const SCUGlobalNowPlayingCellKeyServiceGroup;
extern NSString *const SCUGlobalNowPlayingCellKeyStatus;
extern NSString *const SCUGlobalNowPlayingCellKeyArtwork;

@class SCUButton;

@interface SCUGlobalNowPlayingCell : SCUDefaultTableViewCell

@property (readonly) SCUButton *serviceButton;
@property (readonly) SCUButton *roomsButton;
@property (readonly) SCUButton *powerButton;

@end
