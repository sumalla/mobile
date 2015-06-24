//
//  SCUMediaTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaTableViewCell.h"
#import "SCUMediaDataModel.h"
#import "SCUSwipeCellPrivate.h"
#import "SCUNowPlayingIcon.h"

@interface SCUMediaTableViewCell ()

@property (nonatomic) UILabel *subtitleTextLabel;
@property (nonatomic) BOOL subtitlePresent;
@property (nonatomic) BOOL imagePresent;
@property (nonatomic) CAShapeLayer *bottomLine;
@property (nonatomic) SCUNowPlayingIcon *nowPlayingIcon;

@end

@implementation SCUMediaTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.borderType = SCUDefaultTableViewCellBorderTypeNone;
        self.contentView.borderWidth = 0.0;

        self.textLabel.textColor = [[SCUColors shared] color04];
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:16];
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.numberOfLines = 2;

        self.detailTextLabel.textColor = [UIDevice isPad] ? [[SCUColors shared] color03shade07] : [[SCUColors shared] color03shade07];
        self.detailTextLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 16 : 14];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        if ([UIDevice isPad])
        {
            self.subtitleTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.subtitleTextLabel.textColor = [UIDevice isPad] ? [[SCUColors shared] color03shade07] : [[SCUColors shared] color03shade07];
            self.subtitleTextLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 16 : 14];
            self.subtitleTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            [self.contentView addSubview:self.subtitleTextLabel];
        }

        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.imagePresent)
    {
        CGRect frame = self.imageView.frame;
        frame = CGRectInset(frame, 0, 10);
        frame.size.width = frame.size.height;
        
        CGRect textFrame = self.textLabel.frame;
        CGRect detailFrame = self.detailTextLabel.frame;
        
        textFrame.origin.x   = CGRectGetMaxX(frame) + 10;
        detailFrame.origin.x = CGRectGetMaxX(frame) + 10;
        
        if (self.subtitlePresent)
        {
            textFrame.size.width = CGRectGetWidth(self.contentView.frame) * 0.45;
        }
        
        self.textLabel.frame = textFrame;
        self.detailTextLabel.frame = detailFrame;
        self.imageView.frame = frame;
    }
    else
    {
        CGRect frame = self.imageView.frame;
        frame = CGRectInset(frame, 0, 10);
        frame.size.width = frame.size.height;

        CGRect textFrame = self.textLabel.frame;
        
        if (self.subtitlePresent)
        {
            textFrame.size.width = CGRectGetWidth(self.contentView.frame) * 0.55;
        }

        self.textLabel.frame = textFrame;
    }
}

- (void)addSubtitleConstraintsPad
{
    [self.subtitleTextLabel removeFromSuperview];
    [self.contentView addSubview:self.subtitleTextLabel];

    NSDictionary *views   = @{@"subtitle" : self.subtitleTextLabel};
    NSDictionary *metrics = @{@"spacer" : @(10)};

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0 metrics:metrics views:views formats:@[@"subtitle.right = super.right",
                                                                                                                            @"subtitle.centerY = super.centerY",
                                                                                                                            @"subtitle.width = super.width * 0.35"]]];
                                                                                                                            
}

- (void)setArtworkImage:(UIImage *)image
{
    self.imageView.image = image;
    self.imagePresent = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.accessoryType = UITableViewCellAccessoryNone;
    self.imageView.image = nil;

    if (self.nowPlayingIcon)
    {
        [self.nowPlayingIcon stopAnimating];
        self.nowPlayingIcon = nil;
        self.accessoryView = nil;
    }
}

- (void)configureWithInfo:(NSDictionary *)info
{
    NSDictionary *mInfo = [info dictionaryByAddingObject:@(SCUDefaultTableViewCellBottomLineTypePartial) forKey:SCUDefaultTableViewCellKeyBottomLineType];
    [super configureWithInfo:mInfo];
    
    self.textLabel.text = info[SCUMediaModelKeyTitle];
    
    if (info[SCUMediaModelKeySubtitle])
    {
        if ([UIDevice isPad])
        {
            self.subtitleTextLabel.text = info[SCUMediaModelKeySubtitle];
            [self addSubtitleConstraintsPad];
            self.subtitlePresent = YES;
        }
        else
        {
            self.detailTextLabel.text = info[SCUMediaModelKeySubtitle];
            self.subtitlePresent = NO;
        }
    }

    if ([info[SCUMediaModelKeyHasSubmenu] boolValue])
    {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    if ([info[SCUMediaModelKeyIsTextfield] boolValue])
    {
        self.textLabel.numberOfLines = 0;
    }
    else
    {
        self.textLabel.numberOfLines = 2;
    }

    if ([info[SCUMediaModelKeyCurrentIndex] boolValue])
    {
        self.nowPlayingIcon = [[SCUNowPlayingIcon alloc] initWithFrame:CGRectMake(0, 0, 16, 20)];
        self.accessoryView = self.nowPlayingIcon;
    }
}

- (CGFloat)bottomLineOffset
{
    CGFloat offset = 20;

    if (self.imageView.image)
    {
        offset = CGRectGetMinX(self.imageView.frame);;
    }

    return offset;
}

@end
