//
//  UIView+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIView+SAVExtensions.h"
#import "SAVUIKitExtensions.h"
#import "NSArray+SAVExtensions.h"

CGFloat const SAVViewAutoLayoutStandardSpace = -1;
static CGFloat SAVViewIgnoreFlag = -1;

@interface SAVViewDistributionConfiguration ()

- (NSString *)heightConstraintWithReferenceViewName:(NSString *)referenceViewName;

- (NSString *)widthConstraintWithReferenceViewName:(NSString *)referenceViewName;

- (NSString *)constraintWithReferenceViewName:(NSString *)referenceViewName min:(CGFloat)min max:(CGFloat)max fixed:(CGFloat)fixed;

- (NSString *)interSpacingConstraint;

@end

@implementation UIView (SAVExtensions)

#pragma mark - Distribution/positioning configuration

+ (instancetype)sav_viewWithEvenlyDistributedViews:(NSArray *)views withConfiguration:(SAVViewDistributionConfiguration *)configuration
{
    UIView *containerView = [[[self class] alloc] initWithFrame:CGRectZero];

    for (UIView *view in views)
    {
        [containerView addSubview:view];
    }

    [containerView sav_distributeViewsEvenly:views withConfiguration:configuration];

    return containerView;
}

- (void)sav_distributeViewsEvenly:(NSArray *)views withConfiguration:(SAVViewDistributionConfiguration *)configuration
{
    NSParameterAssert([views count]);

    __block NSString *referenceViewName = nil;
    NSMutableDictionary *viewsDict = [NSMutableDictionary dictionary];
    NSMutableArray *viewNames = [NSMutableArray array];

    [views enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        NSString *viewName = [NSString stringWithFormat:@"view%lu", (unsigned long)idx];
        viewsDict[viewName] = view;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (!referenceViewName && (configuration.distributeEvenly || (view == configuration.referenceView)))
        {
            referenceViewName = viewName;
        }
#pragma clang diagnostic pop

        [viewNames addObject:viewName];
    }];

    NSMutableArray *allFormats = [NSMutableArray array];

    if (configuration.vertical)
    {
        NSMutableArray *verticalFormats = [NSMutableArray array];

        for (NSString *viewName in viewNames)
        {
            [verticalFormats addObject:[NSString stringWithFormat:@"[%@%@]", viewName, [configuration heightConstraintWithReferenceViewName:referenceViewName]]];
            [allFormats addObject:[NSString stringWithFormat:@"|[%@%@]|", viewName, [configuration widthConstraintWithReferenceViewName:referenceViewName]]];
        }

        if (configuration.separatorBlock)
        {
            __block NSUInteger separatorCount = 0;
            verticalFormats = [[verticalFormats arrayByInterposingItemWithBlock:^id{
                UIView *separatorView = configuration.separatorBlock();
                [self addSubview:separatorView];
                NSString *separatorViewName = [NSString stringWithFormat:@"separatorView%lu", (unsigned long)separatorCount++];
                viewsDict[separatorViewName] = separatorView;
                [allFormats addObject:[NSString stringWithFormat:@"|[%@]|", separatorViewName]];
                return [NSString stringWithFormat:@"[%@(%f)]", separatorViewName, configuration.separatorSize];
            }] mutableCopy];
        }

        NSString *verticalFormat = [NSString stringWithFormat:@"V:|%@|", [verticalFormats componentsJoinedByString:[configuration interSpacingConstraint]]];
        [allFormats addObject:verticalFormat];
    }
    else
    {
        NSMutableArray *horizontalFormats = [NSMutableArray array];

        for (NSString *viewName in viewNames)
        {
            [horizontalFormats addObject:[NSString stringWithFormat:@"[%@%@]", viewName, [configuration widthConstraintWithReferenceViewName:referenceViewName]]];
            [allFormats addObject:[NSString stringWithFormat:@"V:|[%@%@]|", viewName, [configuration heightConstraintWithReferenceViewName:referenceViewName]]];
        }

        if (configuration.separatorBlock)
        {
            __block NSUInteger separatorCount = 0;
            horizontalFormats = [[horizontalFormats arrayByInterposingItemWithBlock:^id{
                UIView *separatorView = configuration.separatorBlock();
                [self addSubview:separatorView];
                NSString *separatorViewName = [NSString stringWithFormat:@"separatorView%lu", (unsigned long)separatorCount++];
                viewsDict[separatorViewName] = separatorView;
                [allFormats addObject:[NSString stringWithFormat:@"V:|[%@]|", separatorViewName]];
                return [NSString stringWithFormat:@"[%@(%f)]", separatorViewName, configuration.separatorSize];
            }] mutableCopy];
        }

        NSString *horizontalFormat = [NSString stringWithFormat:@"|%@|", [horizontalFormats componentsJoinedByString:[configuration interSpacingConstraint]]];
        [allFormats addObject:horizontalFormat];
    }

    [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                metrics:nil
                                                                  views:viewsDict
                                                                formats:allFormats]];
    
}

- (void)sav_setPositionWithConfiguration:(SAVViewPositioningConfiguration *)configuration
{
    if (!self.superview)
    {
        [NSException raise:NSInternalInconsistencyException format:@"view must have a superview"];
        return;
    }

    CGRect superBounds = self.superview.bounds;
    CGRect frame = CGRectZero;

    // Compute the width
    CGFloat width = configuration.position.size.width;
    NSParameterAssert(width >= 0);

    if (configuration.relativeViewPosition & SAVViewRelativePositionsWidth)
    {
        NSParameterAssert(configuration.relativeView);
        NSParameterAssert((configuration.relativePositions & SAVViewRelativePositionsWidth) == 0);
        frame.size.width = CGRectGetWidth(configuration.relativeView.bounds) * width;
    }
    else if (configuration.relativePositions & SAVViewRelativePositionsWidth)
    {
        frame.size.width = CGRectGetWidth(superBounds) * width;
    }
    else
    {
        frame.size.width = width;
    }

    // Compute the height
    CGFloat height = configuration.position.size.height;
    NSParameterAssert(height >= 0);

    if (configuration.relativeViewPosition & SAVViewRelativePositionsHeight)
    {
        NSParameterAssert(configuration.relativeView);
        NSParameterAssert((configuration.relativePositions & SAVViewRelativePositionsHeight) == 0);
        frame.size.height = CGRectGetHeight(configuration.relativeView.bounds) * height;
    }
    else if (configuration.relativePositions & SAVViewRelativePositionsHeight)
    {
        frame.size.height = CGRectGetWidth(superBounds) * height;
    }
    else
    {
        frame.size.height = height;
    }

    // Compute the x coordinate.
    CGFloat x = configuration.position.origin.x;

    if (configuration.relativeViewPosition & SAVViewRelativePositionsX)
    {
        NSParameterAssert(configuration.relativeView);
        NSParameterAssert((configuration.relativePositions & SAVViewRelativePositionsX) == 0);

        if (configuration.interSpace >= 0)
        {
            frame.origin.x = CGRectGetMaxX(configuration.relativeView.frame) + configuration.interSpace;
        }
        else
        {
            frame.origin.x = CGRectGetMinX(configuration.relativeView.frame) - configuration.interSpace - CGRectGetWidth(frame);
        }
    }
    else if (configuration.relativePositions & SAVViewRelativePositionsX)
    {
        NSParameterAssert(x >= 0);
        frame.origin.x = CGRectGetWidth(superBounds) * x;
    }
    else
    {
        if (x >= 0)
        {
            frame.origin.x = x;
        }
        else
        {
            frame.origin.x = CGRectGetWidth(superBounds) + x - CGRectGetWidth(frame);
        }
    }

    // Compute the y coordinate
    CGFloat y = configuration.position.origin.y;

    if (configuration.relativeViewPosition & SAVViewRelativePositionsY)
    {
        NSParameterAssert(configuration.relativeView);
        NSParameterAssert((configuration.relativePositions & SAVViewRelativePositionsY) == 0);

        if (configuration.interSpace >= 0)
        {
            frame.origin.y = CGRectGetMaxY(configuration.relativeView.frame) + configuration.interSpace;
        }
        else
        {
            frame.origin.y = CGRectGetMinY(configuration.relativeView.frame) + configuration.interSpace - CGRectGetHeight(frame);
        }
    }
    else if (configuration.relativePositions & SAVViewRelativePositionsY)
    {
        NSParameterAssert(y >= 0);
        frame.origin.y = CGRectGetHeight(superBounds) * y;
    }
    else
    {
        if (y >= 0)
        {
            frame.origin.y = y;
        }
        else
        {
            frame.origin.y = CGRectGetHeight(superBounds) + y - CGRectGetHeight(frame);
        }
    }
    
    self.frame = CGRectIntegral(frame);
}

#pragma mark - Autolayout helpers

- (void)sav_addConstraintsForView:(UIView *)view withEdgeInsets:(UIEdgeInsets)edgeInsets
{
    NSParameterAssert(view);

    NSDictionary *metrics = @{@"t": @(edgeInsets.top),
                              @"l": @(edgeInsets.left),
                              @"b": @(edgeInsets.bottom),
                              @"r": @(edgeInsets.right)};

    [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                metrics:metrics
                                                                  views:NSDictionaryOfVariableBindings(view)
                                                                formats:@[@"|-l-[view]-r-|",
                                                                          @"V:|-t-[view]-b-|"]]];
}

- (void)sav_addFlushConstraintsForView:(UIView *)view withPadding:(CGFloat)padding
{
    [self sav_addConstraintsForView:view withEdgeInsets:UIEdgeInsetsMake(padding, padding, padding, padding)];
}

- (void)sav_addFlushConstraintsForView:(UIView *)view
{
    [self sav_addFlushConstraintsForView:view withPadding:0];
}

- (void)sav_addCenteredConstraintsForView:(UIView *)view
{
    NSParameterAssert(view);
    [self sav_pinView:view withOptions:SAVViewPinningOptionsCenterX | SAVViewPinningOptionsCenterY];
}

- (void)sav_pinView:(UIView *)view withOptions:(SAVViewPinningOptions)options
{
    [self sav_pinView:view withOptions:options withSpace:0];
}

- (void)sav_pinView:(UIView *)view withOptions:(SAVViewPinningOptions)options withSpace:(CGFloat)space
{
    NSMutableArray *formats = [NSMutableArray array];

    NSString *layoutSpace = nil;

    if (space == SAVViewAutoLayoutStandardSpace)
    {
        if (options & SAVViewPinningOptionsCenterX || options & SAVViewPinningOptionsCenterY || options & SAVViewPinningOptionsLeading || options & SAVViewPinningOptionsTrailing || options & SAVViewPinningOptionsBaseline)
        {
            [NSException raise:NSInternalInconsistencyException format:@"CenterX, CenterY, Leading, Trailing, and Baseline may not be used with SAVViewAutoLayoutStandardSpace"];
            return;
        }
        
        layoutSpace = @"-";
    }
    else if (space == 0)
    {
        layoutSpace = @"";
    }
    else
    {
        layoutSpace = [NSString stringWithFormat:@"-(%f)-", space];
    }

    if (!options)
    {
        return;
    }

    if (options & SAVViewPinningOptionsToTop)
    {
        [formats addObject:[NSString stringWithFormat:@"V:|%@[view]", layoutSpace]];
    }

    if (options & SAVViewPinningOptionsToLeft)
    {
        [formats addObject:[NSString stringWithFormat:@"|%@[view]", layoutSpace]];
    }

    if (options & SAVViewPinningOptionsToBottom)
    {
        [formats addObject:[NSString stringWithFormat:@"V:[view]%@|", layoutSpace]];
    }

    if (options & SAVViewPinningOptionsToRight)
    {
        [formats addObject:[NSString stringWithFormat:@"[view]%@|", layoutSpace]];
    }

    if (options & SAVViewPinningOptionsVertically)
    {
        [formats addObject:[NSString stringWithFormat:@"V:|%@[view]%@|", layoutSpace, layoutSpace]];
    }

    if (options & SAVViewPinningOptionsHorizontally)
    {
        [formats addObject:[NSString stringWithFormat:@"|%@[view]%@|", layoutSpace, layoutSpace]];
    }

    if (options & SAVViewPinningOptionsCenterX)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"view.centerX = super.centerX + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"view.centerX = super.centerX - %f", fabs(space)]];
        }
    }

    if (options & SAVViewPinningOptionsCenterY)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"view.centerY = super.centerY + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"view.centerY = super.centerY - %f", fabs(space)]];
        }
    }
    
    if (options & SAVViewPinningOptionsLeading)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"view.leading = super.leading + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"view.leading = super.leading - %f", fabs(space)]];
        }
    }
    
    if (options & SAVViewPinningOptionsTrailing)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"view.trailing = super.trailing + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"view.trailing = super.trailing - %f", fabs(space)]];
        }
    }
    
    if (options & SAVViewPinningOptionsBaseline)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"view.baseline = super.baseline + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"view.baseline = super.baseline - %f", fabs(space)]];
        }
    }

    [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                  views:@{@"view": view}
                                                                formats:formats]];
}

- (void)sav_pinView:(UIView *)pinView withOptions:(SAVViewPinningOptions)options ofView:(UIView *)baseView withSpace:(CGFloat)space
{
    NSParameterAssert(pinView);
    NSParameterAssert(baseView);

    NSString *layoutSpace = nil;

    if (space == SAVViewAutoLayoutStandardSpace)
    {
        if (options & SAVViewPinningOptionsCenterX || options & SAVViewPinningOptionsCenterY || options & SAVViewPinningOptionsLeading || options & SAVViewPinningOptionsTrailing || options & SAVViewPinningOptionsBaseline)
        {
            [NSException raise:NSInternalInconsistencyException format:@"CenterX, CenterY, Leading, Trailing, and Baseline may not be used with SAVViewAutoLayoutStandardSpace"];
            return;
        }
        
        layoutSpace = @"-";
    }
    else if (space == 0)
    {
        layoutSpace = @"";
    }
    else
    {
        layoutSpace = [NSString stringWithFormat:@"-(%f)-", space];
    }

    NSMutableArray *formats = [NSMutableArray array];

    if (options & SAVViewPinningOptionsToTop)
    {
        [formats addObject:[NSString stringWithFormat:@"V:[pinView]%@[baseView]", layoutSpace]];
    }
    else if (options & SAVViewPinningOptionsToLeft)
    {
        [formats addObject:[NSString stringWithFormat:@"[pinView]%@[baseView]", layoutSpace]];
    }
    else if (options & SAVViewPinningOptionsToBottom)
    {
        [formats addObject:[NSString stringWithFormat:@"V:[baseView]%@[pinView]", layoutSpace]];
    }
    else if (options & SAVViewPinningOptionsToRight)
    {
        [formats addObject:[NSString stringWithFormat:@"[baseView]%@[pinView]", layoutSpace]];
    }

    if (options & SAVViewPinningOptionsCenterX)
    {
        [formats addObject:[NSString stringWithFormat:@"pinView.centerX = baseView.centerX"]];
    }

    if (options & SAVViewPinningOptionsCenterY)
    {
        [formats addObject:[NSString stringWithFormat:@"pinView.centerY = baseView.centerY"]];
    }
    
    if (options & SAVViewPinningOptionsLeading)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.leading = baseView.leading + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.leading = baseView.leading - %f", fabs(space)]];
        }
    }
    
    if (options & SAVViewPinningOptionsTrailing)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.trailing = baseView.trailing + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.trailing = baseView.trailing - %f", fabs(space)]];
        }
    }
    
    if (options & SAVViewPinningOptionsBaseline)
    {
        if (space >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.baseline = baseView.baseline + %f", space]];
        }
        else
        {
            [formats addObject:[NSString stringWithFormat:@"pinView.baseline = baseView.baseline - %f", fabs(space)]];
        }
    }

    if (![formats count])
    {
        [NSException raise:NSInternalInconsistencyException format:@"Invalid pinning option: %lu %s", (unsigned long)options, __PRETTY_FUNCTION__];
        return;
    }

    NSDictionary *views = @{@"baseView": baseView,
                            @"pinView": pinView};

    [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil views:views formats:formats]];
}

- (void)sav_setSize:(CGSize)size forView:(UIView *)view isRelative:(BOOL)isRelative
{
    [self sav_setHeight:size.height forView:view isRelative:isRelative];
    [self sav_setWidth:size.width forView:view isRelative:isRelative];
}

- (void)sav_setWidth:(CGFloat)width forView:(UIView *)view isRelative:(BOOL)isRelative
{
    if (isRelative)
    {
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"percentage": @(width)}
                                                                      views:@{@"view": view}
                                                                    formats:@[@"view.width = super.width * percentage"]]];
    }
    else
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[view(width)]"
                                                                     options:0
                                                                     metrics:@{@"width": @(width)}
                                                                       views:@{@"view": view}]];
    }
}

- (void)sav_setHeight:(CGFloat)height forView:(UIView *)view isRelative:(BOOL)isRelative
{
    if (isRelative)
    {
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"percentage": @(height)}
                                                                      views:@{@"view": view}
                                                                    formats:@[@"view.height = super.height * percentage"]]];
    }
    else
    {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(height)]"
                                                                     options:0
                                                                     metrics:@{@"height": @(height)}
                                                                       views:@{@"view": view}]];
    }
}

- (void)sav_setY:(CGFloat)y forView:(UIView *)view isRelative:(BOOL)isRelative
{
    if (isRelative)
    {
        UIView *dummyView = [UIView sav_viewWithColor:[UIColor clearColor]];
        [self addSubview:dummyView];
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"percentage": @(y)}
                                                                      views:@{@"view": view, @"dummy": dummyView}
                                                                    formats:@[@"dummy.top = super.top",
                                                                              @"dummy.height = super.height * percentage",
                                                                              @"view.top = dummy.bottom"]]];
    }
    else
    {
        [self addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"position": @(y)}
                                                                      views:@{@"view": view}
                                                                    formats:@[@"view.top = position"]]];
    }
}

#pragma mark - Layer shortcuts

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}

- (void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

#pragma mark - Utilities

- (NSArray *)sav_allSubviews
{
    NSMutableArray *array = [NSMutableArray arrayWithObject:self];

    for (UIView *view in self.subviews)
    {
        [array addObjectsFromArray:[view sav_allSubviews]];
    }

    return [array copy];
}

- (UIImage *)sav_rasterizedImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (instancetype)sav_topView
{
    UIWindow *window = nil;

    for (UIWindow *w in [[[UIApplication sav_sharedApplicationOrException] windows] reverseObjectEnumerator])
    {
        if (w.windowLevel == UIWindowLevelNormal)
        {
            window = w;
        }
    }

    return window;
}

- (void)sav_setUserInteractionEnabledForSubviews:(BOOL)enabled
{
    for (UIView *view in self.subviews)
    {
        view.userInteractionEnabled = enabled;
    }
}

+ (instancetype)sav_viewWithColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = color;
    return view;
}

#pragma mark - Debugging helpers

- (void)sav_debugBorders
{
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor sav_randomColor].CGColor;
}

@end

@implementation SAVViewDistributionConfiguration

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.fixedWidth = SAVViewIgnoreFlag;
        self.fixedHeight = SAVViewIgnoreFlag;
        self.minimumWidth = SAVViewIgnoreFlag;
        self.minimumHeight = SAVViewIgnoreFlag;
        self.maximumWidth = SAVViewIgnoreFlag;
        self.maximumHeight = SAVViewIgnoreFlag;
        self.interSpace = SAVViewAutoLayoutStandardSpace;
    }

    return self;
}

- (NSString *)heightConstraintWithReferenceViewName:(NSString *)referenceViewName
{
    return [self constraintWithReferenceViewName:referenceViewName min:self.minimumHeight max:self.maximumHeight fixed:self.fixedHeight];
}

- (NSString *)widthConstraintWithReferenceViewName:(NSString *)referenceViewName
{
    return [self constraintWithReferenceViewName:referenceViewName min:self.minimumWidth max:self.maximumWidth fixed:self.fixedWidth];
}

- (NSString *)constraintWithReferenceViewName:(NSString *)referenceViewName min:(CGFloat)min max:(CGFloat)max fixed:(CGFloat)fixed
{
    NSString *constraint = nil;

    if (fixed >= 0)
    {
        constraint = [NSString stringWithFormat:@"==%f", fixed];
    }
    else
    {
        NSMutableArray *formats = [NSMutableArray array];

        if (referenceViewName)
        {
            [formats addObject:[NSString stringWithFormat:@"==%@", referenceViewName]];
        }

        if (min >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@">=%f", min]];
        }

        if (max >= 0)
        {
            [formats addObject:[NSString stringWithFormat:@"<=%f", max]];
        }

        constraint = [formats componentsJoinedByString:@","];
    }

    if ([constraint length])
    {
        return [NSString stringWithFormat:@"(%@)", constraint];
    }
    else
    {
        return @"";
    }
}

- (NSString *)interSpacingConstraint
{
    NSString *interSpacingConstraint = nil;

    if (self.interSpace == SAVViewAutoLayoutStandardSpace || self.interSpace < 0)
    {
        interSpacingConstraint = @"-";
    }
    else
    {
        interSpacingConstraint = [NSString stringWithFormat:@"-%f-", self.interSpace];
    }

    return interSpacingConstraint;
}

- (id)copyWithZone:(NSZone *)zone
{
    SAVViewDistributionConfiguration *configuration = [[[self class] alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    configuration.referenceView = self.referenceView;
#pragma clang diagnostic pop
    configuration.distributeEvenly = self.distributeEvenly;
    configuration.fixedWidth = self.fixedWidth;
    configuration.fixedHeight = self.fixedHeight;
    configuration.minimumWidth = self.minimumWidth;
    configuration.minimumHeight = self.minimumHeight;
    configuration.maximumWidth = self.maximumWidth;
    configuration.maximumHeight = self.maximumHeight;
    configuration.interSpace = self.interSpace;
    configuration.vertical = self.vertical;
    configuration.separatorSize = self.separatorSize;
    configuration.separatorBlock = self.separatorBlock;
    return configuration;
}

@end

@implementation SAVViewPositioningConfiguration

@end
