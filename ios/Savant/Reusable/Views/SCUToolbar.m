//
//  SCUMainToolbar.m
//  SavantController
//
//  Created by Nathan Trapp on 4/3/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUToolbar.h"
#import "SCUMainToolbarManager.h"
#import "SCUVolumeViewController.h"
#import "SCUToolbarButton.h"

@import Extensions;

NSString *const SCUToolbarLeftItemsKey         = @"SCUToolbarLeftItemsKey";
NSString *const SCUToolbarRightItemsKey        = @"SCUToolbarRightItemsKey";
NSString *const SCUToolbarCenterItemsKey       = @"SCUToolbarCenterItemsKey";
NSString *const SCUToolbarLeftItemSpacingKey   = @"SCUToolbarLeftItemSpacingKey";
NSString *const SCUToolbarRightItemSpacingKey  = @"SCUToolbarRightItemSpacingKey";
NSString *const SCUToolbarCenterItemSpacingKey = @"SCUToolbarCenterItemSpacingKey";

typedef NS_ENUM(NSUInteger, SCUToolbarLayoutDirection) {
    SCUToolbarLeftLayout,
    SCUToolbarRightLayout,
    SCUToolbarCenterLayout
};

static NSString *SCUKeyHorizontal = @"SCUKeyHorizontal";
static NSString *SCUKeyVertical   = @"SCUKeyVertical";
static NSString *SCUKeyViews      = @"SCUKeyViews";

@interface SCUToolbarScrollView : UIScrollView

@end

@implementation SCUToolbarScrollView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}

@end

@interface SCUToolbar ()

@property NSArray *viewControllers;

@property NSArray *leftBarItems;
@property NSArray *rightBarItems;
@property NSArray *centerBarItems;

@property NSNumber *leftBarItemSpacing;
@property NSNumber *rightBarItemSpacing;
@property NSNumber *centerBarItemSpacing;

@property (weak) UIView *contentView;

@end

@implementation SCUToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:contentView];
        self.contentView = contentView;
        [self sav_addFlushConstraintsForView:self.contentView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.scrolling)
    {
        CGFloat width = CGRectGetWidth(self.bounds);
        CGFloat contentWidth = self.leftBarItemsSize.width + self.rightBarItemsSize.width;

        UIScrollView *scrollView = (UIScrollView *)self.contentView;
        scrollView.scrollsToTop = NO;

        scrollView.contentSize = CGSizeMake(width > contentWidth ? width : contentWidth, CGRectGetHeight(self.bounds));
    }
}

- (void)resetSubviews
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

#pragma mark - Configuration

+ (NSDictionary *)itemConfigurationWithLeftItems:(NSArray *)leftItems leftSpacing:(NSUInteger)leftSpacing rightItems:(NSArray *)rightItems rightSpacing:(NSUInteger)rightSpacing
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if ([leftItems count])
    {
        dictionary[SCUToolbarLeftItemsKey] = leftItems;
    }

    if (leftSpacing > 0)
    {
        dictionary[SCUToolbarLeftItemSpacingKey] = @(leftSpacing);
    }

    if ([rightItems count])
    {
        dictionary[SCUToolbarRightItemsKey] = rightItems;
    }

    if (rightSpacing > 0)
    {
        dictionary[SCUToolbarRightItemSpacingKey] = @(rightSpacing);
    }

    return [dictionary copy];
}

- (void)configureWithItems:(NSDictionary *)items
{
    [self resetSubviews];

    NSMutableArray *leftBarItems = [NSMutableArray array];
    NSMutableArray *rightBarItems = [NSMutableArray array];
    NSMutableArray *centerBarItems = [NSMutableArray array];
    NSMutableArray *viewControllers = [NSMutableArray array];

    NSArray *leftItems = items[SCUToolbarLeftItemsKey];
    for (id barItem in leftItems)
    {
        if ([barItem isKindOfClass:[UIViewController class]])
        {
            UIViewController *viewController = (UIViewController *)barItem;
            [viewControllers addObject:viewController];
            [leftBarItems addObject:viewController.view];
        }
        else
        {
            [leftBarItems addObject:barItem];
        }
    }

    NSArray *rightItems = items[SCUToolbarRightItemsKey];
    for (id barItem in rightItems)
    {
        if ([barItem isKindOfClass:[UIViewController class]])
        {
            UIViewController *viewController = (UIViewController *)barItem;
            [viewControllers addObject:viewController];
            [rightBarItems addObject:viewController.view];
        }
        else
        {
            [rightBarItems addObject:barItem];
        }
    }

    NSArray *centerItems = items[SCUToolbarCenterItemsKey];
    for (id barItem in centerItems)
    {
        if ([barItem isKindOfClass:[UIViewController class]])
        {
            UIViewController *viewController = (UIViewController *)barItem;
            [viewControllers addObject:viewController];
            [centerBarItems addObject:viewController.view];
        }
        else
        {
            [centerBarItems addObject:barItem];
        }
    }

    self.viewControllers = viewControllers;

    self.leftBarItems = leftBarItems;
    self.rightBarItems = rightBarItems;
    self.centerBarItems = centerBarItems;
    self.leftBarItemSpacing = items[SCUToolbarLeftItemSpacingKey];
    self.rightBarItemSpacing = items[SCUToolbarRightItemSpacingKey];
    self.centerBarItemSpacing = items[SCUToolbarCenterItemSpacingKey];

    [self setupConstraintsForItems];
}

- (void)configureWithManager:(id <SCUMainToolbarManager>)manager
{
    [self resetSubviews];

    SCUMainToolbarItems toolbarItems = SCUMainToolbarItemsNone;

    if ([manager respondsToSelector:@selector(mainToolbarItems)])
    {
        toolbarItems = [manager mainToolbarItems];;
    }

    NSMutableArray *leftBarItems = [NSMutableArray array];
    NSMutableArray *rightBarItems = [NSMutableArray array];
    NSMutableArray *centerBarItems = [NSMutableArray array];
    NSMutableArray *viewControllers = [NSMutableArray array];
    NSNumber *leftItemSpacing = nil;
    NSNumber *rightItemSpacing = nil;
    NSNumber *centerItemSpacing = nil;

    if (toolbarItems & SCUMainToolbarItemsLeftButtons)
    {
        NSArray *items = [manager mainToolbarLeftItems];
        for (id barItem in items)
        {
            if ([barItem isKindOfClass:[UIViewController class]])
            {
                UIViewController *viewController = (UIViewController *)barItem;
                [viewControllers addObject:viewController];
                [leftBarItems addObject:viewController.view];
            }
            else
            {
                [leftBarItems addObject:barItem];
            }
        }
    }

    if (toolbarItems & SCUMainToolbarItemsRightButtons)
    {
        NSArray *items = [manager mainToolbarRightItems];
        for (id barItem in items)
        {
            if ([barItem isKindOfClass:[UIViewController class]])
            {
                UIViewController *viewController = (UIViewController *)barItem;
                [viewControllers addObject:viewController];
                [rightBarItems addObject:viewController.view];
            }
            else
            {
                [rightBarItems addObject:barItem];
            }
        }
    }

    if (toolbarItems & SCUMainToolbarItemsCenterButtons)
    {
        NSArray *items = [manager mainToolbarCenterItems];
        for (id barItem in items)
        {
            if ([barItem isKindOfClass:[UIViewController class]])
            {
                UIViewController *viewController = (UIViewController *)barItem;
                [viewControllers addObject:viewController];
                [centerBarItems addObject:viewController.view];
            }
            else
            {
                [centerBarItems addObject:barItem];
            }
        }
    }

    if (toolbarItems & SCUMainToolbarItemsVolumeControl)
    {
        SCUVolumeViewController *viewController = nil;
        if ([manager respondsToSelector:@selector(isServicesFirst)] && [manager isServicesFirst] && [manager respondsToSelector:@selector(serviceGroup)])
        {
            viewController = [[SCUVolumeViewController alloc] initWithServiceGroup:[manager serviceGroup]];
        }
        // TODO: Handle current service
//        else if ([SCUInterface sharedInstance].currentService)
//        {
//            viewController = [[SCUVolumeViewController alloc] initWithService:[SCUInterface sharedInstance].currentService];
//
//            if ([manager respondsToSelector:@selector(forceSlingshot)] && [manager forceSlingshot])
//            {
//                viewController.forceSlingshot = YES;
//            }
//        }

        if (viewController)
        {
            [viewControllers addObject:viewController];

            if ([UIDevice isPhone])
            {
                [centerBarItems addObject:viewController.view];
            }
            else
            {
                [rightBarItems addObject:viewController.view];
            }
        }
    }

    if (toolbarItems & SCUMainToolbarItemsBarTintColor)
    {
        self.barTintColor = [manager mainToolbarTintColor];
    }
    else
    {
        self.barTintColor = [[SCUColors shared] color03];
    }

    if (toolbarItems & SCUMainToolbarItemsLeftSpacing)
    {
        leftItemSpacing = [manager mainToolbarItemLeftSpacing];
    }

    if (toolbarItems & SCUMainToolbarItemsRightSpacing)
    {
        rightItemSpacing = [manager mainToolbarItemRightSpacing];
    }

    if (toolbarItems & SCUMainToolbarItemsCenterSpacing)
    {
        rightItemSpacing = [manager mainToolbarItemCenterSpacing];
    }

    self.viewControllers = viewControllers;

    self.leftBarItems = leftBarItems;
    self.rightBarItems = rightBarItems;
    self.centerBarItems = centerBarItems;
    self.leftBarItemSpacing = leftItemSpacing;
    self.rightBarItemSpacing = rightItemSpacing;
    self.centerBarItemSpacing = centerItemSpacing;

    [self setupConstraintsForItems];
}

- (void)setupConstraintsForItems
{
    NSDictionary *leftFormats = [self visualFormatsForViews:self.leftBarItems layoutDirection:SCUToolbarLeftLayout spacing:self.leftBarItemSpacing];
    NSDictionary *rightFormats = [self visualFormatsForViews:self.rightBarItems layoutDirection:SCUToolbarRightLayout spacing:self.rightBarItemSpacing];
    NSDictionary *centerFormats = [self visualFormatsForViews:self.centerBarItems layoutDirection:SCUToolbarCenterLayout spacing:self.centerBarItemSpacing];

    NSMutableDictionary *views = [NSMutableDictionary dictionaryWithDictionary:leftFormats[SCUKeyViews]];
    [views addEntriesFromDictionary:rightFormats[SCUKeyViews]];
    [views addEntriesFromDictionary:centerFormats[SCUKeyViews]];

    NSArray *formatString = @[];

    NSString *horizontalFormatString = @"";

    if (leftFormats[SCUKeyHorizontal])
    {
        horizontalFormatString = [horizontalFormatString stringByAppendingString:leftFormats[SCUKeyHorizontal]];
    }

    if (rightFormats[SCUKeyHorizontal])
    {
        if ([horizontalFormatString length])
        {
            horizontalFormatString = [horizontalFormatString stringByAppendingString:@"-(>=1)-"];
        }

        horizontalFormatString = [horizontalFormatString stringByAppendingString:rightFormats[SCUKeyHorizontal]];
    }

    if ([horizontalFormatString length])
    {
        formatString = [formatString arrayByAddingObject:horizontalFormatString];
    }

    if (centerFormats[SCUKeyHorizontal])
    {
        NSString *centerFormatString = @"";

        //-------------------------------------------------------------------
        // setup spacer1
        //-------------------------------------------------------------------
        UIView *spacerView1 = [[UIView alloc] init];
        [self.contentView addSubview:spacerView1];
        [views addEntriesFromDictionary:@{@"spacer1": spacerView1}];

        centerFormatString = [centerFormatString stringByAppendingString:@"|[spacer1(>=1,==spacer2@500)]"];

        centerFormatString = [centerFormatString stringByAppendingString:centerFormats[SCUKeyHorizontal]];

        //-------------------------------------------------------------------
        // setup spacer2
        //-------------------------------------------------------------------
        UIView *spacerView2 = [[UIView alloc] init];
        [self.contentView addSubview:spacerView2];
        [views addEntriesFromDictionary:@{@"spacer2": spacerView2}];

        centerFormatString = [centerFormatString stringByAppendingString:@"[spacer2(>=1,==spacer1@500)]|"];

        formatString = [formatString arrayByAddingObject:centerFormatString];
    }

    formatString = [formatString arrayByAddingObjectsFromArray:leftFormats[SCUKeyVertical]];
    formatString = [formatString arrayByAddingObjectsFromArray:rightFormats[SCUKeyVertical]];
    formatString = [formatString arrayByAddingObjectsFromArray:centerFormats[SCUKeyVertical]];

    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil views:views formats:formatString]];

    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (NSDictionary *)visualFormatsForViews:(NSArray *)views layoutDirection:(SCUToolbarLayoutDirection)direction spacing:(NSNumber *)spacing
{
    NSDictionary *visualFormats = nil;

    if ([views count])
    {
        NSMutableDictionary *viewDictionary = [NSMutableDictionary dictionary];

        NSString *spacer = @"-";

        if (spacing)
        {
            spacer = [spacer stringByAppendingFormat:@"(%@)-", spacing];
        }

        NSInteger viewCount = 0;
        for (UIView *view in views)
        {
            [self.contentView addSubview:view];

            viewDictionary[[NSString stringWithFormat:@"view%ld%lu", (long)viewCount++, (unsigned long)direction]] = view;
        }

        NSString *horizontalFormat = nil;
        NSMutableArray *verticalFormats = [NSMutableArray array];

        NSArray *sortedViewNames = [[viewDictionary allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *view1, NSString *view2) {
            return [view1 compare:view2 options:NSCaseInsensitiveSearch | NSNumericSearch];
        }];

        for (NSString *viewName in sortedViewNames)
        {
            UIView *view = viewDictionary[viewName];

            NSString *widthConstraint = nil;

            if ([view isKindOfClass:[SCUToolbarButton class]])
            {
                widthConstraint = CGRectGetWidth(view.frame) ? [NSString stringWithFormat:@"%f@500,>=44@1000", CGRectGetWidth(view.frame)] : [NSString stringWithFormat:@">=44@1000"];
            }
            else if (CGRectGetWidth(view.frame))
            {
                widthConstraint = [NSString stringWithFormat:@"%f", CGRectGetWidth(view.frame)];
            }

            NSString *horizontal =  widthConstraint ? [NSString stringWithFormat:@"[%@(%@)]", viewName, widthConstraint] : [NSString stringWithFormat:@"[%@]", viewName];

            if (direction == SCUToolbarLeftLayout)
            {
                horizontal = [spacer stringByAppendingString:horizontal];
            }
            else if (direction == SCUToolbarCenterLayout)
            {
                if ([horizontalFormat length])
                {
                    horizontal = [spacer stringByAppendingString:horizontal];
                }
            }
            else
            {
                if ([UIDevice isPad] || ([UIDevice isPhone] && ![viewName isEqualToString:[sortedViewNames lastObject]]))
                {
                    horizontal = [horizontal stringByAppendingString:spacer];
                }
            }

            if (horizontalFormat)
            {
                horizontalFormat = [horizontalFormat stringByAppendingString:horizontal];
            }
            else
            {
                horizontalFormat = (direction == SCUToolbarLeftLayout) ? [NSString stringWithFormat:@"|%@", horizontal] : horizontal;
            }

            [verticalFormats addObject:[NSString stringWithFormat:@"%@.centerY = super.centerY", viewName]];

            if (!CGRectGetHeight(view.frame))
            {
                [verticalFormats addObject:[NSString stringWithFormat:@"%@.height = super.height", viewName]];
            }
            else
            {
                [verticalFormats addObject:[NSString stringWithFormat:@"%@.height = %f", viewName, CGRectGetHeight(view.frame)]];
            }
        }

        if (direction == SCUToolbarRightLayout)
        {
            horizontalFormat = [horizontalFormat stringByAppendingString:@"|"];
        }

        visualFormats = @{SCUKeyHorizontal: horizontalFormat ? horizontalFormat : @"", SCUKeyVertical: verticalFormats, SCUKeyViews: viewDictionary};
    }

    return visualFormats;
}

- (CGSize)sizeForBarItems:(NSArray *)items spacing:(NSNumber *)spacing
{
    CGFloat x = 0;
    CGFloat y = 0;

    for (id item in items)
    {
        UIView *view = nil;
        if ([self.viewControllers containsObject:item])
        {
            view = [(UIViewController *)item view];
        }
        else
        {
            view = (UIView *)item;
        }

        CGRect frame = view.frame;

        if (CGRectEqualToRect(frame, CGRectZero))
        {
            frame = CGRectMake(0, 0, view.intrinsicContentSize.width, view.intrinsicContentSize.height);
        }

        x += CGRectGetWidth(frame);

        CGFloat height = CGRectGetHeight(frame);
        y = height > y ? height : y;
    }

    x += [items count] * [spacing floatValue];

    return CGSizeMake(x, y);
}

- (void)scrollToItem:(UIView *)item animated:(BOOL)animated
{
    NSAssert(self.scrolling, @"Scrolling must be enabled to scroll to an item!");

    UIScrollView *scrollView = (UIScrollView *)self.contentView;
    [scrollView scrollRectToVisible:item.frame animated:animated];
}

#pragma mark - Toolbar Passthrough

- (void)setBarTintColor:(UIColor *)color
{
    self.backgroundColor = color;
}

- (UIColor *)barTintColor
{
    return self.backgroundColor;
}

#pragma mark - View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController viewDidAppear:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    for (UIViewController *viewController in self.viewControllers)
    {
        [viewController viewDidDisappear:animated];
    }
}

#pragma mark - Properties

- (void)setScrolling:(BOOL)scrolling
{
    if (scrolling != _scrolling)
    {
        _scrolling = scrolling;

        [self.contentView removeFromSuperview];

        if (self.scrolling)
        {
            SCUToolbarScrollView *scrollView = [[SCUToolbarScrollView alloc] initWithFrame:self.bounds];
            [self addSubview:scrollView];
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView.showsVerticalScrollIndicator = NO;
            scrollView.canCancelContentTouches = YES;

            self.contentView = scrollView;
            [self sav_addFlushConstraintsForView:self.contentView];
        }
        else
        {
            UIView *contentView = [[UIView alloc] initWithFrame:self.bounds];
            [self addSubview:contentView];
            self.contentView = contentView;
            [self sav_addFlushConstraintsForView:self.contentView];
        }
    }
}

- (CGSize)leftBarItemsSize
{
    return [self sizeForBarItems:self.leftBarItems spacing:self.leftBarItemSpacing];
}

- (CGSize)rightBarItemsSize
{
    return [self sizeForBarItems:self.rightBarItems spacing:self.rightBarItemSpacing];
}

@end
