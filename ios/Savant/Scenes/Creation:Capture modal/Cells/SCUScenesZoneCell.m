//
//  SCUScenesZoneCell.m
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesZoneCell.h"
#import "SCUZoneImagesView.h"

NSString *const SCUScenesZoneCellCellKeySelected = @"SCUScenesZoneCellCellKeySelected";
NSString *const SCUScenesZoneCellCellKeyRoomsList = @"SCUScenesZoneCellCellKeyRoomsList";
NSString *const SCUScenesZoneCellCellKeyRoomImagesArray = @"SCUScenesZoneCellCellKeyRoomImagesArray";

@interface SCUScenesZoneCell ()

@property NSArray *images;
@property SCUZoneImagesView *zoneImages;

@property UILabel *zoneName;

@end

@implementation SCUScenesZoneCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.zoneName = [[UILabel alloc] init];
        self.zoneName.textColor = [[SCUColors shared] color04];
        self.zoneName.font = [UIFont fontWithName:@"Gotham-Book" size:17.0f];
        
        [self.contentView addSubview:self.zoneName];
        
        self.roomNames = [[UILabel alloc] init];
        self.roomNames.textColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.6];
        self.roomNames.font = [UIFont fontWithName:@"Gotham-Book" size:12];
        self.roomNames.numberOfLines = 3;
        [self.contentView addSubview:self.roomNames];
        
        self.zoneImages = [[SCUZoneImagesView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.zoneImages];

        [self.zoneImages addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{} views:@{@"zoneImages" : self.zoneImages} formats:@[@"zoneImages.width = zoneImages.height"]]];

        [self.contentView sav_pinView:self.zoneName withOptions:SAVViewPinningOptionsToTop withSpace:30];
        [self.contentView sav_pinView:self.zoneName withOptions:SAVViewPinningOptionsToRight withSpace:15];
        [self.contentView sav_pinView:self.zoneName withOptions:SAVViewPinningOptionsToRight ofView:self.zoneImages withSpace:25];
        [self.contentView sav_pinView:self.zoneImages withOptions:SAVViewPinningOptionsToLeft withSpace:20];
        [self.contentView sav_setWidth:100 forView:self.zoneImages isRelative:NO];
        [self.contentView sav_pinView:self.zoneImages withOptions:SAVViewPinningOptionsCenterY];
        [self.contentView sav_pinView:self.roomNames withOptions:SAVViewPinningOptionsToBottom ofView:self.zoneName withSpace:15];
        [self.contentView sav_pinView:self.roomNames withOptions:SAVViewPinningOptionsToRight ofView:self.zoneImages withSpace:25];
        [self.contentView sav_pinView:self.roomNames withOptions:SAVViewPinningOptionsToRight withSpace:30];

        
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

- (UIButton *)imageButton
{
    return self.zoneImages.imageButton;
}

- (void)setImageButtonEnabled:(BOOL)imageButtonEnabled
{
    _imageButtonEnabled = imageButtonEnabled;
    self.zoneImages.imageButton.userInteractionEnabled = imageButtonEnabled;
}

- (void)setRoomsFromArray:(NSArray *)rooms
{
    NSMutableArray *mutableRooms = [rooms mutableCopy];

    if ([mutableRooms count] > 3)
    {
        NSInteger moreCount = [mutableRooms count] - 2;

        [mutableRooms insertObject:[NSString stringWithFormat:@"%@%ld %@", NSLocalizedString(@"+", nil), (long)moreCount, NSLocalizedString(@"Rooms", nil)] atIndex:2];

        [mutableRooms removeObjectsInRange:NSMakeRange(3, [mutableRooms count] - 3)];
    }
    
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setLineSpacing:5];

    self.roomNames.attributedText = [[NSAttributedString alloc] initWithString:[[mutableRooms componentsJoinedByString:@"\n"] uppercaseString]
                                                                    attributes:@{NSParagraphStyleAttributeName: paragrahStyle,
                                                                                 NSFontAttributeName: [UIFont fontWithName:@"Gotham-Book" size:12]}];
}

- (void)setImagesFromArray:(NSArray *)images
{
    [self.zoneImages setImagesFromArray:images];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (info[SCUScenesZoneCellCellKeyRoomsList])
    {
        [self setRoomsFromArray:info[SCUScenesZoneCellCellKeyRoomsList]];
    }
    
    if (info[SCUScenesZoneCellCellKeyRoomImagesArray])
    {
        [self.zoneImages setImagesFromArray:info[SCUScenesZoneCellCellKeyRoomImagesArray]];
        
    }
    self.accessoryType = [info[SCUDefaultTableViewCellKeyAccessoryType] integerValue];
    self.zoneName.text = info[SCUDefaultTableViewCellKeyTitle];
    [self.zoneImages setSelected:[info[SCUScenesZoneCellCellKeySelected] boolValue]];
}

@end
