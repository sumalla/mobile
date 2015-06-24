//
//  SCUButtonBase.h
//  SavantController
//
//  Created by Cameron Pulsford on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;
@import Extensions;

/**
 *  An SCUButtonStyle will define the default look of a button.
 */
typedef NS_ENUM(NSUInteger, SCUButtonStyle)
{
    /**
     *  Clear background. White text, with light selected color.
     */
    SCUButtonStyleLight,
    /**
     *  Clear background. White text, with orange selected color.
     */
    SCUButtonStyleLightAccent,
    /**
     *  Clear background. Orange text, with lighter orange selected color.
     */
    SCUButtonStyleAccent,
    /**
     *  Clear background. Black text, with a lighter selected color.
     */
    SCUButtonStyleDark,
    /**
     *  Black background, white text, orange selected color
     */
    SCUButtonStyleAVStandardGrouped,
    /**
     *  Same as @p SCUButtonStyleAVStandardGrouped, but with a light gray border.
     */
    SCUButtonStyleAVStandardSolo,
    /**
     *  A very rounded clear button with a white outline and a green selected fill.
     */
    SCUButtonStyleStandardPill,
    /**
     *  A very rounded clear button with a white outline and a green selected fill.
     */
    SCUButtonStyleStandardPillDark,
    /**
     *  A button styled to look like a hyperlink - white with a white underline
     */
    SCUButtonStyleUnderlinedText,
    /**
     *  A button styled to look like a hyperlink - dark text with a dark underline
     */
    SCUButtonStyleUnderlinedTextDark,
    /**
     *  A button styled to be clear and pinned to the bottom with light text color
     */
    SCUButtonStylePinnedButton,
    /**
     *  A button styled to be clear and pinned to the bottom with dark text color
     */
    SCUButtonStylePinnedButtonDark,
    /**
     *  No color set by default.
     */
    SCUButtonStyleCustom,
};

@interface SCUButton : UIButton

#pragma mark - Defining behavior

/**
 *  Set the button's target.
 */
@property (nonatomic, weak) id target;

/**
 *  Set the button's touch down action.
 */
@property (nonatomic) SEL pressAction;

/**
 *  TouchDown callback that is called on button press
 */
@property (nonatomic, copy) void (^pressCallback)(void);

/**
 *  Set the button's hold action.
 */
@property (nonatomic) SEL holdAction;

/**
 *  Hold callback.
 */
@property (nonatomic, copy) void (^holdCallback)(void);

/**
 *  Set the button's release action.
 */
@property (nonatomic) SEL releaseAction;

/**
 *  Release callback that is called on buttonRelease
 */
@property (nonatomic, copy) void (^releaseCallback)(void);

/**
 *  Duration between hold commands. If undefined, assumed to be a push button.
 */
@property (nonatomic) NSTimeInterval holdTime;

/**
 *  Duration of delay before hold commands are executed. The default is .8.
 */
@property (nonatomic) CGFloat holdDelay;

#pragma mark - Defining style

/**
 *  Define the color of the title or image when the button is in a normal state.
 */
@property (nonatomic) UIColor *color;

/**
 *  Define the color of the title or image when the button is in a selected state.
 */
@property (nonatomic) UIColor *selectedColor;

/**
 *  Define the color of the title or image when the button is in a disabled state.
 */
@property (nonatomic) UIColor *disabledColor;

/**
 *  Define the background color when the button is in a normal state.
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 *  Define the background color when the button is in a selected state.
 */
@property (nonatomic) UIColor *selectedBackgroundColor;

/**
 *  Define the background color when the button is in a disabled state.
 */
@property (nonatomic) UIColor *disabledBackgroundColor;

/**
 *  Define whether or not the corners should be rounded.
 */
@property (nonatomic) BOOL roundedCorners;

/**
 *  Define the insets for use in an UIBarButtonItem
 */
@property (nonatomic) UIEdgeInsets buttonInsets;

#pragma mark - Text properties

/**
 *  Set the title.
 */
@property (nonatomic) NSString *title;

/**
 *  Set the attributed title.
 */
@property (nonatomic) NSAttributedString *attributedTitle;

/**
 *  Set the title padding. The default is CGSizeMake(15, 10).
 */
@property (nonatomic) CGSize titlePadding;

#pragma mark - Image properties

/**
 *  If this is set to YES, the image that is set will be tinted to self.color. The default is YES.
 */
@property (nonatomic) BOOL tintImage;

/**
 *  If this is set to YES, the image that is set will be tinted to self.selectedColor. The default is YES.
 */
@property (nonatomic) BOOL tintSelectedImage;

/**
 *  If this is set to YES, the image will be scaled to be no taller than the current font.
 */
@property (nonatomic) BOOL scaleImageToFont;

/**
 *  Set the image.
 */
@property (nonatomic) UIImage *image;

/**
 *  Set the selected image. By default the main image will be used and tinted with selectedColor.
 */
@property (nonatomic) UIImage *selectedImage;

#pragma mark - View Properties

/**
 *  Set the custom content view.
 */
@property (nonatomic) UIView *contentView;

/**
 *  Set the selected custom content view.
 */
@property (nonatomic) UIView *selectedContentView;

/**
 *  Set the content view pinning options. Defaults to Vertically and Horizontally.
 */
@property (nonatomic) SAVViewPinningOptions contentViewPinning;

#pragma mark - Creation

/**
 *  Initializes a new SCUButton with the given style.
 *
 *  @param style The style.
 *
 *  @return An initialized SCUButton with the given style.
 */
- (instancetype)initWithStyle:(SCUButtonStyle)style;

/**
 *  Initializes a new SCUButton with the given style and title.
 *
 *  @param style The style.
 *  @param title The title.
 *
 *  @return An initialized SCUButton with the given style and title.
 */
- (instancetype)initWithStyle:(SCUButtonStyle)style title:(NSString *)title;

/**
 *  Initializes a new SCUButton with the given style and attributed title.
 *
 *  @param style           The style.
 *  @param attributedTitle The title.
 *
 *  @return An initialized SCUButton with the given style and attributed title.
 */
- (instancetype)initWithStyle:(SCUButtonStyle)style attributedTitle:(NSAttributedString *)attributedTitle;

/**
 *  Initializes a new SCUButton with given title and style SCUButtonStyleCustom.
 *
 *  @param title The title.
 *
 *  @return An initialized SCUButton with the given title and style SCUButtonStyleCustom.
 */
- (instancetype)initWithTitle:(NSString *)title;

/**
 *  Initializes a new SCUButton with the given style and image.
 *
 *  @param style The style.
 *  @param image The image.
 *
 *  @return An initialized SCUButton with the given style and image.
 */
- (instancetype)initWithStyle:(SCUButtonStyle)style image:(UIImage *)image;

/**
 *  Initializes a new SCUButton with given image and style SCUButtonStyleCustom.
 *
 *  @param image The image.
 *
 *  @return An initialized SCUButton with the given image and style SCUButtonStyleCustom.
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 *  Initializes a new SCUButton with the given style and image.
 *
 *  @param style The style.
 *  @param contentView The contentView.
 *
 *  @return An initialized SCUButton with the given style and contentView.
 */
- (instancetype)initWithStyle:(SCUButtonStyle)style contentView:(UIView *)contentView;

/**
 *  Initializes a new SCUButton with given image and style SCUButtonStyleCustom.
 *
 *  @param contentView The contentView.
 *
 *  @return An initialized SCUButton with the given contentView and style SCUButtonStyleCustom.
 */
- (instancetype)initWithContentView:(UIView *)contentView;

/**
 *  Initializes an SCUButton with style SCUButtonStyleCustom.
 *
 *  @return An initialized SCUButton with the style SCUButtonStyleCustom.
 */
- (instancetype)init;

#pragma mark - Applying custom styles

/**
 *  If performance is a concern, use this method to apply multiple style properties more efficiently.
 *
 *  @param block A style updating block.
 */
- (void)updateStyleWithBlock:(dispatch_block_t)block;

@end
