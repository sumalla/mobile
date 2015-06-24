//
//  SCUProgressBezel.h
//  SavantController
//
//  Created by Cameron Pulsford on 4/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAlertView.h"

typedef NS_ENUM(NSUInteger, SCUProgressBezelStyle)
{
    SCUProgressBezelStyleIndeterminate,
    SCUProgressBezelStyleCircle,
    SCUProgressBezelStyleBar
};

@interface SCUProgressBezel : SCUAlertView

@property (nonatomic, readonly) SCUProgressBezelStyle progressStyle;

@property (nonatomic) NSString *stage;

@property (nonatomic) CGFloat progress;

- (instancetype)initWithTitle:(NSString *)title progressStyle:(SCUProgressBezelStyle)progressStyle cancelButtonTitle:(NSString *)cancelButtonTitle;

- (void)completeWithMessage:(NSString *)message;

@end
