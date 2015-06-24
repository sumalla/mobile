//
//  SCUScenesRoomCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUScenesRoomCellCellKeySelected;

@interface SCUScenesRoomCell : SCUDefaultTableViewCell

@property (readonly) UIImageView *roomImage;
@property (readonly) UIButton *imageButton;

@end
