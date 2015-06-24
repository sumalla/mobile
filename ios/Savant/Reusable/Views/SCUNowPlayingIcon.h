//
//  SCUNowPlayingIcon.h
//  SavantController
//
//  Created by Nathan Trapp on 8/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUNowPlayingIcon : UIView

@property (nonatomic) NSUInteger numberOfLines;
@property (nonatomic) CGFloat animationDuration;
@property (nonatomic, readonly, getter = isAnimating) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;

@end
