//
//  UIImage+SAVExtensions.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "UIImage+SAVExtensions.h"
#import "UIFont+SAVExtensions.h"

@import Accelerate;
@import Darwin.C;

static NSCache *tintedImageCache = nil;

@implementation UIImage (SAVExtensions)

+ (instancetype)resizableImageOfColor:(UIColor *)color initialSize:(CGFloat)initialSize
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(initialSize, initialSize), NO, 0);

    [color setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, initialSize, initialSize)] fill];

    UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];

    UIGraphicsEndImageContext();

    return image;
}

- (instancetype)tintedImageWithColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(ctx, 0, self.size.height);
    CGContextScaleCTM(ctx, 1, -1);

    CGContextClipToMask(ctx, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage);
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, self.size.width, self.size.height));

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFont:(UIFont *)font maxWidth:(CGFloat)maxWidth
{
    CGFloat height = font.sav_renderHeight;

    CGFloat scale = 1;

    if (height < image.size.height)
    {
        scale = height / image.size.height;
    }
    else
    {
        scale = image.size.height / height;
    }

    if (maxWidth)
    {
        maxWidth = maxWidth / [UIScreen mainScreen].scale;

        if ((image.size.width / scale) > maxWidth)
        {
            scale = maxWidth / image.size.width;
        }
    }

    return [UIImage imageWithImage:image scale:scale];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFont:(UIFont *)font
{
    return [UIImage imageWithImage:image scaledToFont:font maxWidth:0];
}

+ (UIImage *)imageWithImage:(UIImage *)image scale:(CGFloat)scale
{
    return [UIImage imageWithCGImage:image.CGImage scale:1 / scale orientation:UIImageOrientationUp];
}

- (UIImage *)scaleToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)sav_aspectScaleToMaxDimension:(CGFloat)maxDimension
{
    UIImage *image = self;

    BOOL resizeImage = NO;

    CGSize size = self.size;

    if (size.width > maxDimension)
    {
        CGFloat scale = size.width / maxDimension;
        size.width = maxDimension;
        size.height /= scale;
        resizeImage = YES;
    }

    if (size.height > maxDimension)
    {
        CGFloat scale = size.height / maxDimension;
        size.height = maxDimension;
        size.width /= scale;
        resizeImage = YES;
    }

    if (resizeImage)
    {
        image = [self scaleToSize:size];
    }

    return image;
}

- (UIImage *)cropImageWithRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height);

    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));

    // draw image
    [self drawInRect:drawRect];

    // grab image
    UIImage *subImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return subImage;
}

- (UIImage *)roundedImageByRadius:(CGFloat)radius
{
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0, 0, self.size.width, self.size.height);
    imageLayer.contents = (id)self.CGImage;

    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = radius;

    UIGraphicsBeginImageContext(self.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}

- (UIImage *)stripOrientation
{
    UIImage *image = nil;

    if (self.imageOrientation == UIImageOrientationUp)
    {
        image = self;
    }
    else
    {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        [self drawInRect:(CGRect){{0, 0}, self.size}];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return image;
}

+ (UIImage *)sav_imageNamed:(NSString *)imageName tintColor:(UIColor *)color
{
    return [[self class] sav_imageNamed:imageName tintColor:color blur:NO];
}

+ (UIImage *)sav_imageNamed:(NSString *)imageName tintColor:(UIColor *)color blur:(BOOL)blur
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tintedImageCache = [[NSCache alloc] init];
    });

    UIImage *image = nil;
    NSString *uniqueImageName = imageName;

    if (color)
    {
        uniqueImageName = [self stringFromImageName:imageName andTintColor:color];
    }

    if (blur)
    {
        uniqueImageName = [@"blurred." stringByAppendingString:imageName];
    }

    image = [tintedImageCache objectForKey:uniqueImageName];

    if (!image)
    {
        image = [UIImage imageNamed:imageName];

        if (color)
        {
            image = [image tintedImageWithColor:color];
        }

        if (blur)
        {
            image = [image applySavantBlur];
        }

        if (image)
        {
            [tintedImageCache setObject:image forKey:uniqueImageName];
        }
    }

    return image;
}

+ (UIImage *)sav_imageNamed:(NSString *)imageName
{
    return [[self class] sav_imageNamed:imageName tintColor:nil blur:NO];
}

+ (UIImage *)sav_blurredImageNamed:(NSString *)imageName
{
    return [[self class] sav_imageNamed:imageName tintColor:nil blur:YES];
}

+ (void)sav_clearImageCache
{
    [tintedImageCache removeAllObjects];
}

+ (NSString *)stringFromImageName:(NSString *)imageName andTintColor:(UIColor *)color
{
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return [NSString stringWithFormat:@"%@%f%f%f%f", imageName, red, green, blue, alpha];
}

- (UIImage *)applySavantBlurWithRadius:(CGFloat)blurRadius
{
    return [self applyBlurWithRadius:blurRadius tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:1 maskImage:nil];
}

- (UIImage *)applySavantBlur
{
    return [self applySavantBlurWithRadius:6];
}

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }

    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;

    CGImageRef imageRef = self.CGImage;
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);

    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        CGContextRef effectInContext = CGBitmapContextCreate(nil, (size_t)self.size.width, (size_t)self.size.height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
        CGContextSetInterpolationQuality(effectInContext, kCGInterpolationLow);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);

        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);

        CGContextRef effectOutContext = CGBitmapContextCreate(nil, (size_t)self.size.width, (size_t)self.size.height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
        CGContextSetInterpolationQuality(effectOutContext, kCGInterpolationLow);

        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);

        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = (NSUInteger)(floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5));
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wvla"
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
#pragma clang diagnostic pop
            for (NSUInteger i = 0; i < matrixSize; ++i) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
                saturationMatrix[i] = (int16_t)roundf((float)floatingPointSaturationMatrix[i] * (float)divisor);
#pragma clang diagnostic pop
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        
        if (!effectImageBuffersAreSwapped)
        {
            CGImageRef newImage = CGBitmapContextCreateImage(effectOutContext);
            effectImage = [[UIImage alloc] initWithCGImage:newImage];
            CGImageRelease(newImage);
        }
        else
        {
            CGImageRef newImage = CGBitmapContextCreateImage(effectInContext);
            effectImage = [[UIImage alloc] initWithCGImage:newImage];
            CGImageRelease(newImage);
        }

        CGContextRelease(effectInContext);
        CGContextRelease(effectOutContext);
    }

    // Set up output context.
    CGContextRef outputContext = CGBitmapContextCreate(nil, (size_t)self.size.width, (size_t)self.size.height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
    CGContextSetInterpolationQuality(outputContext, kCGInterpolationLow);

    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, imageRef);

    // Draw effect image.
    if (hasBlur)
    {
        CGContextSaveGState(outputContext);

        if (maskImage)
        {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }

        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }

    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }

    CGImageRef newImage = CGBitmapContextCreateImage(outputContext);
    UIImage *blurredImage = [[UIImage alloc] initWithCGImage:newImage];
    CGImageRelease(newImage);
    CGContextRelease(outputContext);
    return blurredImage;
}

@end
