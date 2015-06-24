//
//  SCUIconSelectView.m
//  SavantController
//
//  Created by Stephen Silber on 1/16/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUIconSelectView.h"
#import "SCUDataSourceModel.h"
#import "SCUButton.h"

@interface SCUIconSelectView ()

@property (nonatomic) NSArray *imageNames;
@property (nonatomic) NSMutableArray *imageViews;
@property (nonatomic) NSInteger previousIndex;
@property (nonatomic) NSInteger selectedIndex;

@end

@implementation SCUIconSelectView

- (instancetype)initWithImages:(NSArray *)images
{
    self = [super initWithFrame:CGRectZero];
    
    if (self)
    {
        self.backgroundColor = [[SCUColors shared] color03];
        
        self.imageNames = [images arrayByMappingBlock:^id(NSString *imageName) {
            return [imageName stringByAppendingString:@"_Notification"];
        }];
        
        [self setupViews];
    }
    
    return self;
}

- (void)setupViews
{
    NSUInteger index = 0;
    self.imageViews = [NSMutableArray array];
    for (NSString *name in self.imageNames)
    {
        UIColor *tintColor = [name isEqualToString:self.imageNames.firstObject] ? [[SCUColors shared] color01] : [[SCUColors shared] color04];
        UIImage *normalImage = [UIImage sav_imageNamed:name tintColor:tintColor];
        UIImageView *icon = [[UIImageView alloc] initWithImage:normalImage];
        icon.contentMode = UIViewContentModeCenter;
        
        icon.userInteractionEnabled = YES;
        icon.tag = index;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTappedIcon:)];
        
        [icon addGestureRecognizer:tap];
        [self.imageViews addObject:icon];
        
        index++;
    }
    
    SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
    configuration.interSpace = 0;
    configuration.distributeEvenly = YES;
    configuration.separatorSize = [UIScreen screenPixel];
    
    UIView *container = [UIView sav_viewWithEvenlyDistributedViews:self.imageViews withConfiguration:configuration];
    
    [self addSubview:container];
    [self sav_pinView:container withOptions:SAVViewPinningOptionsHorizontally];
    [self sav_pinView:container withOptions:SAVViewPinningOptionsVertically withSpace:10.0f];
}

- (void)handleTappedIcon:(UITapGestureRecognizer *)tap
{
    NSInteger index = tap.view.tag;
    if (index != self.selectedIndex)
    {
        self.selectedIndex = index;
        
        [self updateSelectedIcon];
        
        if ([self.delegate respondsToSelector:@selector(selectedIndex:forImage:)])
        {
            [self.delegate selectedIndex:self.selectedIndex forImage:self.imageNames[self.selectedIndex]];
        }
    }
}

- (void)selectIndex:(NSInteger)index
{
    self.selectedIndex = index;
    
    [self updateSelectedIcon];
}

- (void)updateSelectedIcon
{
    UIImageView *previousIcon = self.imageViews[self.previousIndex];
    previousIcon.image = [UIImage sav_imageNamed:self.imageNames[self.previousIndex] tintColor:[[SCUColors shared] color04]];
    
    UIImageView *selectedIcon = self.imageViews[self.selectedIndex];
    selectedIcon.image = [UIImage sav_imageNamed:self.imageNames[self.selectedIndex] tintColor:[[SCUColors shared] color01]];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    self.previousIndex = _selectedIndex;
    _selectedIndex = selectedIndex;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 100.0);
}

@end