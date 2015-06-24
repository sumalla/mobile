//
//  SCUButtonContentView.m
//  SavantController
//
//  Created by Jason Wolkovitz on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonContentView.h"
@import Extensions;

@interface SCUButtonContentView ()

@property UIColor *defaultBackgroundColor;

@end

@implementation SCUButtonContentView

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;

    if (highlighted)
    {
        if (self.selectedBackgroundColor)
        {
            self.backgroundColor = self.selectedBackgroundColor;
        }

        for (UIView *view in self.subviews)
        {
            if ([view isKindOfClass:[UILabel class]] && self.selectedColor)
            {
                UITextView *textView = (UITextView *)view;
                textView.textColor = self.selectedColor;
            }
            else if ([view isKindOfClass:[UIImageView class]] && !self.ignoreImageColor)
            {
                UIImageView *imageView = (UIImageView *)view;

                if (self.selectedImageColor)
                {
                    imageView.image = [imageView.image tintedImageWithColor:self.selectedImageColor];
                }
                else if (self.selectedColor)
                {
                    imageView.image = [imageView.image tintedImageWithColor:self.selectedColor];
                }
            }
        }
    }
    else
    {
        if (self.defaultBackgroundColor)
        {
            self.backgroundColor = self.defaultBackgroundColor;
        }

        for (UIView *view in self.subviews)
        {
            if ([view isKindOfClass:[UILabel class]] && self.color)
            {
                UITextView *textView = (UITextView *)view;
                textView.textColor = self.color;
            }
            else if ([view isKindOfClass:[UIImageView class]] && !self.ignoreImageColor)
            {
                UIImageView *imageView = (UIImageView *)view;

                if (self.imageColor)
                {
                    imageView.image = [imageView.image tintedImageWithColor:self.imageColor];
                }
                else if (self.color)
                {
                    imageView.image = [imageView.image tintedImageWithColor:self.color];
                }
            }
        }
    }
}

- (void)setSelected:(BOOL)selected
{
    _selected = YES;

    self.highlighted = selected;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (!self.defaultBackgroundColor)
    {
        self.defaultBackgroundColor = backgroundColor;
    }

    if (![backgroundColor isEqual:self.selectedBackgroundColor])
    {
        self.defaultBackgroundColor = backgroundColor;
    }

    if (!backgroundColor)
    {
        backgroundColor = [UIColor clearColor];
        self.defaultBackgroundColor = backgroundColor;
    }

    [super setBackgroundColor:backgroundColor];
}

@end
