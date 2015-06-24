//
//  SCUTVOverlayCell.h
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUOverflowCellKeyTitle;
extern NSString *const SCUOverflowCellKeyImage;

@interface SCUOverflowCell : SCUDefaultTableViewCell

@property (nonatomic) BOOL disabled;

@end
