//
//  UIView+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

/**
 *  Use this value where you would normally have written a '-' in the visual format language.
 */
extern CGFloat const SAVViewAutoLayoutStandardSpace;

/**
 *  This block should return a view to be used as a separator in a distributed view configuration. If UIView responded to some form of NSCopying, then we wouldn't need this.
 *
 *  @return A separator view.
 */
typedef UIView * (^SAVViewDistributionConfigurationSeparator)(void);

@interface SAVViewDistributionConfiguration : NSObject <NSCopying>

/**
 *  Assign a reference view for sizing. This is the equivalent of doing "[view1(==referenceView]" or its veritcal equivalent.
 */
@property (nonatomic, weak) UIView *referenceView __attribute((deprecated("Use the distributeEvenly property instead.")));

/**
 *  YES if all views should be distributed evenly. The default is NO. This is the equivalent of doing "[view1(==referenceView]" or its veritcal equivalent.
 */
@property (nonatomic) BOOL distributeEvenly;

/**
 *  Assign a fixed width to all views.
 */
@property (nonatomic) CGFloat fixedWidth;

/**
 *  Assign a fixed height to all views.
 */
@property (nonatomic) CGFloat fixedHeight;

/**
 *  Assign a minimum width to all views.
 */
@property (nonatomic) CGFloat minimumWidth;

/**
 *  Assign a minimum height to all views.
 */
@property (nonatomic) CGFloat minimumHeight;

/**
 *  Assign a maximum width to all views.
 */
@property (nonatomic) CGFloat maximumWidth;

/**
 *  Assign a maximum height to all views.
 */
@property (nonatomic) CGFloat maximumHeight;

/**
 *  Assign the space between items. The default is SAVViewAutoLayoutStandardSpace.
 */
@property (nonatomic) CGFloat interSpace;

/**
 *  YES if views should be distributed vertically; NO for horizontally. The default is horizontal.
 */
@property (nonatomic) BOOL vertical;

/**
 *  Use this if you need a custom separator between each view.
 */
@property (nonatomic, copy) SAVViewDistributionConfigurationSeparator separatorBlock;

/**
 *  Define the size of the separator. This will be applied either veritcally or horizontally, depending on the @p vertical property.
 */
@property (nonatomic) CGFloat separatorSize;

@end

typedef NS_OPTIONS(NSUInteger, SAVViewRelativePositions)
{
    SAVViewRelativePositionsX      = 1 << 0,
    SAVViewRelativePositionsY      = 1 << 1,
    SAVViewRelativePositionsWidth  = 1 << 2,
    SAVViewRelativePositionsHeight = 1 << 3
};

@interface SAVViewPositioningConfiguration : NSObject

@property (nonatomic) CGRect position;
@property (nonatomic) SAVViewRelativePositions relativePositions;

@property (nonatomic) CGFloat interSpace;
@property (nonatomic) UIView *relativeView;
@property (nonatomic) SAVViewRelativePositions relativeViewPosition;

@end

typedef NS_OPTIONS(NSUInteger, SAVViewPinningOptions)
{
    SAVViewPinningOptionsNone         = 1 << 0,
    SAVViewPinningOptionsToTop        = 1 << 1,
    SAVViewPinningOptionsToLeft       = 1 << 2,
    SAVViewPinningOptionsToBottom     = 1 << 3,
    SAVViewPinningOptionsToRight      = 1 << 4,
    SAVViewPinningOptionsVertically   = 1 << 5,
    SAVViewPinningOptionsHorizontally = 1 << 6,
    SAVViewPinningOptionsCenterX      = 1 << 7,
    SAVViewPinningOptionsCenterY      = 1 << 8,
    SAVViewPinningOptionsLeading      = 1 << 9,
    SAVViewPinningOptionsTrailing     = 1 << 10,
    SAVViewPinningOptionsBaseline     = 1 << 11,
};

@interface UIView (SAVExtensions)

#pragma mark - Distribution/positioning configuration

/**
 *  A convenience method for returning a container view wrapping an array of views distributed using the given configuration.
 *
 *  @param views         An array of views to distribute.
 *  @param configuration A view distribution configuration.
 *
 *  @return A newly created view.
 */
+ (instancetype)sav_viewWithEvenlyDistributedViews:(NSArray *)views withConfiguration:(SAVViewDistributionConfiguration *)configuration;

/**
 *  Distribute views in an existing view.
 *
 *  @param views         An array of views to distribute.
 *  @param configuration A view distribution configuraiton.
 */
- (void)sav_distributeViewsEvenly:(NSArray *)views withConfiguration:(SAVViewDistributionConfiguration *)configuration;

/**
 *  Set the receiver's frame in its parent with the given positioning configuration.
 *
 *  @param configuration A view positioning configuration.
 */
- (void)sav_setPositionWithConfiguration:(SAVViewPositioningConfiguration *)configuration;

#pragma mark - Autolayout helpers

/**
 *  Position the given view in the receiver as flush, but with the given edge insets.
 *
 *  @param view       The view to position in the receiver.
 *  @param edgeInsets The edge insets.
 */
- (void)sav_addConstraintsForView:(UIView *)view withEdgeInsets:(UIEdgeInsets)edgeInsets;

/**
 *  Position the given view in the receiver as flush, but with constant padding all around it.
 *
 *  @param view    The view to position in the receiver.
 *  @param padding The constant padding around the view.
 */
- (void)sav_addFlushConstraintsForView:(UIView *)view withPadding:(CGFloat)padding;

/**
 *  Position the given view in the receiver as flush.
 *
 *  @param view The view to position in the receiver.
 */
- (void)sav_addFlushConstraintsForView:(UIView *)view;

/**
 *  Pin a view to the center X and center Y of the receiver.
 *
 *  @param view The view to pin to the center of the receiver.
 */
- (void)sav_addCenteredConstraintsForView:(UIView *)view;

/**
 *  Pin a view in the receiver with the given options.
 *
 *  @param view    The view to pin in the receiver.
 *  @param options A bit mask of pinning options.
 */
- (void)sav_pinView:(UIView *)view withOptions:(SAVViewPinningOptions)options;

/**
 *  Pin a view in the receiver with the given options and space.
 *
 *  @param view    The view to pin in the receiver.
 *  @param options A bit mask of pinning options.
 *  @param space   A space. Negative values are accepted.
 */
- (void)sav_pinView:(UIView *)view withOptions:(SAVViewPinningOptions)options withSpace:(CGFloat)space;

/**
 *  Pin a view in the receiver in relation to a second view with the given options and spacing.
 *
 *  @param view    The view to pin relative to the pinView.
 *  @param options A bit mask of pinning options.
 *  @param pinView The relative view.
 *  @param space   A space. Negative values are accepted.
 */
- (void)sav_pinView:(UIView *)view withOptions:(SAVViewPinningOptions)options ofView:(UIView *)pinView withSpace:(CGFloat)space;

/**
 *  Set the size of the given view in the receiver.
 *
 *  @param size       The size.
 *  @param view       The view to size.
 *  @param isRelative If YES, CGSizeMake(1, .5) would be interpreted as 100% height as the receiver, and half with width. If NO, the size is treated as regular points.
 */
- (void)sav_setSize:(CGSize)size forView:(UIView *)view isRelative:(BOOL)isRelative;

/**
 *  Set the width of the given view in the receiver.
 *
 *  @param width      The width.
 *  @param view       The view to size.
 *  @param isRelative If YES, .5 would give the view half the width of the receiver. If NO, the size is treated as a regular point value.
 */
- (void)sav_setWidth:(CGFloat)width forView:(UIView *)view isRelative:(BOOL)isRelative;

/**
 *  Set the height of the given view in the receiver.
 *
 *  @param height     The height.
 *  @param view       The view to size.
 *  @param isRelative If YES, .5 would give the view half the height of the receiver. If NO, the size is treated as a regular point value.
 */
- (void)sav_setHeight:(CGFloat)height forView:(UIView *)view isRelative:(BOOL)isRelative;

/**
 *  Set the y coordinate of the given view in the receiver.
 *
 *  @param y          The y value.
 *  @param view       The view to position.
 *  @param isRelative If YES, .5 would position the top of the view in the middle of the receiver. If NO, the size is treated as a regular point value.
 */
- (void)sav_setY:(CGFloat)y forView:(UIView *)view isRelative:(BOOL)isRelative;

#pragma mark - Layer shortcuts

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic) UIColor *borderColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat borderWidth  UI_APPEARANCE_SELECTOR;

#pragma mark - Utilites

/**
 *  Returns an array of all subviews, recursively, of the receiver.
 *
 *  @return An array of all subviews, recursively, of the receiver.
 */
- (NSArray *)sav_allSubviews;

/**
 *  Returns the top most view in the application.
 *
 *  @return The top most view in the application.
 */
+ (instancetype)sav_topView;

/**
 *  Returns an image of the receiver.
 *
 *  @return An image of the receiver.
 */
- (UIImage *)sav_rasterizedImage;

/**
 *  Recursively set userInteractionEnabled to the given value on all subviews of the receiver.
 *
 *  @param enabled YES to enable views; otherwise, NO.
 */
- (void)sav_setUserInteractionEnabledForSubviews:(BOOL)enabled;

/**
 *  A convenience method to return a @p CGRectZero view with the given color.
 *
 *  @param color The color to set as the new views backgroundColor.
 *
 *  @return A new view with the given background color and a frame of @p CGRectZero.
 */
+ (instancetype)sav_viewWithColor:(UIColor *)color;

#pragma mark - Debugging helpers

/**
 *  Put a random-colored border around the receiver.
 */
- (void)sav_debugBorders;

@end
