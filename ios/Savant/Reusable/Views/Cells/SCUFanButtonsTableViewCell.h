//
//  SCUFanButtonsTableViewCell.h
//  SavantController
//
//  Created by Stephen Silber on 2/25/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUButton.h"

typedef NS_ENUM(NSInteger, SCUFanButtonsTableViewCellSelectedButton) {
    SCUFanButtonsTableViewCellSelectedButtonOff,
    SCUFanButtonsTableViewCellSelectedButtonLow,
    SCUFanButtonsTableViewCellSelectedButtonMed,
    SCUFanButtonsTableViewCellSelectedButtonHigh,
    SCUFanButtonsTableViewCellSelectedButtonNone
};

extern NSString *const SCUFanButtonsTableViewCellKeySelectedButton;

@interface SCUFanButtonsTableViewCell : SCUDefaultTableViewCell

@property (nonatomic, readonly) SCUButton *offButton;

@property (nonatomic, readonly) SCUButton *lowButton;

@property (nonatomic, readonly) SCUButton *mediumButton;

@property (nonatomic, readonly) SCUButton *highButton;

@end
