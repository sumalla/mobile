//
//  SCUScheudlingExpandableCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/14/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingExpandableCell.h"
#import "SCUSchedulingEditorModel.h"
#import "SCUSchedulingEditingViewController.h"

#import <SavantExtensions/SavantExtensions.h>

@interface SCUSchedulingExpandableCell ()

@property (weak) UIImageView *imageView;

@end

@implementation SCUSchedulingExpandableCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        self.textLabel.font = [UIFont systemFontOfSize:18];
        self.backgroundColor = [UIColor clearColor];

        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:imageView];
        self.imageView = imageView;

        UIView *seperator = [[UIView alloc] initWithFrame:CGRectZero];
        seperator.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.4];
        [self.contentView addSubview:seperator];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                  views:@{@"seperator": seperator,
                                                                                          @"imageView": imageView}
                                                                                formats:@[@"[imageView]-(15)-|",
                                                                                          @"V:|[imageView(53)]",
                                                                                          @"|[seperator]|",
                                                                                          @"V:[seperator(1)]|"]]];
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if (info[SCUDefaultCollectionViewCellKeyModelObject])
    {
        self.imageView.image = [UIImage sav_imageNamed:@"chevron-up" tintColor:[[SCUColors shared] color04]];
    }
    else
    {
        self.imageView.image = [UIImage sav_imageNamed:@"chevron-down" tintColor:[[SCUColors shared] color04]];
    }
}

@end
