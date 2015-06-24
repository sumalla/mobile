//
//  SCUNumberPadCollectionViewCell.m
//
//
//  Created by Jason Wolkovitz on 4/16/14.
//
//

#import "SCUNumberPadCollectionViewCell.h"
@import Extensions;

NSString *const SCUNumberPadCollectionViewCellSubTitleKey = @"SCUNumberPadCollectionViewCellSubTitleKey";

@interface SCUNumberPadCollectionViewCell()

@property (nonatomic) UILabel *subTitleLabel;
@property NSArray *labelConstraints;

@end

@implementation SCUNumberPadCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subTitleLabel.textColor = [[SCUColors shared] color03shade06];
        self.subTitleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 16 : 10];

//        self.cellButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 36 : 25];
        self.cellButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[UIDevice isPad] ? [[SCUDimens dimens] regular].h9 : [[SCUDimens dimens] regular].h9];

        [self.contentView addSubview:self.subTitleLabel];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    self.subTitleLabel.textColor = highlighted ? [[SCUColors shared] color03shade03] : [[SCUColors shared] color03shade06];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if (!info[SCUDefaultCollectionViewCellKeyModelObject])
    {
        self.hidden = YES;
    }
    else if ([info[SCUNumberPadCollectionViewCellSubTitleKey] length] > 0)
    {
        self.subTitleLabel.text = info[SCUNumberPadCollectionViewCellSubTitleKey];
        self.cellButton.title = info[SCUDefaultCollectionViewCellKeyTitle];
        self.cellButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, [UIDevice isPhone] ? 14 : 20, 0);

        NSDictionary *views = @{@"subTitle": self.subTitleLabel};

        if ([UIDevice isPad])
        {
            self.labelConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                           metrics:nil
                                                                             views:views
                                                                           formats:@[@"subTitle.top = super.bottom * .70",
                                                                                     @"subTitle.centerX = super.centerX"]];
        }
        else
        {
            self.labelConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                           metrics:nil
                                                                             views:views
                                                                           formats:@[@"subTitle.top = super.bottom * .65",
                                                                                     @"subTitle.centerX = super.centerX"]];
        }

        [self.contentView addConstraints:self.labelConstraints];
    }
    else
    {
        [super configureWithInfo:info];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    if (self.labelConstraints)
    {
        [self.contentView removeConstraints:self.labelConstraints];
    }
    self.subTitleLabel.text = nil;
    self.hidden = NO;
}

@end
