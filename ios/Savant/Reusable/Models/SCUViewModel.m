//
//  SCUViewModel.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUViewModel.h"
#import "SCUStateReceiver.h"
@import SDK;

@implementation SCUViewModel

- (void)viewWillAppear
{
    //--------------------------------------------------
    // Regsiter states
    //--------------------------------------------------
    [self registerStates];
}

- (void)registerStates
{
    //--------------------------------------------------
    // Regsiter states
    //--------------------------------------------------
    if ([self conformsToProtocol:@protocol(SCUStateReceiver)])
    {
        SCUViewModel <SCUStateReceiver> *stateReceiver = (SCUViewModel <SCUStateReceiver> *)self;

        NSArray *statesToRegister = stateReceiver.statesToRegister;

        if ([statesToRegister count])
        {
            [[Savant states] registerForStates:statesToRegister forObserver:stateReceiver];
        }
    }
}

- (void)viewWillDisappear
{
    //--------------------------------------------------
    // Unregister states
    //--------------------------------------------------
    [self unregisterStates];
}

- (void)unregisterStates
{
    //--------------------------------------------------
    // Unregister states
    //--------------------------------------------------
    if ([self conformsToProtocol:@protocol(SCUStateReceiver)])
    {
        SCUViewModel <SCUStateReceiver> *stateReceiver = (SCUViewModel <SCUStateReceiver> *)self;

        NSArray *statesToRegister = stateReceiver.statesToRegister;

        if ([statesToRegister count])
        {
            [[Savant states] unregisterForStates:statesToRegister forObserver:stateReceiver];
        }
    }
}

@end
