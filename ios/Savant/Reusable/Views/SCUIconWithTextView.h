//
//  SCUIconWithTextView.h
//  SavantController
//
//  Created by Stephen Silber on 11/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonContentView.h"

@interface SCUIconWithTextView : SCUButtonContentView

- (instancetype)initWithFrame:(CGRect)frame andImage:(UIImage *)image andText:(NSString *)text;

@property (nonatomic) UIImageView *icon;

@property (nonatomic) UILabel *titleLabel;

@end
