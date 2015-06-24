//
//  SCUPagingViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 10/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
@import Extensions;

@interface SCUPageView : UIView

@property (nonatomic) UIImage *backgroundImage;

@property (nonatomic) BOOL backgroundImageShouldCrossfade;

@end

@interface SCUTextPageView : SCUPageView

@property (nonatomic) NSString *text;
@property (nonatomic) NSString *detailText;

@end

@interface SCUPagingViewController : UIViewController

- (instancetype)initWithPageViews:(NSArray *)pageViews;

@end
