//
//  SCUMediaTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/21/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUProgressTableViewCell.h"

typedef NS_ENUM(NSUInteger, SCUProgressTableViewCellType)
{
    SCUProgressTableViewCellTypeTitleAndSubtitlePad,
    SCUProgressTableViewCellTypeTitleAndSubtitlePhone,
    SCUProgressTableViewCellTypeTitleOnlyPad,
    SCUProgressTableViewCellTypeTitleOnlyPhone
};

@interface SCUMediaTableViewCell : SCUProgressTableViewCell

- (void)setArtworkImage:(UIImage *)image;

@end


/*

 
 - (void)addPadConstraints
 {
 self.titleWidthPercentage = 0.9;
 NSDictionary *views = @{@"title"    : self.titleTextLabel,
 @"subtitle" : self.subtitleTextLabel,
 @"artwork"  : self.artworkImageView,
 @"bottomBorder" : self.bottomBorder};
 
 NSDictionary *metrics = @{@"spacer" : @(10)};
 
 [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0 metrics:metrics views:views formats:@[@"|-10-[artwork]",
 @"[artwork]-10-[title]",
 @"V:|-10-[artwork]-9-[bottomBorder(1)]|",
 @"title.centerY = super.centerY",
 @"subtitle.centerY = super.centerY",
 @"subtitle.left = super.centerX * 1.4",
 @"title.width = super.width * 0.5",
 @"subtitle.width = super.width * 0.3",
 @"artwork.width = artwork.height",
 @"bottomBorder.width = super.width * 0.95",
 @"bottomBorder.centerX = super.centerX"]]];
 }
 
 - (void)addPhoneConstraints
 {
 self.titleWidthPercentage = 0.9;
 NSDictionary *views = @{@"title"    : self.titleTextLabel,
 @"subtitle" : self.subtitleTextLabel,
 @"artwork"  : self.artworkImageView,
 @"bottomBorder" : self.bottomBorder};
 
 NSDictionary *metrics = @{@"spacer" : @(10)};
 
 [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0 metrics:metrics views:views formats:@[@"|-(spacer)-[artwork]",
 @"[artwork]-(spacer)-[title]",
 @"[artwork]-(spacer)-[subtitle]",
 @"V:|-(spacer)-[artwork]-9-[bottomBorder(1)]|",
 @"V:|[title][subtitle]|",
 @"artwork.width = artwork.height",
 @"bottomBorder.width = super.width * 0.95",
 @"bottomBorder.centerX = super.centerX"]]];
 }



*/