//
//  SCULightingTableDimmerCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 6/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonTableViewCell.h"
#import "SCUSwipeCellPrivate.h"

NSString *const SCUButtonTableViewCellKeyImageName = @"SCUButtonTableViewCellKeyImageName";
NSString *const SCUButtonTableViewCellKeyButtonText = @"SCUButtonTableViewCellKeyButtonText";
NSString *const SCUButtonTableViewCellKeyButtonIsHighlighted = @"SCUButtonTableViewCellKeyButtonIsHighlighted";

@interface SCUButtonTableViewCell ()

@property (nonatomic) UILabel *label;
@property (nonatomic) UIImageView *labelImage;
@property (nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation SCUButtonTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = .7;

        self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor lightTextColor];
        self.label.userInteractionEnabled = YES;

        self.labelImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
        self.labelImage.userInteractionEnabled = YES;
        self.labelImage.contentMode = UIViewContentModeCenter;
    }

    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.label.textColor = [UIColor lightTextColor];
    self.label.text = nil;
    self.labelImage.image = nil;
    self.accessoryView = nil;

    if (self.tapGesture)
    {
        for (UIGestureRecognizer *recognizer in self.labelImage.gestureRecognizers)
        {
            if (recognizer == self.tapGesture)
            {
                [self.labelImage removeGestureRecognizer:self.tapGesture];
                break;
            }
        }

        for (UIGestureRecognizer *recognizer in self.label.gestureRecognizers)
        {
            if (recognizer == self.tapGesture)
            {
                [self.label removeGestureRecognizer:self.tapGesture];
                break;
            }
        }

        self.tapGesture = nil;
    }
}

- (void)layoutSubviews
{
    CGRect labelFrame = self.label.frame;
    CGSize size = [self.label.text sizeWithAttributes:@{NSFontAttributeName: self.label.font}];
    labelFrame.size.width = size.width;
    labelFrame.origin.x = CGRectGetMaxX(self.bounds) - size.width - 12;
    self.label.frame = CGRectIntegral(labelFrame);

    [super layoutSubviews];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    NSString *imageName = info[SCUButtonTableViewCellKeyImageName];

    if (imageName)
    {
        UIImage *image = [UIImage sav_imageNamed:imageName tintColor:[[SCUColors shared] color04]];
        self.labelImage.image = image;
        self.accessoryView = self.labelImage;
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAccessoryTap:)];
        [self.labelImage addGestureRecognizer:self.tapGesture];
    }
    else
    {
        self.label.text = info[SCUButtonTableViewCellKeyButtonText];

        NSUInteger value = [info[SCUButtonTableViewCellKeyButtonIsHighlighted] unsignedIntegerValue];

        if (value > 0)
        {
            self.label.textColor = [[SCUColors shared] color04];
        }
        else
        {
            self.label.textColor = [UIColor lightTextColor];
        }

        self.accessoryView = self.label;
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAccessoryTap:)];
        [self.label addGestureRecognizer:self.tapGesture];
    }
}

- (void)handleAccessoryTap:(UITapGestureRecognizer *)tapGesture
{
    if ([self.tableView.delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
    {
        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:[self.tableView indexPathForCell:self]];
    }
}

@end
