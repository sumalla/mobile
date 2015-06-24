//
//  SCUCaptureRoomCell.h
//  SavantController
//
//  Created by Stephen Silber on 12/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButton.h"
#import "SCUScenesRoomCell.h"

extern NSString *const SCUCaptureRoomCellKeyChevronDirection;

typedef NS_ENUM(NSUInteger, SCUCaptureRoomCellChevronDirection)
{
    SCUCaptureRoomCellChevronDirectionUp,
    SCUCaptureRoomCellChevronDirectionDown
};

@import UIKit;

@interface SCUCaptureRoomCell : SCUScenesRoomCell

@property (nonatomic, readonly) SCUButton *chevronButton;

@end
