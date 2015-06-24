//
//  SCUIconWithTextView.m
//  SavantController
//
//  Created by Stephen Silber on 11/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUIconWithTextView.h"
@import Extensions;

@implementation SCUIconWithTextView

- (instancetype)initWithFrame:(CGRect)frame andImage:(UIImage *)image andText:(NSString *)text
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.icon = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.icon.image = image;
        self.icon.contentMode = UIViewContentModeScaleAspectFit;
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.text = text;
        self.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:18];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = .75;
        self.titleLabel.textColor = [[SCUColors shared] color04];
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [self addSubview:self.icon];
        [self addSubview:self.titleLabel];

        [self sav_setSize:CGSizeMake(24, 24) forView:self.icon isRelative:NO];
        [self sav_pinView:self.icon withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsCenterY];
        [self sav_pinView:self.titleLabel withOptions:SAVViewPinningOptionsToRight ofView:self.icon withSpace:5];
        [self sav_pinView:self.titleLabel withOptions:SAVViewPinningOptionsCenterY|SAVViewPinningOptionsVertically|SAVViewPinningOptionsToRight];
    }
    
    return self;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeZero;
    size.height = UIViewNoIntrinsicMetric;
    
    if (self.icon.image)
    {
        size.width += CGRectGetWidth(self.icon.frame);
    }
    
    if (self.titleLabel)
    {
        NSString *titleText = self.titleLabel.text;
        size.width += [titleText sizeWithAttributes: @{NSFontAttributeName:self.titleLabel.font}].width;
    }
    
    return size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

@end
