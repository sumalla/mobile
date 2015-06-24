//
//  SCUSurveillanceNavigationViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/1/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSurveillanceNavigationViewController.h"
#import "SCUSurveillanceNavigationViewControllerPrivate.h"
#import "SCUTransportButtonCollectionViewController.h"
#import "SCUButton.h"
@import SDK;

@implementation SCUSurveillanceNavigationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[SCUColors shared] color03shade01];
    
    SCUTransportButtonCollectionViewController *buttonController = [[SCUTransportButtonCollectionViewController alloc] initWithGenericCommands:self.model.transportGenericCommands backCommands:self.model.transportBackCommands forwardCommands:self.model.transportForwardCommands];
    buttonController.columns = 3;
    
    self.transportContainer = [[SCUButtonViewController alloc] initWithCollectionViewController:buttonController];
    self.transportContainer.delegate = self;
    self.transportContainer.numberOfColumns = 3;
    [self addChildViewController:self.transportContainer];
    
    self.numberPad = [[SCUButtonViewController alloc] initWithCommands:self.model.channelCommands];
    self.numberPad.delegate = self;
    self.numberPad.numberOfColumns = 3;
    
    CGFloat rowsFloat = (1.0 * self.model.channelCommands.count) / self.numberPad.numberOfColumns;
    NSInteger rows = ceilf(rowsFloat);
    
    self.numberPad.numberOfRows = rows;
    
    [self addChildViewController:self.numberPad];
    
    self.directionalSwipeView = [[SCUSwipeView alloc] initWithFrame:CGRectZero configuration:SCUSwipeViewConfigurationAll];
    self.directionalSwipeView.delegate = self;
    
    self.exitButton  = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Exit", nil)];
    
    [self.exitButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
        [self.model sendCommand:@"Exit"];
    }];
    
    self.directionalSwipeView.borderWidth = 0;
    self.directionalSwipeView.arrowViewSize = 200;
    self.directionalSwipeView.arrowSize = CGSizeMake(40, 40);
    self.directionalSwipeView.arrowColor = [[SCUColors shared] color03shade01];
    
    self.exitButton.borderWidth = [UIScreen screenPixel];
    self.exitButton.backgroundColor = [[SCUColors shared] color03];
    self.exitButton.borderColor = [[SCUColors shared] color03shade02];
    self.exitButton.selectedBackgroundColor = [[SCUColors shared] color01];
    self.exitButton.color = [[SCUColors shared] color04];
    self.exitButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h10];
    
    [self.directionalSwipeView addSubview:self.exitButton];
}

- (void)handleRelease
{
    [self.model endHoldCommandWithCommand:@"StopRepeat"];
}

#pragma mark - Tab Bar Controller

- (UIImage *)tabBarIcon
{
    return [UIImage imageNamed:@"navigation"];
}

#pragma mark - SCUButtonCollectionViewControllerDelegate methods

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    [self.model sendCommand:command];
}

- (void)setOrderOfDynamicCommands:(NSDictionary *)orderedAndHiddenCommandsDict
{
    [self.model setOrderOfCommands:orderedAndHiddenCommandsDict];
}

#pragma mark - SCUSwipeViewDelegate methods

- (void)swipeView:(SCUSwipeView *)swipeView didReceiveInteraction:(SCUSwipeViewDirection)interaction isHold:(BOOL)isHold
{
    NSArray *possibleCommands = nil;
    NSString *cmd = nil;
    
    if (swipeView == self.directionalSwipeView)
    {
        possibleCommands = self.model.navigationCommands;
    }
    else
    {
        return;
    }
    
    switch (interaction)
    {
        case SCUSwipeViewDirectionUp:
            cmd = [self commandContainingString:@[@"Up"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionDown:
            cmd = [self commandContainingString:@[@"Down"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionLeft:
            cmd = [self commandContainingString:@[@"Left"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionRight:
            cmd = [self commandContainingString:@[@"Right"] inArray:possibleCommands];
            break;
        case SCUSwipeViewDirectionCenter:
            cmd = [self commandContainingString:@[@"Select", @"Enter"] inArray:possibleCommands];
            break;
    }
    
    if (cmd)
    {
        if (isHold)
        {
            [self.model sendHoldCommand:cmd withInterval:0.2f];
        }
        else
        {
            [self.model sendCommand:cmd];
        }
    }
}

- (void)swipeView:(SCUSwipeView *)swipeView holdInteractionDidEnd:(SCUSwipeViewDirection)interaction
{
    [self.model endHoldCommandWithCommand:nil];
}

#pragma mark - SCUSwipeViewDelegate helper methods

- (NSString *)commandContainingString:(NSArray *)strings inArray:(NSArray *)array
{
    NSArray *commands = [array filteredArrayUsingBlock:^BOOL(NSString *command) {
        BOOL keep = NO;
        
        for (NSString *string in strings)
        {
            keep = [command containsString:string];
            
            if (keep)
            {
                break;
            }
        }
        
        return keep;
    }];
    
    NSString *commandToUse = nil;
    
    for (NSString *string in strings)
    {
        for (NSString *command in commands)
        {
            if ([command containsString:string])
            {
                commandToUse = command;
                
                break;
            }
        }
        
        if (commandToUse)
        {
            break;
        }
    }
    
    return commandToUse;
}

@end
