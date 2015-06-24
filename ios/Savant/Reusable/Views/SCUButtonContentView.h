//
//  SCUButtonContentView.h
//  SavantController
//
//  Created by Jason Wolkovitz on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUButtonContentView : UIView

@property (nonatomic) UIColor *color, *selectedColor;
@property (nonatomic) UIColor *imageColor, *selectedImageColor;
@property (nonatomic) UIColor *selectedBackgroundColor;
@property BOOL ignoreImageColor;

@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, getter = isSelected) BOOL selected;

@end
