//
//  UIControl+SAVExtensions.m
//  SavantExtensions
//
//  Created by Cameron Pulsford on 7/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIControl+SAVExtensions.h"
#import "SAVUtils.h"

@interface UIControl ()

@property (nonatomic, copy) dispatch_block_t sav_actionBlock;

@end

@implementation UIControl (SAVExtensions)

SAVSynthesizeCategoryProperty(sav_actionBlock, setSav_actionBlock, dispatch_block_t, OBJC_ASSOCIATION_COPY_NONATOMIC)

- (void)sav_forControlEvent:(UIControlEvents)controlEvent performBlock:(dispatch_block_t)block
{
    NSParameterAssert(block);
    self.sav_actionBlock = block;
    [self addTarget:self action:@selector(sav_performActionBlock) forControlEvents:controlEvent];
}

- (void)sav_performActionBlock
{
    self.sav_actionBlock();
}

@end
