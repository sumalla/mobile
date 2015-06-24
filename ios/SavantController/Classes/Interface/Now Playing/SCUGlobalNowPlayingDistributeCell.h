//
//  SCUGlobalNowPlayingDistributeCell.h
//  SavantController
//
//  Created by Nathan Trapp on 10/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUGlobalNowPlayingDistributeCellKeyServiceGroup;
extern NSString *const SCUGlobalNowPlayingDistributeCellKeyExpanded;
extern NSString *const SCUGlobalNowPlayingDistributeCellKeyArtworkPresent;

@class SCUButton2;

@interface SCUGlobalNowPlayingDistributeCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) SCUButton2 *expandToggle;

@end
