//
//  SCUReorderableTileLayoutSpan.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/24/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUReorderableTileLayoutSpan.h"
#import "SCUReorderableTileLayoutSpanPrivate.h"

@implementation SCUReorderableTileLayoutSpan

+ (instancetype)spanWithWidth:(NSUInteger)width height:(NSUInteger)height
{
    SCUReorderableTileLayoutSpan *span = [[[self class] alloc] init];
    span.width = width;
    span.height = height;
    return span;
}

- (void)normalizeWithNumberOfColumns:(NSUInteger)numberOfColumns
{
    if (self.width < 1)
    {
        self.width = 1;
    }
    else if (self.width > numberOfColumns)
    {
        self.width = numberOfColumns;
    }

    if (self.height < 1)
    {
        self.height = 1;
    }
}

- (CGRect)frameWithPadding:(CGFloat)padding baseSize:(CGSize)baseSize insets:(UIEdgeInsets)insets
{
    CGRect frame = CGRectZero;

    frame.origin.x = [self absoluteXPositionForRelativePosition:self.column padding:padding baseSize:baseSize.width] + insets.left;
    frame.origin.y = [self absoluteYPositionForRelativePosition:self.row padding:padding baseSize:baseSize.height] + insets.top;
    frame.size.width = [self absoluteSizeForSpan:self.width padding:padding baseSize:baseSize.width];
    frame.size.height = [self absoluteSizeForSpan:self.height padding:padding baseSize:baseSize.height];

    return CGRectIntegral(frame);
}

- (CGFloat)absoluteXPositionForRelativePosition:(NSUInteger)relativePosition padding:(CGFloat)padding baseSize:(CGFloat)baseSize
{
    return (relativePosition * padding) + (relativePosition * baseSize);
}

- (CGFloat)absoluteYPositionForRelativePosition:(NSUInteger)relativePosition padding:(CGFloat)padding baseSize:(CGFloat)baseSize
{
    return (relativePosition * padding) + (relativePosition * baseSize);
}

- (CGFloat)absoluteSizeForSpan:(CGFloat)span padding:(CGFloat)padding baseSize:(CGFloat)baseSize
{
    return (baseSize * span) + ((span - 1) * padding);
}

- (id)copyWithZone:(NSZone *)zone
{
    SCUReorderableTileLayoutSpan *span = [[SCUReorderableTileLayoutSpan alloc] init];
    span.width = self.width;
    span.height = self.height;
    span.row = self.row;
    span.column = self.column;
    return span;
}

- (BOOL)isEqual:(id)object
{
    BOOL isEqual = [super isEqual:object];

    if (!isEqual && [object isKindOfClass:[self class]])
    {
        isEqual = [self isEqualToSpan:object];
    }

    return isEqual;
}

- (BOOL)isEqualToSpan:(SCUReorderableTileLayoutSpan *)span
{
    return self.width == span.width && self.height == span.height && self.column == span.column && self.row == span.row;
}

- (NSUInteger)hash
{
    return [[NSString stringWithFormat:@"%lu,%lu,%lu,%lu",
             (unsigned long)self.width,
             (unsigned long)self.height,
             (unsigned long)self.column,
             (unsigned long)self.row] hash];
}

- (NSString *)description
{
    return NSStringFromCGRect(CGRectMake(self.column, self.row, self.width, self.height));
}

- (NSComparisonResult)compare:(SCUReorderableTileLayoutSpan *)span options:(NSUInteger)options
{
    /* our sort function is expecting a string so this options argument is unused */
    NSComparisonResult result = NSOrderedSame;

    if (self.row == span.row)
    {
        if (self.column == span.column)
        {
            result = NSOrderedSame;
        }
        else if (self.column < span.column)
        {
            result = NSOrderedAscending;
        }
        else
        {
            result = NSOrderedDescending;
        }
    }
    else if (self.row < span.row)
    {
        result = NSOrderedAscending;
    }
    else
    {
        result = NSOrderedDescending;
    }

    return result;
}

@end
