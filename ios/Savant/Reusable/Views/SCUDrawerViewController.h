//
//  SCUDrawerViewController.h
//  SCUDrawerViewController
//
//  Created by Cameron Pulsford on 4/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, SCUDrawerSide)
{
    SCUDrawerSideNone,
    SCUDrawerSideLeft,
    SCUDrawerSideRight
};

typedef NS_ENUM(NSUInteger, SCUDrawerLevel)
{
    SCUDrawerLevelBelow,
    SCUDrawerLevelAbove
};

typedef NS_ENUM(NSUInteger, SCUDrawerGestureCompatibilityMode)
{
    SCUDrawerGestureCompatibilityModePreferClient,
    SCUDrawerGestureCompatibilityModePreferDrawer
};

@protocol SCUDrawerViewControllerDelegate, SCUDrawerViewControllerParallaxDelegate;

@interface SCUDrawerViewController : UIViewController

@property (nonatomic, weak) id<SCUDrawerViewControllerDelegate> __nullable delegate;

@property (nonatomic, weak) id<SCUDrawerViewControllerParallaxDelegate> __nullable parallaxDelegate;

#pragma mark - Configuration

/**
 *  The width of an open drawer in terms of the percentage of the root view controller's width. The default is 0.85.
 */
@property (nonatomic) CGFloat openWidthPercentage;

/**
 *  The maximum drawer width in points. The default is CGFLOAT_MAX. If you want to set this, generally you would want to additionally set openWidthPercentage to 1.
 */
@property (nonatomic) CGFloat maximumDrawerOpenWidth;

/**
 *  The intensity for the parallax effect. The default is 8
 */
@property (nonatomic) CGFloat parallaxIntensity;

/**
 *  The percentage of the screen you must drag before the drawer would open automatically. The default is 1/5.
 */
@property (nonatomic) CGFloat dragOpenThreshold;

/**
 *  If the drawer is opened less than 'dragOpenThreshold', but with a velocity greater than this, the drawer would still open. The default is 300.
 */
@property (nonatomic) CGFloat dragOpenVelocityThreshold;

/**
 *  If, given the drawers velocity, the drawer would open/close greater than this duration, this duration will be used instead. The default is 0.4.
 */
@property (nonatomic) NSTimeInterval maximumAnimationDuration;

/**
 *  If, given the drawers velocity, the drawer would open/close less than this duration, this duration will be used instead. The default is 0.4.
 */
@property (nonatomic) NSTimeInterval minimumAnimationDuration;

/**
 *  If this value is 1, the whole screen is draggable. Lower this value to make only a percentage of the screen draggable. The default is .15.
 */
@property (nonatomic) CGFloat edgeDraggingThreshold;

/**
 *  Shows an overlay above the background view in SCUDrawerLevelAbove mode. The default is YES.
 */
@property (nonatomic) BOOL showOverlay;

/**
 *  Shows a shadow underneath the slider drawer. The default is YES;
 */
@property (nonatomic) BOOL showShadow;

/**
 *  Use this if you want a drawer to be positioned below a navbar. The default is NO.
 *  This value will only be applied to drawers that use the SCUDrawerLevelAbove level.
 */
@property (nonatomic) BOOL positionAboveDrawerBelowNavBar;

#pragma mark - State

/**
 *  YES if the drawer is open; otherwise, NO.
 */
@property (nonatomic, readonly, getter = isOpen) BOOL open;

/**
 *  The side of the drawer that's open; otherwise, SCUDrawerSideNone.
 */
@property (nonatomic, readonly) SCUDrawerSide openSide;

/**
 *  Access the left, root, and right view controllers.
 */
@property (nonatomic, readonly) UIViewController * __nullable rootViewController;
@property (nonatomic, readonly) UIViewController * __nullable leftViewController;
@property (nonatomic, readonly) UIViewController * __nullable rightViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Initializes a new drawer view controller with the given root view controller.
 *
 *  @param rootViewController The root or main view controller of the drawer.
 *
 *  @return An initialized drawer view controller.
 */
- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

/**
 *  Setup a drawer.
 *
 *  @param viewController The view controller.
 *  @param drawerSide     The side to present the view controller from.
 *  @param level          The level to present the view controller on.
 */
- (void)setViewController:(UIViewController *)viewController forSide:(SCUDrawerSide)drawerSide level:(SCUDrawerLevel)level;

/**
 *  This method sets up the given gesture recognizers to require that all of the drawer's internal gesture recognizers have failed.
 *
 *  @param gestureRecognizers An array of gesture recognizers.
 */
- (void)setupGestureRecognizerCompatibility:(NSArray *)gestureRecognizers compatibilityMode:(SCUDrawerGestureCompatibilityMode)compatibilityMode;

/**
 *  Open the drawer from the given side. If NO is returned, the completion handler is not run.
 *
 *  @param drawerSide The side to open the drawer from.
 *  @param animated   Pass YES to animate the opening; otherwise, pass NO.
 *  @param completion A completion handler or NULL.
 *
 *  @return YES if the drawer could be opened from the given side; otherwise, NO.
 */
- (BOOL)openDrawerFromSide:(SCUDrawerSide)drawerSide animated:(BOOL)animated completion:(__nullable dispatch_block_t)completion;

/**
 *  Open the drawer. If NO is returned, the completion handler is not run.
 *
 *  @param animated   Pass YES to animate the opening; otherwise, pass NO.
 *  @param completion A completion handler or NULL.
 *
 *  @return YES if only one drawer side is set and could be opened; otherwise, NO.
 */
- (BOOL)openDrawerAnimated:(BOOL)animated completion:(__nullable dispatch_block_t)completion;

/**
 *  Close the drawer. If NO is returned, the completion handler is not run.
 *
 *  @param animated   Pass YES to animate the closing; otherwise, pass NO.
 *  @param completion A completion handler or NULL.
 *
 *  @return YES of the drawer could be closed; otherwise, NO.
 */
- (BOOL)closeDrawerAnimated:(BOOL)animated completion:(__nullable dispatch_block_t)completion;

@end

@protocol SCUDrawerViewControllerParallaxDelegate <NSObject>

@optional

- (UIView *)addParallaxEffectsForDrawer:(SCUDrawerViewController *)drawer;

@end

@protocol SCUDrawerViewControllerDelegate <NSObject>

@optional

/**
 *  Implement this method if there are condition you would like to check before allowing a drawer to open/close.
 *
 *  @param drawer The drawer controller.
 *
 *  @return YES if dragging is allowed; otherwise, NO.
 *
 *  @note This will not be called when manually opening/closing the drawer.
 */
- (BOOL)shouldDrawer:(SCUDrawerViewController *)drawer beginDraggingFromSide:(SCUDrawerSide)drawerSide;

/**
 *  Implement this method if you wish to animate some items with the drawer opening/closing.
 *
 *  @param drawer          The drawer controller.
 *  @param drawerSide      The side the drawer is opened on, or closing from.
 *  @param percentComplete The percentage (0.0 -> 1.0) of how open the drawer is.
 */
- (void)drawer:(SCUDrawerViewController *)drawer isAnimatingSide:(SCUDrawerSide)drawerSide percentOpen:(CGFloat)percentComplete;

- (void)drawer:(SCUDrawerViewController *)drawer didOpenFromSide:(SCUDrawerSide)drawerSide;

- (void)drawer:(SCUDrawerViewController *)drawer didCloseFromSide:(SCUDrawerSide)drawerSide;

@end

NS_ASSUME_NONNULL_END
