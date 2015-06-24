//
//  SCUPickerView.h
//  SavantController
//
//  Created by David Fairweather on 4/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

typedef NS_OPTIONS(NSUInteger, SCUPickerViewConfiguration)
{
    SCUPickerViewConfigurationTwoArrowsHorizontal = 1 << 0,
    SCUPickerViewConfigurationTwoArrowsVertical = 1 << 1,
    SCUPickerViewConfigurationFourArrows = 1 << 2,
    SCUPickerViewConfigurationTwoArrowsVerticalClimate = 1 << 3,
};

typedef NS_ENUM(NSInteger, SCUPickerViewDirection)
{
    SCUPickerViewDirectionNone,
    SCUPickerViewDirectionUp,
    SCUPickerViewDirectionDown,
    SCUPickerViewDirectionLeft,
    SCUPickerViewDirectionRight
};

@class SCUButton;
@protocol SCUPickerViewDelegate;

typedef void (^SCUPickerViewHandler)(SCUPickerViewDirection direction);

@interface SCUPickerView : UIView

@property (nonatomic) NSInteger *currentValue;
@property (nonatomic, weak) id<SCUPickerViewDelegate> delegate;

@property (nonatomic) CGFloat holdTime;
@property (nonatomic) CGFloat holdDelay;
@property (nonatomic) NSString *title;

@property (nonatomic) UIColor *tintColor, *selectedTintColor;

@property (readonly) SCUButton *centerButton;

@property (strong) SCUPickerViewHandler handler, tappedHandler;

- (instancetype)initWithConfiguration:(SCUPickerViewConfiguration)config;
- (instancetype)initWithFrame:(CGRect)frame andConfiguration:(SCUPickerViewConfiguration)config;
- (void)enlargeButtonsInPickerViewBySize:(CGFloat)size;
- (void)changeColorOfButtonsToColor:(UIColor *)color;

@end

@protocol SCUPickerViewDelegate <NSObject>

@optional
- (void)pickerView:(SCUPickerView *)pickerView didSelectArrowWithDirection:(SCUPickerViewDirection)direction;
- (void)pickerView:(SCUPickerView *)pickerView didTapArrowWithDirection:(SCUPickerViewDirection)direction;

@end
