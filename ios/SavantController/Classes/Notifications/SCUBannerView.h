//
//  SCUBannerView.h
//  SavantController
//
//  Created by Julian Locke on 2/9/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUBannerView : UIView

@property (nonatomic, copy) dispatch_block_t tapHandler;

@property (nonatomic, copy) void (^dismissHandler)(SCUBannerView *bannerView);

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image text:(NSString *)text;

- (void)showAnimated:(BOOL)animated withVelocity:(CGFloat)velocity withCompletionHandler:(dispatch_block_t)completionHandler;

- (void)hideAnimated:(BOOL)animated withVelocity:(CGFloat)velocity withCompletionHandler:(dispatch_block_t)completionHandler;

@end
