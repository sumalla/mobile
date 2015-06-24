//
//  SCUDefaultTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUSwipeCellPrivate.h"

NSString *const SCUDefaultTableViewCellKeyTitle = @"SCUDefaultTableViewCellKeyTitle";
NSString *const SCUDefaultTableViewCellKeyTitleColor = @"SCUDefaultTableViewCellKeyTitleColor";
NSString *const SCUDefaultTableViewCellKeyAttributedTitle = @"SCUDefaultTableViewCellKeyAttributedTitle";
NSString *const SCUDefaultTableViewCellKeyDetailTitle = @"SCUDefaultTableViewCellKeyDetailTitle";
NSString *const SCUDefaultTableViewCellKeyDetailTitleColor = @"SCUDefaultTableViewCellKeyDetailTitleColor";
NSString *const SCUDefaultTableViewCellKeyImage = @"SCUDefaultTableViewCellKeyImage";
NSString *const SCUDefaultTableViewCellKeyImageTintColor = @"SCUDefaultTableViewCellKeyImageTintColor";
NSString *const SCUDefaultTableViewCellKeyRightImageName = @"SCUDefaultTableViewCellKeyRightImageName";
NSString *const SCUDefaultTableViewCellKeyRightImageTintColor = @"SCUDefaultTableViewCellKeyRightImageTintColor";
NSString *const SCUDefaultTableViewCellKeyModelObject = @"SCUDefaultTableViewCellKeyModelObject";
NSString *const SCUDefaultTableViewCellKeyAccessoryType = @"SCUDefaultTableViewCellKeyAccessoryType";
NSString *const SCUDefaultTableViewCellKeyBottomLineType = @"SCUDefaultTableViewCellKeyBottomLineType";
NSString *const SCUDefaultTableViewCellKeyBottomLineColor = @"SCUDefaultTableViewCellKeyBottomLineColor";
NSString *const SCUDefaultTableViewCellKeyBorderType = @"SCUDefaultTableViewCellKeyBorderType";

@interface SCUDefaultTableViewCell ()

@property (nonatomic) CAShapeLayer *bottomLine;
@property (nonatomic) CAShapeLayer *borderLines;

@end

@implementation SCUDefaultTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style == UITableViewCellStyleDefault ? UITableViewCellStyleValue1 : style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        _bottomLineOffset = -1;
        
        self.textLabel.textColor = [[SCUColors shared] color04];
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
        
        self.detailTextLabel.textColor = [[SCUColors shared] color03shade07];
        self.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];

        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = .7;

        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    self.textLabel.text = info[SCUDefaultTableViewCellKeyTitle];
    self.detailTextLabel.text = info[SCUDefaultTableViewCellKeyDetailTitle];

    NSAttributedString *attributedTitle = info[SCUDefaultTableViewCellKeyAttributedTitle];

    if (attributedTitle)
    {
        self.textLabel.attributedText = attributedTitle;
    }

    if (info[SCUDefaultTableViewCellKeyImageTintColor])
    {
        self.imageView.image = [info[SCUDefaultTableViewCellKeyImage] tintedImageWithColor:info[SCUDefaultTableViewCellKeyImageTintColor]];
    }
    else
    {
        self.imageView.image = info[SCUDefaultTableViewCellKeyImage];
    }

    UIColor *titleColor = info[SCUDefaultTableViewCellKeyTitleColor];

    if (titleColor)
    {
        self.textLabel.textColor = titleColor;
    }

    if (info[SCUDefaultTableViewCellKeyDetailTitleColor])
    {
        self.detailTextLabel.textColor = info[SCUDefaultTableViewCellKeyDetailTitleColor];
    }

    if (info[SCUDefaultTableViewCellKeyAccessoryType])
    {
        self.accessoryType = [info[SCUDefaultTableViewCellKeyAccessoryType] integerValue];
    }

    if (info[SCUDefaultTableViewCellKeyBottomLineType])
    {
        self.bottomLineType = [info[SCUDefaultTableViewCellKeyBottomLineType] unsignedIntegerValue];
    }

    if (info[SCUDefaultTableViewCellKeyBottomLineColor])
    {
        self.bottomLineColor = info[SCUDefaultTableViewCellKeyBottomLineColor];
    }

    NSString *rightImageName = info[SCUDefaultTableViewCellKeyRightImageName];
    UIColor *rightImageTintColor = info[SCUDefaultTableViewCellKeyRightImageTintColor];

    if ([rightImageName length])
    {
        if (rightImageTintColor)
        {
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:rightImageName tintColor:rightImageTintColor]];
        }
        else
        {
            self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:rightImageName]];
        }
    }
    else if (rightImageName && ![rightImageName length])
    {
        self.accessoryView = nil;
    }

    if (info[SCUDefaultTableViewCellKeyBorderType])
    {
        self.borderType = [info[SCUDefaultTableViewCellKeyBorderType] integerValue];
    }
}

- (void)setCustomSeparator:(UIView *)customSeparator
{
    [self.customSeparator removeFromSuperview];

    _customSeparator = customSeparator;

    if (self.customSeparator)
    {
        [self.contentView addSubview:self.customSeparator];
    }
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    if (![indexPath isEqual:_indexPath])
    {
        _indexPath = indexPath;
        [self setNeedsDisplay];
    }
}

- (void)setNumberOfRowsInSection:(NSInteger)numberOfRowsInSection
{
    if (numberOfRowsInSection != _numberOfRowsInSection)
    {
        _numberOfRowsInSection = numberOfRowsInSection;

        [self setNeedsDisplay];
    }
}

- (void)setBorderType:(SCUDefaultTableViewCellBorderType)borderType
{
    if (borderType != _borderType)
    {
        _borderType = borderType;

        [self setNeedsDisplay];
    }
}

- (void)setBottomLineType:(SCUDefaultTableViewCellBottomLineType)bottomLineType
{
    if (bottomLineType != _bottomLineType)
    {
        _bottomLineType = bottomLineType;

        [self setNeedsDisplay];
    }
}

- (void)setBottomLineOffset:(CGFloat)bottomLineOffset
{
    if (bottomLineOffset != _bottomLineOffset)
    {
        _bottomLineOffset = bottomLineOffset;

        [self setNeedsDisplay];
    }
}

- (void)setBottomLineOffsetRelative:(CGFloat)bottomLineOffsetRelative
{
    if (bottomLineOffsetRelative != _bottomLineOffsetRelative)
    {
        _bottomLineOffsetRelative = bottomLineOffsetRelative;

        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *borderPath = nil;
    UIBezierPath *bottomPath = nil;

    BOOL drawSideBorders = NO;
    BOOL drawTopBorder = NO;
    BOOL drawBottomBorder = NO;

    switch (self.borderType)
    {
        case SCUDefaultTableViewCellBorderTypeSection:
            if (self.indexPath.row == 0)
            {
                drawTopBorder = YES;
            }
            // fall through to bottom + sides
        case SCUDefaultTableViewCellBorderTypeBottomAndSides:
            drawSideBorders = YES;

            if (self.indexPath.row == (self.numberOfRowsInSection - 1))
            {
                drawBottomBorder = YES;
            }
            break;
        case SCUDefaultTableViewCellBorderTypeCell:
            drawSideBorders = YES;
            drawTopBorder = YES;
            drawBottomBorder = YES;
            break;
        case SCUDefaultTableViewCellBorderTypeTopPartial:
            drawTopBorder = YES;
            break;
        case SCUDefaultTableViewCellBorderTypeNone:
            break;
    }

    if (drawSideBorders)
    {
        if (!borderPath)
        {
            borderPath = [UIBezierPath bezierPath];
        }

        // Left
        [borderPath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, [UIScreen screenPixel], CGRectGetHeight(rect))]];

        // Right
        [borderPath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(CGRectGetWidth(rect) - [UIScreen screenPixel], 0, [UIScreen screenPixel], CGRectGetHeight(rect))]];
    }

    if (drawTopBorder)
    {
        if (!borderPath)
        {
            borderPath = [UIBezierPath bezierPath];
        }

        CGRect f = CGRectMake(0, 0, CGRectGetWidth(rect), [UIScreen screenPixel]);

        if (self.borderType == SCUDefaultTableViewCellBorderTypeTopPartial)
        {
            f.size.width = CGRectGetWidth(rect) - (CGRectGetMinX(self.textLabel.frame) * 2);
            f.origin.x = (CGRectGetWidth(rect) - f.size.width) / 2;
        }

        [borderPath appendPath:[UIBezierPath bezierPathWithRect:CGRectIntegral(f)]];
    }

    if (drawBottomBorder)
    {
        if (!borderPath)
        {
            borderPath = [UIBezierPath bezierPath];
        }

        if (self.bottomLine)
        {
            [self.bottomLine removeFromSuperlayer];
            self.bottomLine = nil;
        }

        [borderPath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(0, CGRectGetHeight(rect) - [UIScreen screenPixel], CGRectGetWidth(rect), [UIScreen screenPixel])]];
    }
    else
    {
        if (self.bottomLineType == SCUDefaultTableViewCellBottomLineTypeNone)
        {
            [self.bottomLine removeFromSuperlayer];
            self.bottomLine = nil;
        }
        else if (self.bottomLineType == SCUDefaultTableViewCellBottomLineTypeFull)
        {
            bottomPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, CGRectGetHeight(rect) - [UIScreen screenPixel], CGRectGetWidth(rect), [UIScreen screenPixel])];
        }
        else
        {
            CGFloat leftSide = 0;
            CGFloat width = 0;

            if (self.bottomLineOffset == -1)
            {
                leftSide = 15;
                width = CGRectGetWidth(rect) - (leftSide * 2);
            }
            else
            {
                if (self.bottomLineOffsetRelative)
                {
                    leftSide = CGRectGetWidth(rect) * self.bottomLineOffset;
                }
                else
                {
                    leftSide = self.bottomLineOffset;
                }
                width = CGRectGetWidth(rect) - (leftSide * 2);

                if ([self.tableView.dataSource sectionIndexTitlesForTableView:self.tableView])
                {
                    width -= 20;
                }
            }

            bottomPath = [UIBezierPath bezierPathWithRect:CGRectMake(leftSide,
                                                               CGRectGetHeight(rect) - [UIScreen screenPixel],
                                                               width,
                                                               [UIScreen screenPixel])];
        }

        if (bottomPath)
        {
            if (self.bottomLine)
            {
                [self.bottomLine removeFromSuperlayer];
            }

            self.bottomLine = [CAShapeLayer layer];
            self.bottomLine.path = [bottomPath CGPath];
            self.bottomLine.fillColor = self.bottomLineColor ? self.bottomLineColor.CGColor : [[[SCUColors shared] color03shade05] colorWithAlphaComponent:.8].CGColor;
            self.bottomLine.lineWidth = [UIScreen screenPixel];
            [self.layer addSublayer:self.bottomLine];
        }
    }

    if (self.borderLines)
    {
        [self.borderLines removeFromSuperlayer];
        self.borderLines = nil;
    }

    if (borderPath)
    {
        self.borderLines = [CAShapeLayer layer];
        self.borderLines.path = [borderPath CGPath];
        self.borderLines.fillColor = self.borderColor.CGColor;
        [self.layer addSublayer:self.borderLines];
    }
}

@end
