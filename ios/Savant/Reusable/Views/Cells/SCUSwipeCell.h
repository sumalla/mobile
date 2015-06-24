//
//  SCUSwipeCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Extensions;

typedef NS_ENUM(NSInteger, SCUTableViewCellAccessory) {
    SCUTableViewCellAccessoryLock = 1000,
    SCUTableViewCellAccessoryChevronDown,
    SCUTableViewCellAccessoryChevronUp
};

extern NSString *const SCUSwipeCellAccessoryImageName;

@protocol SCUSwipeCellDelegate <NSObject>

@optional

- (BOOL)tableView:(UITableView *)tableView shouldAllowSwipeForIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView buttonWasTappedAtIndex:(NSUInteger)buttonIndex inCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface SCUSwipeCell : UITableViewCell

/**
 *  Set the sliding buttons.
 */
@property (nonatomic) NSArray *rightButtons;

/**
 *  YES if the buttons are visible; otherwise, NO.
 */
@property (nonatomic, readonly, getter = isOpen) BOOL open;

/**
 *  Show the buttons.
 *
 *  @param animated   YES to animate the showing; otherwise, NO.
 *  @param completion A block to perform after the buttons are shown; otherwise, NULL.
 */
- (void)openAnimated:(BOOL)animated completion:(dispatch_block_t)completion;

/**
 *  Hide the buttons.
 *
 *  @param animated   YES to animate the hiding; otherwise, NO.
 *  @param completion A block to perform after the button are hidden; otherwise, NULL.
 */
- (void)closeAnimated:(BOOL)animated completion:(dispatch_block_t)completion;

/**
 *  Configure the cell with a model object.
 *
 *  @param info The model object.
 */
- (void)configureWithInfo:(NSDictionary *)info;

/**
 *  This method will return a valid view with a title for use with the rightButtons property.
 *
 *  @param title           The title.
 *  @param font            The title font, or nil for the default.
 *  @param color           The title's text color.
 *  @param backgroundColor The background color.
 *
 *  @return A button appropriate for use with the rightButtons property.
 */
+ (UIView *)buttonViewWithTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor;

/**
 *  This method will return a valid view with an image for use with the rightButtons property.
 *
 *  @param imageName       The image name.
 *  @param color           The image's tint color or nil if the image is already the correct color.
 *  @param backgroundColor The background color.
 *
 *  @return A button appropriate for use with the rightButtons property.
 */
+ (UIView *)buttonViewWithImageName:(NSString *)imageName color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor;

@end
