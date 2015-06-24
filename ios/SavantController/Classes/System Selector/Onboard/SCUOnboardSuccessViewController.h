//
//  SCUOnboardSuccessViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 10/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUOnboardSuccessViewController : UIViewController

- (instancetype)initWithSystemName:(NSString *)systemName continueBlock:(dispatch_block_t)continueBlock;

@end
