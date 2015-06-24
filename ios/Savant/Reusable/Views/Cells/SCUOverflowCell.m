//
//  SCUTVOverlayCell.m
//  SavantController
//
//  Created by Stephen Silber on 2/2/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUOverflowCell.h"

@interface SCUOverflowCell ()

@property (nonatomic) UIImageView *menuItemImageView;
@property (nonatomic) UILabel *menuItemLabel;

@end

NSString *const SCUOverflowCellKeyTitle = @"SCUOverflowCellKeyTitle";
NSString *const SCUOverflowCellKeyImage = @"SCUOverflowCellKeyImage";

@implementation SCUOverflowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        self.menuItemLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.menuItemLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
        self.menuItemLabel.textColor = [[SCUColors shared] color04];
        
        self.menuItemImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        [self.contentView addSubview:self.menuItemLabel];
        [self.contentView addSubview:self.menuItemImageView];

        [self.contentView sav_pinView:self.menuItemImageView withOptions:SAVViewPinningOptionsToLeft withSpace:45];
        [self.contentView sav_pinView:self.menuItemImageView withOptions:SAVViewPinningOptionsCenterY];
        
        [self.contentView sav_pinView:self.menuItemLabel withOptions:SAVViewPinningOptionsToLeft withSpace:90];
        [self.contentView sav_pinView:self.menuItemLabel withOptions:SAVViewPinningOptionsCenterY];
    }
    
    return self;
}

- (void)setDisabled:(BOOL)disabled
{
    if (_disabled != disabled)
    {
        _disabled = disabled;
        
        if (disabled)
        {
            self.menuItemLabel.alpha = 0.4;
            self.menuItemImageView.alpha = 0.4;
            self.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.4];
            self.accessoryType = UITableViewCellAccessoryNone;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            self.menuItemLabel.alpha = 1;
            self.menuItemImageView.alpha = 1;
            self.backgroundColor = [[SCUColors shared] color03shade03];
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.menuItemImageView.image = nil;
    self.menuItemLabel.text = nil;
    self.disabled = NO;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    if (info[SCUOverflowCellKeyTitle])
    {
        self.menuItemLabel.text = [info[SCUOverflowCellKeyTitle] uppercaseString];
    }
    
    if (info[SCUOverflowCellKeyImage])
    {
        UIImage *image = info[SCUOverflowCellKeyImage];
        self.menuItemImageView.image = [image scaleToSize:CGSizeMake(24, 24)];
    }
}

@end
