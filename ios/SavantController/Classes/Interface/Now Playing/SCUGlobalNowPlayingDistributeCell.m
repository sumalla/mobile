//
//  SCUGlobalNowPlayingDistributeCell.m
//  SavantController
//
//  Created by Nathan Trapp on 10/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUGlobalNowPlayingDistributeCell.h"
#import "SCUButton.h"
#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSInteger, SCUGlobalNowPlayingDistributeCellDirection)
{
    SCUGlobalNowPlayingDistributeCellDirectionUp,
    SCUGlobalNowPlayingDistributeCellDirectionDown
};

NSString *const SCUGlobalNowPlayingDistributeCellKeyServiceGroup    = @"SCUGlobalNowPlayingDistributeCellKeyServiceGroup";
NSString *const SCUGlobalNowPlayingDistributeCellKeyExpanded        = @"SCUGlobalNowPlayingDistributeCellKeyExpanded";

@interface SCUGlobalNowPlayingDistributeCell ()

@property (nonatomic) SCUButton2 *expandToggle;
@property (nonatomic) UIView *divider;

@end

@implementation SCUGlobalNowPlayingDistributeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];

        UIView *divider = [[UIView alloc] initWithFrame:CGRectZero];
        divider.backgroundColor = [[SCUColors shared] color03shade05];
        [self.contentView addSubview:divider];
        self.divider = divider;

        self.expandToggle = [[SCUButton2 alloc] initWithStyle:SCUButtonStyle1];
        self.expandToggle.selectedBackgroundColor = [[SCUColors shared] color03shade04];
        [self.contentView addSubview:self.expandToggle];

        [self.contentView sav_pinView:divider withOptions:SAVViewPinningOptionsCenterY];
        [self.contentView sav_setHeight:.65 forView:divider isRelative:YES];
        [self.contentView sav_setWidth:[UIScreen screenPixel] forView:divider isRelative:NO];


        [self.contentView sav_pinView:self.expandToggle withOptions:SAVViewPinningOptionsToRight];
        [self.contentView sav_pinView:self.expandToggle withOptions:SAVViewPinningOptionsVertically];
        [self.contentView sav_setWidth:50 forView:self.expandToggle isRelative:NO];
        [self.contentView sav_pinView:divider withOptions:SAVViewPinningOptionsToLeft ofView:self.expandToggle withSpace:0];
    }
    return self;
}

- (void)animateChevronIconWithDirection:(SCUGlobalNowPlayingDistributeCellDirection)direction
{
    CGFloat angle = (direction == SCUGlobalNowPlayingDistributeCellDirectionDown) ? M_PI : 0;
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle);
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:10 options:0 animations:^{
        self.expandToggle.transform = transform;
    } completion:nil];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.expandToggle.image = [UIImage imageWithImage:[UIImage sav_imageNamed:@"chevron-up" tintColor:[[SCUColors shared] color03shade05]] scale:.6 / [UIScreen mainScreen].scale];

    if ([info[SCUGlobalNowPlayingDistributeCellKeyExpanded] boolValue])
    {
        [self animateChevronIconWithDirection:SCUGlobalNowPlayingDistributeCellDirectionUp];
    }
    else
    {
        [self animateChevronIconWithDirection:SCUGlobalNowPlayingDistributeCellDirectionDown];
    }

    self.imageView.image = [UIImage sav_imageNamed:@"distribute" tintColor:[[SCUColors shared] color01]];
    self.textLabel.text = NSLocalizedString(@"All Rooms", nil);
}

@end
