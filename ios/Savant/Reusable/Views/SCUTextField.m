//
//  SCUTextField.m
//  SavantController
//
//  Created by Cameron Pulsford on 8/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTextField.h"
@import Extensions;

@implementation SCUTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.contentInsets = UIEdgeInsetsMake(0, 10, 0, 10);

        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *clearImage = [UIImage imageNamed:@"ClearButton"];
        [clearButton setImage:[clearImage tintedImageWithColor:[[SCUColors shared] color04]] forState:UIControlStateNormal];
        [clearButton setImage:[clearImage tintedImageWithColor:[UIColor lightGrayColor]] forState:UIControlStateSelected];
        clearButton.frame = CGRectMake(0, 0, 30, 30);
        clearButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        self.rightView = clearButton;
        self.rightViewMode = UITextFieldViewModeWhileEditing;

        SAVWeakSelf;
        [clearButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
            wSelf.text = @"";
        }];
    }

    return self;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect newBounds = bounds;
    newBounds.origin.x += self.contentInsets.left;
    newBounds.size.width -= self.contentInsets.right;
    return newBounds;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    return [self editingRectForBounds:bounds];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect rect = bounds;
    rect.origin.x = CGRectGetMaxX(bounds) - 50;
    rect.origin.y = (CGRectGetMaxY(bounds) / 2) - 25;
    rect.size.width = 50;
    rect.size.height = 50;
    return rect;
}

@end
