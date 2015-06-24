//
//  UIImage+SAVExtensions.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface UIImage (SAVExtensions)

+ (instancetype)resizableImageOfColor:(UIColor *)color initialSize:(CGFloat)initialSize;

- (instancetype)tintedImageWithColor:(UIColor *)color;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToFont:(UIFont *)font;
+ (UIImage *)imageWithImage:(UIImage *)image scale:(CGFloat)scale;

- (UIImage *)scaleToSize:(CGSize)newSize;
- (UIImage *)sav_aspectScaleToMaxDimension:(CGFloat)maxDimension;
- (UIImage *)cropImageWithRect:(CGRect)rect;
- (UIImage *)roundedImageByRadius:(CGFloat)radius;

- (UIImage *)stripOrientation;

+ (UIImage *)sav_imageNamed:(NSString *)imageName tintColor:(UIColor *)color;
+ (UIImage *)sav_imageNamed:(NSString *)imageName;
+ (UIImage *)sav_blurredImageNamed:(NSString *)imageName;

+ (void)sav_clearImageCache;

- (UIImage *)applySavantBlurWithRadius:(CGFloat)blurRadius;

- (UIImage *)applySavantBlur;

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
