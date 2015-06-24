//
//  SCUScenesRoomCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesRoomCell.h"

NSString *const SCUScenesRoomCellCellKeySelected = @"SCUScenesRoomCellCellKeySelected";

@interface SCUScenesRoomCell ()

@property UIImageView *roomImage;
@property UIImageView *selectedImage;
@property UILabel *roomName;
@property UIButton *imageButton;

@end

@implementation SCUScenesRoomCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.roomImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.roomImage.contentMode = UIViewContentModeScaleAspectFill;
        self.roomImage.clipsToBounds = YES;
        [self.contentView addSubview:self.roomImage];
        [self.contentView sav_pinView:self.roomImage withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToLeft withSpace:15];
        [self.contentView sav_setWidth:70 forView:self.roomImage isRelative:NO];

        self.selectedImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.selectedImage.contentMode = UIViewContentModeCenter;
        self.selectedImage.layer.borderColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.25].CGColor;
        self.selectedImage.layer.borderWidth = [UIScreen screenPixel];
        self.selectedImage.backgroundColor = [[[SCUColors shared] color03shade05] colorWithAlphaComponent:.9];
        self.selectedImage.hidden = YES;
        self.selectedImage.image = [UIImage sav_imageNamed:@"check" tintColor:[[SCUColors shared] color04]];
        [self.roomImage addSubview:self.selectedImage];
        [self.roomImage sav_addFlushConstraintsForView:self.selectedImage];

        self.roomName = [[UILabel alloc] init];
        self.roomName.textColor = [[SCUColors shared] color04];
        [self.contentView addSubview:self.roomName];

        [self.contentView sav_pinView:self.roomName withOptions:SAVViewPinningOptionsToRight ofView:self.roomImage withSpace:15];
        [self.contentView sav_pinView:self.roomName withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToRight withSpace:18];

        self.imageButton = [[UIButton alloc] init];
        [self.contentView addSubview:self.imageButton];
        [self.contentView sav_pinView:self.imageButton withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToLeft withSpace:15];
        [self.contentView sav_setWidth:70 forView:self.imageButton isRelative:NO];

        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:20];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *backgroundColor = self.selectedImage.backgroundColor;
    [super setSelected:selected animated:animated];
    self.selectedImage.backgroundColor = backgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    UIColor *backgroundColor = self.selectedImage.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    self.selectedImage.backgroundColor = backgroundColor;
    
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.accessoryType = [info[SCUDefaultTableViewCellKeyAccessoryType] integerValue];
    self.roomName.text = info[SCUDefaultTableViewCellKeyTitle];
    self.selectedImage.hidden = ![info[SCUScenesRoomCellCellKeySelected] boolValue];
}

@end
