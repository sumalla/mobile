//
//  SCUGlobalNowPlayingStatusCell.h
//  SavantController
//
//  Created by Nathan Trapp on 10/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUGlobalNowPlayingStatusCellKeyServiceGroup;
extern NSString *const SCUGlobalNowPlayingStatusCellKeyStatus;
extern NSString *const SCUGlobalNowPlayingDistributeCellKeyArtworkPresent;

@class SCUButton2;

@interface SCUGlobalNowPlayingStatusCell : SCUDefaultTableViewCell

@property (readonly) SCUButton2 *powerButton;

@end

