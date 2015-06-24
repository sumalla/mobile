//
//  SCUScenesExtensionItem.h
//  SavantController
//
//  Created by Nathan Trapp on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButton.h"

@interface SCUScenesExtensionItem : SCUButton

@property (nonatomic, readonly) UIImageView *contentImage;
@property (nonatomic, readonly) UILabel *contentLabel;

+ (instancetype)itemWithImage:(UIImage *)image width:(CGFloat)width andName:(NSString *)name;

@end
