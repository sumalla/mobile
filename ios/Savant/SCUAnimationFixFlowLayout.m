//
//  SCUAnimationFixFlowLayout.m
//  Prototype
//
//  Created by Nathan Trapp on 3/4/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUAnimationFixFlowLayout.h"

@interface SCUAnimationFixFlowLayout ()

@property (nonatomic) BOOL animatingBoundsChange;

@end

@implementation SCUAnimationFixFlowLayout

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
    [super prepareForAnimatedBoundsChange:oldBounds];
    self.animatingBoundsChange = YES;
}

- (void)finalizeAnimatedBoundsChange
{
    [super finalizeAnimatedBoundsChange];
    self.animatingBoundsChange = NO;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.animatingBoundsChange)
    {
        // If the view is rotating, appearing items should animate from their current attributes (specify `nil`).
        // Both of these appear to do much the same thing:
        //return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        return nil;
    }
    return [super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    if (self.animatingBoundsChange)
    {
        // If the view is rotating, disappearing items should animate to their new attributes.
        return [self layoutAttributesForItemAtIndexPath:itemIndexPath];
    }
    return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
}

@end
