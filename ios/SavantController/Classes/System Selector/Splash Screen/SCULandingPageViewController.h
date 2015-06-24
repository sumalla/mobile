//
//  SCULandingPageViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 10/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCULandingPageViewController : UIViewController

@property (nonatomic, readonly) UIImageView *backgroundImage;

- (instancetype)initWithImageName:(NSString *)imageName mainText:(NSString *)mainText detailText:(NSString *)detailText;

@end
