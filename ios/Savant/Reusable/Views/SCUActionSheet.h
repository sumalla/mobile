//
//  SCUActionSheet.m
//  SavantController
//
//  Created by Stephen Silber on 9/03/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;

typedef void (^SCUActionSheetCallback)(NSInteger buttonIndex);

@protocol SCUActionSheetDelegate;

@interface SCUActionSheet : UIView

@property (nonatomic, weak) id<SCUActionSheetDelegate> delegate;

@property (nonatomic) UIFont *titleFont;
@property (nonatomic) UIFont *buttonFont;
@property (nonatomic) UIFont *cancelButtonFont;

@property (nonatomic) UIColor *titleTextColor;
@property (nonatomic) UIColor *buttonTextColor;
@property (nonatomic) UIColor *cancelTextColor;
@property (nonatomic) UIColor *destructiveTextColor;

@property (nonatomic) UIColor *titleTextSelectedColor;
@property (nonatomic) UIColor *buttonTextSelectedColor;
@property (nonatomic) UIColor *cancelTextSelectedColor;
@property (nonatomic) UIColor *destructiveTextSelectedColor;

@property (nonatomic) UIColor *separatorColor;
@property (nonatomic) UIColor *buttonBackgroundColor;
@property (nonatomic) UIColor *buttonBackgroundSelectedColor;

@property (nonatomic) UIColor *cancelBackgroundColor;
@property (nonatomic) UIColor *cancelBackgroundSelectedColor;

@property (nonatomic) UIColor *destructiveBackgroundColor;
@property (nonatomic) UIColor *destructiveBackgroundSelectedColor;

@property (nonatomic, copy) SCUActionSheetCallback callback;

@property (nonatomic) UIView *maskingView;

@property (nonatomic, readonly) BOOL visible;

@property (nonatomic) BOOL showTableSeparatorLines;

@property (nonatomic) CGFloat maximumTableHeightPercentage; /* The default is 1 for full height */

- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles;
- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles cancelTitle:(NSString *)cancelTitle;
- (instancetype)initWithTitle:(NSString *)title buttonTitles:(NSArray *)buttonTitles;
- (instancetype)initWithTitle:(NSString *)title buttonTitles:(NSArray *)buttonTitles cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle;

- (void)showInView:(UIView *)view;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view withMaxWidth:(CGFloat)maxWidth;

- (NSInteger)addButton:(NSString *)buttonTitle;

- (void)setDestructiveButtonText:(NSString *)destructiveButtonTitle;
- (void)setCancelButtonText:(NSString *)cancelButtonTitle;
- (void)setButtonTitlesFromArray:(NSArray *)buttonTitles;

@end

@protocol SCUActionSheetDelegate <NSObject>

- (void)actionSheet:(SCUActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface SCUActionSheetCell : UITableViewCell

@end
