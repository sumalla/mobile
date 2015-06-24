//
//  SCUButtonFavoriteContentView.m
//  SavantController
//
//  Created by Jason Wolkovitz on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonFavoriteContentView.h"
@import Extensions;

@interface SCUButtonFavoriteContentView()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *label;

@end

@implementation SCUButtonFavoriteContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];

        self.textColor = [[SCUColors shared] color04];

        self.label = [[UILabel alloc] initWithFrame:frame];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setTextColor:self.textColor];
        [self.label setTextAlignment:(NSTextAlignmentCenter)];
        [self addSubview:self.label];
        
        self.imageView = [[UIImageView alloc]initWithFrame:frame];
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        
        [self addSubview:self.imageView];
        [self sav_addFlushConstraintsForView:self.imageView];
        [self sav_addFlushConstraintsForView:self.label withPadding: [UIDevice isPad] ? 10 : 5];
    }
    return self;
}

- (void)setText:(NSString *)text
{
    [self.label setText:text];
    [self.label setFont:[UIFont systemFontOfSize:[UIDevice isPhone] ? 20 : 40]];

    [self.label setAdjustsFontSizeToFitWidth:YES];
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;

    if (image)
    {
        self.text = nil;
    }
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setHighlighted:(BOOL)highlighted
{
    self.imageView.alpha = highlighted ? .6 : 1;
    self.label.alpha = highlighted ? .6 : 1;
}

@end
