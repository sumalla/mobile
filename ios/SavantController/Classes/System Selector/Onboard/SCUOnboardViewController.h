//
//  SCUOnboardViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 9/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
#import <SavantControl/SavantControl.h>

@protocol SCUOnboardViewControllerDelegate <NSObject>

@optional

- (void)systemDidBind:(SAVSystem *)system;

- (void)system:(SAVSystem *)system didNotBindWithError:(NSError *)error;

- (void)systemBindWasSkipped:(SAVSystem *)system;

@end

@interface SCUOnboardViewController : UIViewController

@property (nonatomic, weak) id<SCUOnboardViewControllerDelegate> delegate;

- (instancetype)initWithSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink;

@end
