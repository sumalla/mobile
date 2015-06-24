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

@property (nonatomic) UIActivityIndicatorView *indicator;
@property (nonatomic) NSString *originalTitle;

@end

@implementation SCUToolbarButtonAnimated

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super init];
    
    if (self)
    {
        UIFont *font = [UIFont fontWithName:@"Gotham-Medium" size:17];
        self.titleLabel.font = font;
        self.title = title;
        self.originalTitle = title;
        self.frame = [title sav_rectWithFont:font];
        self.backgroundColor = [UIColor clearColor];
        self.selectedBackgroundColor = [UIColor clearColor];
        
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.indicator.hidden = YES;
        [self addSubview:self.indicator];
        [self sav_addCenteredConstraintsForView:self.indicator];
    }

    return self;
}

- (void)setColor:(UIColor *)color
{
    [super setColor:color];
    self.disabledColor = color;
}

- (void)setAnimating:(BOOL)animating
{
    if (_animating != animating)
    {
        _animating = animating;

        if (animating)
        {
            self.userInteractionEnabled = NO;
            self.title = nil;
            self.indicator.hidden = NO;
            [self.indicator startAnimating];
        }
        else
        {
            self.userInteractionEnabled = YES;
            self.title = self.originalTitle;
            self.indicator.hidden = YES;
            [self.indicator stopAnimating];
        }
    }
}

@end
