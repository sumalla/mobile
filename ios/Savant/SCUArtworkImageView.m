//
//  SCUArtworkImageView.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUArtworkImageView.h"

@import Extensions;

@interface SCUArtworkImageView ()

@property (nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation SCUArtworkImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.contentMode = UIViewContentModeScaleAspectFit;
        [self addGestureRecognizer:self.tapGesture];
    }

    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)tapGesture
{
    [self.delegate artworkViewWasTapped:self];
}

@end
