//
//  SCUSceneSaveStockImageCell.m
//  SavantController
//
//  Created by Stephen Silber on 10/13/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneSaveStockImageCell.h"

NSString *const SCUSceneSaveStockImageCellKeySelected = @"SCUSceneSaveStockImageCellKeySelected";
NSString *const SCUSceneSaveStockImageCellKeyImage = @"SCUSceneSaveStockImageCellKeyImage";

@interface SCUSceneSaveStockImageCell ()

@property (nonatomic) UIImageView *sceneImageView;
@property (nonatomic) UIImageView *selectedImageView;

@end

@implementation SCUSceneSaveStockImageCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        UIImageView *sceneImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        UIImageView *selectedImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        selectedImageView.backgroundColor = [[[SCUColors shared] color03shade04] colorWithAlphaComponent:0.9];
        selectedImageView.contentMode = UIViewContentModeCenter;
        selectedImageView.hidden = YES;
        
        [self.contentView addSubview:sceneImageView];
        [self.contentView addSubview:selectedImageView];
        
        [self.contentView sav_addFlushConstraintsForView:sceneImageView];
        [self.contentView sav_addFlushConstraintsForView:selectedImageView];
        
        self.sceneImageView = sceneImageView;
        self.selectedImageView = selectedImageView;
    }
    
    return self;
}

- (void)prepareForReuse
{
    self.sceneImageView.image = nil;
    self.selectedImageView.image = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (info[SCUSceneSaveStockImageCellKeyImage])
    {
        UIImage *sceneImage = [UIImage imageNamed:info[SCUSceneSaveStockImageCellKeyImage]];
        self.sceneImageView.image = sceneImage;
    }
    
    if ([info[SCUSceneSaveStockImageCellKeySelected] boolValue])
    {
        self.selectedImageView.image = [UIImage sav_imageNamed:@"check" tintColor:[[SCUColors shared] color04]];
        self.selectedImageView.hidden = NO;
    }
    else
    {
        self.selectedImageView.hidden = YES;
    }
}

@end
