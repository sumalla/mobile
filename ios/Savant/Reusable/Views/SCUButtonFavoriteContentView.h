//
//  SCUButtonFavoriteContentView.h
//  SavantController
//
//  Created by Jason Wolkovitz on 6/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButtonContentView.h"

@interface SCUButtonFavoriteContentView : SCUButtonContentView


@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *selectedImage;

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *selectedTextColor;

- (void)setText:(NSString *)text;

@end
