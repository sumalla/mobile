//
//  SCUAddFavoriteChannelCell.m
//  SavantController
//
//  Created by Stephen Silber on 10/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddFavoriteChannelCell.h"

NSString *const CellImageContentMode = @"CellImageContentMode";

@interface SCUAddFavoriteChannelCell ()

@property (nonatomic) UIImageView *cellImage;

@end

@implementation SCUAddFavoriteChannelCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIImageView *cellImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        cellImage.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:cellImage];
        [self.contentView sav_addFlushConstraintsForView:cellImage withPadding:35.0f];
        
        self.cellImage = cellImage;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.cellImage.image = nil;
    self.cellImage.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)configureWithInfo:(id)info
{
    NSString *imageName = info[SCUCollectionViewCellImageNameKey];
    
    if ([imageName length] > 0)
    {
        self.cellImage.image = [UIImage imageNamed:imageName];
    }
    
    if (info[CellImageContentMode])
    {
        self.cellImage.contentMode = [info[CellImageContentMode] integerValue];
    }
}

@end
