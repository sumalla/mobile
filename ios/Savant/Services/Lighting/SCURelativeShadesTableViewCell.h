//
//  SCUDiscreteShadesTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUButton.h"

@interface SCURelativeShadesTableViewCell : SCUDefaultTableViewCell

@property (readonly, nonatomic) SCUButton *closeButton;
@property (readonly, nonatomic) SCUButton *stopButton;
@property (readonly, nonatomic) SCUButton *openButton;

@end
