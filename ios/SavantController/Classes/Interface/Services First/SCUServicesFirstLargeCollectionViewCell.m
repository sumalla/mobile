//
//  SCUServicesFirstLargeCollectionViewCell.m
//  SavantController
//
//  Created by Stephen Silber on 9/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUServicesFirstLargeCollectionViewCell.h"

@interface SCUServicesFirstLargeCollectionViewCell ()

@property (nonatomic) UIView *container;
@property (nonatomic) UILabel *subordinateLabel;

@end

@implementation SCUServicesFirstLargeCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        [self.textLabel removeFromSuperview];
        [self.imageView removeFromSuperview];
        self.imageView.contentMode = UIViewContentModeCenter;

        [self.contentView addSubview:self.textLabel];
        [self.contentView addSubview:self.subordinateLabel];
        [self.contentView addSubview:self.imageView];

        self.textLabel.numberOfLines = 2;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        [UIDevice isPad] ? [self padLayout] : [self phoneLayout];
        
        self.contentView.clipsToBounds = YES;
    }
    
    return self;
}

- (void)padLayout
{
    self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h7];
    self.subordinateLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
    
    [self.contentView sav_pinView:self.imageView withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_setY:0.27 forView:self.imageView isRelative:YES];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.imageView
                        withSpace:15];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
    
    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsCenterX
                           ofView:self.textLabel
                        withSpace:8];
}

- (void)phoneLayout
{
    CGFloat yPercentage = .21;

    if ([UIDevice isPhablet])
    {
        yPercentage = .27;
    }

    [self.contentView sav_setY:yPercentage forView:self.imageView isRelative:YES];
    [self.contentView sav_pinView:self.imageView withOptions:SAVViewPinningOptionsHorizontally];
    
    self.textLabel.numberOfLines = 2;
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.imageView
                        withSpace:13];
    
    [self.contentView sav_pinView:self.textLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
    
    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsToBottom
                           ofView:self.textLabel
                        withSpace:4];
    
    [self.contentView sav_pinView:self.subordinateLabel
                      withOptions:SAVViewPinningOptionsHorizontally
                        withSpace:SAVViewAutoLayoutStandardSpace];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.subordinateLabel.text = nil;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];
    
    self.subordinateLabel.textColor = info[SCUServicesFirstCollectionViewCellSubordinateTextColorKey];
    self.subordinateLabel.text = info[SCUServicesFirstCollectionViewCellSubordinateTextKey];
}

@end
