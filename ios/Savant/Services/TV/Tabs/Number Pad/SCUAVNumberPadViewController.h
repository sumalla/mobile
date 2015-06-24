//
//  SCUTVNumberPadViewController.h
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNavigationViewController.h"

typedef NS_ENUM(NSUInteger, SCUAVNumberPadViewState)
{
    SCUAVNumberPadViewStateTransport,
    SCUAVNumberPadViewStateNumberpad
};

@interface SCUAVNumberPadViewController : SCUAVNavigationViewController

- (void)snapScrollViewtoState:(SCUAVNumberPadViewState)state;

- (CGFloat)contentHeight;

- (CGFloat)numberPadHeight;

@end
