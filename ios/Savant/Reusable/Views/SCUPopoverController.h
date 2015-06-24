//
//  SCUTablePopoverController.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUPopoverController : UIPopoverController

- (void)presentPopoverFromButton:(UIButton *)button permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;

@end
