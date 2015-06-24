//
//  SCUButtonPrivate.h
//  SavantController
//
//  Created by Stephen Silber on 2/13/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUButton.h"

@interface SCUButton ()

- (void)pressed:(SCUButton *)button;

- (void)released:(SCUButton *)button;

- (void)releasedOutside:(SCUButton *)button;

- (void)handleTouchDownAction;

- (void)handleHold;

- (void)handleRelease;

@end
