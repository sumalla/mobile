//
//  SCUServiceSelectorTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServiceSelectorTableViewCell.h"
#import "SCUServiceSelectorModel.h"
#import "SCUSwipeCellPrivate.h"

NSString *const SCUServiceSelectorTableViewCellKeyServiceIconName = @"SCUServiceSelectorTableViewCellKeyServiceIconName";
NSString *const SCUServiceSelectorTableViewCellKeyIsPowered = @"SCUServiceSelectorTableViewCellKeyIsPowered";
NSString *const SCUServiceSelectorTableViewCellKeyShowsPowerButton = @"SCUServiceSelectorTableViewCellKeyShowsPowerButton";
NSString *const SCUServiceSelectorTableViewCellKeyExpandableImage = @"SCUServiceSelectorTableViewCellKeyExpandableImage";

@interface SCUServiceSelectorTableViewCell ()

@property (nonatomic) SCUButton *powerButton;
@property (nonatomic) SCUServiceSelectorTableViewCellExpandableImageType lastExpandableImageType;
@property (nonatomic) CAShapeLayer *verticalPipe;
@property (nonatomic) CAShapeLayer *horizontalPipe;

@end

@implementation SCUServiceSelectorTableViewCell

+ (UIColor *)poweredColor
{
    return [[SCUColors shared] color04];
}

+ (UIColor *)unpoweredColor
{
    return [[SCUColors shared] color03shade06];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.bottomLineOffset = .085;
        self.bottomLineOffsetRelative = YES;
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPhone] ? [[SCUDimens dimens] regular].h10 : [[SCUDimens dimens] regular].h8];
        self.powerButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"Power"]];
        self.powerButton.frame = CGRectMake(0, 0, 50, 40);
        self.powerButton.color = [[SCUColors shared] color01];
        self.powerButton.selectedColor = [[SCUColors shared] color01];
        self.powerButton.backgroundColor = [UIColor clearColor];
        self.powerButton.selectedBackgroundColor = [UIColor clearColor];
        self.powerButton.scaleImage = YES;
        self.accessoryView = self.powerButton;
        self.bottomLineColor = [[SCUColors shared] color03shade03];
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.accessoryView = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    NSString *imageName = info[SCUServiceSelectorTableViewCellKeyServiceIconName];

    BOOL isPowered = [info[SCUServiceSelectorTableViewCellKeyIsPowered] boolValue];

    if (isPowered)
    {
        self.textLabel.textColor = [[self class] poweredColor];
    }
    else
    {
        self.textLabel.textColor = [[self class] unpoweredColor];
    }

    if (imageName)
    {
        UIImage *image = [UIImage imageNamed:imageName];

        if (isPowered)
        {
            self.imageView.image = [image tintedImageWithColor:[[self class] poweredColor]];
        }
        else
        {
            self.imageView.image = [image tintedImageWithColor:[[self class] unpoweredColor]];
        }
    }
    else
    {
        self.imageView.image = nil;
    }

    SCUServiceSelectorTableViewCellExpandableImageType expandableType = [info[SCUServiceSelectorTableViewCellKeyExpandableImage] unsignedIntegerValue];

    if (expandableType != self.lastExpandableImageType)
    {
        self.lastExpandableImageType = expandableType;
        [self setNeedsDisplay];
    }

    if ([info[SCUServiceSelectorTableViewCellKeyShowsPowerButton] boolValue])
    {
        self.accessoryView = self.powerButton;
        [self setNeedsLayout];
    }
    else
    {
        self.accessoryView = nil;
    }
}

#pragma mark -

- (CGFloat)leftContentOffset
{
    if ([UIDevice isPhablet] || [UIDevice isPad])
    {
        return 70;
    }
    
    return 63;
}

- (CGFloat)indentedLeftContentOffset
{
    if ([UIDevice isPhablet] || [UIDevice isPad])
    {
        return 73;
    }
    
    return 64;
}

- (BOOL)pinAccessoryViewToRight
{
    return YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    
    CGRect textFrame = self.textLabel.frame;
    textFrame.origin.y = (CGRectGetHeight(self.frame) / 2) - (CGRectGetHeight(textFrame) / 2);
    
    if (self.imageView)
    {
        textFrame.origin.x = self.imageView.frame.origin.x + (CGRectGetMinX(self.imageView.frame) + CGRectGetWidth(self.imageView.frame));
    }

    if (self.accessoryView)
    {
        CGRect accessoryFrame = self.accessoryView.frame;
        if (self.imageView)
        {
            self.accessibilityFrame = accessoryFrame;
        }
        textFrame.size.width += (CGRectGetMinX(accessoryFrame) - CGRectGetMaxX(textFrame));
    }
    
    if (self.lastExpandableImageType != SCUServiceSelectorTableViewCellExpandableImageTypeNone)
    {
        textFrame.origin.x = [self indentedLeftContentOffset];
        textFrame.size.width = CGRectGetWidth(self.frame) - ([self indentedLeftContentOffset] * 2);
    }
    
    self.textLabel.frame = textFrame;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    UIBezierPath *verticalPath = nil;

    if (self.lastExpandableImageType == SCUServiceSelectorTableViewCellExpandableImageTypeNone)
    {
        [self.verticalPipe removeFromSuperlayer];
        [self.horizontalPipe removeFromSuperlayer];
        self.verticalPipe = nil;
        self.horizontalPipe = nil;
    }
    else if (self.lastExpandableImageType == SCUServiceSelectorTableViewCellExpandableImageTypeFirstAndMiddle)
    {
        verticalPath = [UIBezierPath bezierPathWithRect:CGRectMake(([self leftContentOffset] / 2) - [UIScreen screenPixel],
                                                                   0,
                                                                   [UIScreen screenPixel],
                                                                   CGRectGetHeight(rect))];
    }
    else
    {
        verticalPath = [UIBezierPath bezierPathWithRect:CGRectMake(([self leftContentOffset] / 2) - [UIScreen screenPixel],
                                                                   0,
                                                                   [UIScreen screenPixel],
                                                                   CGRectGetHeight(rect) / 2)];
    }

    if (verticalPath)
    {
        if (self.verticalPipe)
        {
            [self.verticalPipe removeFromSuperlayer];
            self.verticalPipe = nil;
        }

        if (self.horizontalPipe)
        {
            [self.horizontalPipe removeFromSuperlayer];
            self.horizontalPipe = nil;
        }

        self.verticalPipe = [CAShapeLayer layer];
        self.verticalPipe.path = [verticalPath CGPath];
        self.verticalPipe.fillColor = [[SCUColors shared] color03shade06].CGColor;
        self.verticalPipe.lineWidth = [UIScreen screenPixel];
        [self.layer addSublayer:self.verticalPipe];

        UIBezierPath *horizontalPath = [UIBezierPath bezierPathWithRect:CGRectMake(([self leftContentOffset] / 2),
                                                                                   (CGRectGetHeight(rect) / 2) - [UIScreen screenPixel],
                                                                                   [self leftContentOffset] / 3,
                                                                                   [UIScreen screenPixel])];

        self.horizontalPipe = [CAShapeLayer layer];
        self.horizontalPipe.path = [horizontalPath CGPath];
        self.horizontalPipe.fillColor = [[SCUColors shared] color03shade06].CGColor;
        self.horizontalPipe.lineWidth = [UIScreen screenPixel];
        [self.layer addSublayer:self.horizontalPipe];
    }
}

@end
