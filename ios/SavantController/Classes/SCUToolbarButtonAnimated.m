//
//  SCUToolbarButtonAnimated.m
//  SavantController
//
//  Created by Julian Locke on 11/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToolbarButtonAnimated.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUToolbarButtonAnimated ()

@property (strong, nonatomic) UIActivityIndicatorView *indicator;

@end

@implementation SCUToolbarButtonAnimated

- (instancetype)initWithTitle:(NSString *)title
{
    if ((self = [super init]))
    {
        self.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:17];
        self.title = title;
        self.backgroundColor = nil;
        self.selectedBackgroundColor = nil;
        self.selectedColor = [[SCUColors shared] color01];
        self.scaleImage = NO;
        
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        [self addSubview:self.indicator];

        [self sav_pinView:self.indicator withOptions:SAVViewPinningOptionsCenterX];
        [self sav_pinView:self.indicator withOptions:SAVViewPinningOptionsCenterY];
    }
    return self;
}

- (void)animateButton:(BOOL)shouldAnimate
{
    if (shouldAnimate)
    {
        [self setEnabled:NO];
        self.titleLabel.alpha = 0.f;
        [self.indicator startAnimating];
    }
    else
    {
        [self setEnabled:YES];
        [UIView animateWithDuration:.25 animations:^{
            self.titleLabel.alpha = 1.f;
            [self.indicator stopAnimating];
        }];
    }
}

@end
