//
//  SCUVolumeTableViewCell.h
//  SavantController
//
//  Created by Nathan Trapp on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUVolumeCellKeyService;
extern NSString *const SCUVolumeCellKeyServiceGroup;
extern NSString *const SCUVolumeCellKeyDisallowGlobalRoomVolume;

@class SCUVolumeViewController;

@interface SCUVolumeTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) SCUVolumeViewController *volumeVC;
@property (nonatomic) BOOL ignoreFirstAnimation;
@property (nonatomic, copy) dispatch_block_t sliderInteractionHandler;

@end
