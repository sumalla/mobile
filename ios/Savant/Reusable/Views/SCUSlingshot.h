//
//  SCUSlingshot.h
//  CAPractice
//
//  Created by Stephen Silber on 8/1/14.
//  Copyright (c) 2014 SavantSystems. All rights reserved.
//

@import UIKit;

typedef NS_OPTIONS(NSUInteger, SCUSlingshotDirection)
{
    SCUSlingshotDirectionRight = UISwipeGestureRecognizerDirectionRight,
    SCUSlingshotDirectionLeft = UISwipeGestureRecognizerDirectionLeft
};

@interface SCUSlingshotManager : NSObject

@end

@class SCUSlingshot, SAVService;

@protocol SCUSlingshotDelegate;

typedef void (^SCUSlingshotCallback)(SCUSlingshot *slingshot);
typedef void (^SCUSlingshotCallbackWithValue)(SCUSlingshot *slingshot, NSInteger value);

@interface SCUSlingshot : UIView

/**
 *  This callback is called when the slingshot updates.
 */
@property (nonatomic, copy) SCUSlingshotCallbackWithValue callback;

/**
 *  This callback occurs any time the slingshot is interacted with.
 */
@property (nonatomic, copy) dispatch_block_t interactionCallback;

/**
 *  This callback occurs any time the slingshot is released.
 */
@property (nonatomic, copy) SCUSlingshotCallback releaseCallback;

/**
 *  Specifies the minimum interval between callbacks.
 */
@property (nonatomic) NSTimeInterval callbackTimeInterval;

/**
 *  Set the base track color.
 */
@property (nonatomic) UIColor *trackColor UI_APPEARANCE_SELECTOR;

/**
 *  Set the thumb color.
 */
@property (nonatomic) UIColor *thumbColor UI_APPEARANCE_SELECTOR;

/**
 *  Set the pulse color
 */
@property (nonatomic) UIColor *trackFillColor UI_APPEARANCE_SELECTOR;

/**
 *  YES if the slingshot is tracking; otherwise NO.
 */
@property (nonatomic, readonly, getter = isTracking) BOOL tracking;

/**
 *  Set the minimum value the slingshot should represent. This can be negative. The default is -5.
 */
@property (nonatomic) NSInteger minimumValue;

/**
 *  Set the maximum value the slingshot should represent. This can be negative but must be higher than the minimumValue. The default is 5.
 */
@property (nonatomic) NSInteger maximumValue;

/**
 *  Set the minimum interval between slingshot points. The default is 1
 */
@property (nonatomic) NSInteger delta;

/**
 *  Get the current value.
 */
@property (readonly, nonatomic) NSInteger value;

/**
 *  Is the master slingshot for Global Volume
 */
@property (nonatomic, getter = isMaster) BOOL master;

/**
 * Is only a visual slingshot -- no commands should be sent
 */
@property (nonatomic, readonly) BOOL onlyVisual;

/**
 * Is only a visual slingshot -- no commands should be sent
 */
@property (nonatomic) BOOL showsIndicator;

- (instancetype)initWithFrame:(CGRect)frame andService:(SAVService *)service;

- (void)updateService:(SAVService *)service;

@end
