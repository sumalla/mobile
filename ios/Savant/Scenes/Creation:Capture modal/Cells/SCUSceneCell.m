//
//  SCUSceneCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneCell.h"

NSString *const SCUSceneCellKeyOff = @"SCUSceneCellKeyOff";

@interface SCUSceneCell ()

@property UILabel *nameLabel;
@property UILabel *roomsLabel;
@property UIImageView *iconImageView;

@end

@implementation SCUSceneCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont fontWithName:@"Gotham-Book" size:17];
        self.nameLabel.textColor = [[SCUColors shared] color04];
        self.roomsLabel = [[UILabel alloc] init];
        self.roomsLabel.font = [UIFont fontWithName:@"Gotham-Book" size:12];
        self.roomsLabel.textColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.6];
        self.roomsLabel.numberOfLines = 3;
        self.iconImageView = [[UIImageView alloc] init];
        self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.iconImageView sizeToFit];

        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.roomsLabel];
        [self.contentView addSubview:self.iconImageView];

        [self.contentView sav_pinView:self.nameLabel withOptions:SAVViewPinningOptionsToTop withSpace:30];
        [self.contentView sav_pinView:self.nameLabel withOptions:SAVViewPinningOptionsToRight withSpace:15];
        [self.contentView sav_pinView:self.nameLabel withOptions:SAVViewPinningOptionsToRight ofView:self.iconImageView withSpace:40];
        [self.contentView sav_pinView:self.iconImageView withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToLeft withSpace:30];
        [self.contentView sav_setWidth:40 forView:self.iconImageView isRelative:NO];
        [self.contentView sav_pinView:self.roomsLabel withOptions:SAVViewPinningOptionsToBottom ofView:self.nameLabel withSpace:15];
        [self.contentView sav_pinView:self.roomsLabel withOptions:SAVViewPinningOptionsToRight ofView:self.iconImageView withSpace:40];
        [self.contentView sav_pinView:self.roomsLabel withOptions:SAVViewPinningOptionsToRight withSpace:30];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.nameLabel.text = info[SCUDefaultTableViewCellKeyTitle];

    NSMutableArray *rooms = [info[SCUDefaultTableViewCellKeyModelObject] mutableCopy];

    if ([rooms count] > 3)
    {
        NSInteger moreCount = [rooms count] - 2;

        [rooms insertObject:[NSString stringWithFormat:@"%@%ld %@", NSLocalizedString(@"+", nil), (long)moreCount, NSLocalizedString(@"Rooms", nil)] atIndex:2];

        [rooms removeObjectsInRange:NSMakeRange(3, [rooms count] - 3)];
    }



    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setLineSpacing:7];

    NSAttributedString *roomsText = [[NSAttributedString alloc] initWithString:[[rooms componentsJoinedByString:@"\n"] uppercaseString]
                                                                    attributes:@{NSParagraphStyleAttributeName: paragrahStyle}];

    self.roomsLabel.attributedText = roomsText;
    self.iconImageView.image = [info[SCUDefaultTableViewCellKeyImage] tintedImageWithColor:[[SCUColors shared] color04]];

    if ([info[SCUSceneCellKeyOff] boolValue])
    {
        self.nameLabel.textColor = [[SCUColors shared] color01];
    }
    else
    {
        self.nameLabel.textColor = [[SCUColors shared] color04];
    }
}

@end
