//
//  SCUScenesZoneCell.h
//  SavantController
//
//  Created by Stephen Silber on 8/12/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

extern NSString *const SCUScenesZoneCellCellKeySelected;
extern NSString *const SCUScenesZoneCellCellKeyRoomsList;
extern NSString *const SCUScenesZoneCellCellKeyRoomImagesArray;

@interface SCUScenesZoneCell : SCUDefaultTableViewCell

- (void)setImagesFromArray:(NSArray *)images;

- (void)setRoomsFromArray:(NSArray *)rooms;

@property (readonly) UIImageView *roomImage;

@property (nonatomic, readonly) UIButton *imageButton;

@property (nonatomic) UILabel *roomNames;

@property (nonatomic) BOOL imageButtonEnabled;

@property UIImageView *selectedImage;

@end
