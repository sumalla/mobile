//
//  SCUNavBarToolbar.m
//  SavantController
//
//  Created by Cameron Pulsford on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNavBarToolbar.h"
#import "SCUToolbar.h"

@import Extensions;

@interface SCUNavBarToolbar ()

@property (nonatomic) SCUToolbar *toolbar;
@property (nonatomic) NSArray *lastItems;

@end

@implementation SCUNavBarToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.toolbar = [[SCUToolbar alloc] initWithFrame:CGRectZero];
        self.toolbar.scrolling = YES;
        self.barStyle = UIBarStyleBlackTranslucent;
        [self addSubview:self.toolbar];
    }

    return self;
}

- (void)clearToolbarItems
{
    [self setItems:@[]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.toolbar.frame = self.bounds;
}

- (void)setItems:(NSArray *)items
{
    if ([items isEqualToArray:self.lastItems])
    {
        return;
    }

    self.lastItems = items;

    if (items)
    {
        [self.toolbar configureWithItems:[SCUToolbar itemConfigurationWithLeftItems:items
                                                                        leftSpacing:[UIDevice isPad] ? 25 : 17
                                                                         rightItems:nil
                                                                       rightSpacing:0]];
    }
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    [self setItems:items];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];
    [self.toolbar setTintColor:tintColor];
}

- (void)setBarTintColor:(UIColor *)barTintColor
{
    [super setBarTintColor:barTintColor];
    [self.toolbar setBarTintColor:barTintColor];
}

@end
