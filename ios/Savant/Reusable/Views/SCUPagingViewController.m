//
//  SCUPagingViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/8/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUPagingViewController.h"

@implementation SCUPageView

@end

@interface SCUTextPageView ()

@property (nonatomic) UILabel *textLabel;
@property (nonatomic) UILabel *detailTextLabel;

@end

@implementation SCUTextPageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];

        for (UILabel *label in @[self.textLabel, self.detailTextLabel])
        {
            label.numberOfLines = 0;
            label.textColor = [[SCUColors shared] color04];
        }
    }

    return self;
}

- (void)setText:(NSString *)text
{
    _text = text;
    self.textLabel.text = text;
}

- (void)setDetailText:(NSString *)detailText
{
    _detailText = detailText;
    self.detailTextLabel.text = detailText;
}

@end

@interface SCUPagingViewController ()

@property (nonatomic) NSArray *pageViews;

@end

@implementation SCUPagingViewController

- (instancetype)initWithPageViews:(NSArray *)pageViews
{
    self = [super init];

    if (self)
    {
        self.pageViews = pageViews;
    }

    return self;
}

@end
