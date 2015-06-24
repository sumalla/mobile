//
//  SCULightingModelPrivate.h
//  
//
//  Created by Cameron Pulsford on 8/26/14.
//
//

#import "SCULightingModel.h"

typedef NS_OPTIONS(NSUInteger, SCULightingEntityType)
{
    SCULightingEntityTypeScene          = 1 << 0,
    SCULightingEntityTypeLightingDimmer = 1 << 1,
    SCULightingEntityTypeLightingSwitch = 1 << 2,
    SCULightingEntityTypeShadeDimmer    = 1 << 3,
    SCULightingEntityTypeShadeSwitch    = 1 << 4,
    SCULightingEntityTypeFan            = 1 << 5
};

extern NSString *const SCULightingSectionKey;
extern NSString *const SCULightingArrayKey;
extern NSString *const SCULightingStateKey;
extern NSString *const SCULightingModelType;
extern NSString *const SCULightingCellType;

@interface SCULightingModel ()

#pragma mark - Methods to subclass

/**
 *  Return the combination of lighting types you are interested in.
 *
 *  @return The combination of lighting types you are interested in.
 */
@property (nonatomic, readonly) SCULightingEntityType lightingTypes;

/**
 *  Called when the room image updates.
 */
- (void)roomImageDidUpdate:(UIImage *)image;

- (void)didLoadLightingData;

- (void)switchDidToggleOn:(BOOL)on forIndexPath:(NSIndexPath *)indexPath;

- (void)sliderDidUpdateToValue:(CGFloat)value forParentIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)valueForIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)valueForChildBelowIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Utility functions

- (NSArray *)allStates;

- (NSArray *)allScopes;

@end
