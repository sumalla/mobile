//
//  SCUTVNavigationViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVNavigationViewControllerPhone.h"
#import "SCUAVNavigationViewControllerPrivate.h"

@implementation SCUAVNavigationViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView addSubview:self.directionalSwipeView];
    [self.contentView sav_addFlushConstraintsForView:self.directionalSwipeView withPadding:5.0f];
    
    //    self.bottomLabel.text = [NSLocalizedString(@"Channel", nil) uppercaseString];
    
    [self.directionalSwipeView addSubview:self.exitButton];
    [self.directionalSwipeView sav_setSize:CGSizeMake(60, 60) forView:self.exitButton isRelative:NO];
    
    UIView *invisibleBottomBox = [[UIView alloc] initWithFrame:CGRectZero];
    invisibleBottomBox.userInteractionEnabled = YES;
    invisibleBottomBox.backgroundColor = [UIColor clearColor];

    UIView *buttonContainer = [self containerViewForPossibleButtons];
    
    if (buttonContainer)
    {
        UIView *invisibleTopBox = [[UIView alloc] initWithFrame:CGRectZero];
        invisibleTopBox.userInteractionEnabled = YES;
        invisibleTopBox.backgroundColor = [UIColor clearColor];
        
        [self.view addSubview:invisibleTopBox];
        [invisibleTopBox addSubview:buttonContainer];
        
        [self.view sav_setHeight:70.0f forView:invisibleTopBox isRelative:NO];
        [self.view sav_pinView:invisibleTopBox withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsHorizontally withSpace:10.0f];
        [invisibleTopBox sav_pinView:buttonContainer withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsHorizontally withSpace:10.0f];
    }
    
    [self.view addSubview:invisibleBottomBox];
    [self.view addSubview:self.bottomView];
    [self.view sav_pinView:invisibleBottomBox withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToBottom withSpace:10.0];
    [self.view sav_pinView:self.bottomView withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToBottom withSpace:20.0];
    [self.view sav_setHeight:62 forView:self.bottomView isRelative:NO];
    [self.view sav_setHeight:72 forView:invisibleBottomBox isRelative:NO];
}

- (UIView *)containerViewForPossibleButtons
{
    NSMutableArray *buttons = [NSMutableArray arrayWithObjects:self.exitButton, self.lastButton, self.dvrButton, self.guideButton, nil];
    if (![self.model.serviceCommands containsObject:@"Exit"])
    {
        if ([self.model.serviceCommands containsObject:@"Return"])
        {
            self.exitButton.title = NSLocalizedString(@"Return", nil);
            [self.exitButton sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
                [self.model sendCommand:@"Return"];
            }];
        }
        else
        {
            [buttons removeObject:self.exitButton];
        }
    }
    
    if (![self.model.serviceCommands containsObject:@"LastChannel"])
    {
        [buttons removeObject:self.lastButton];
    }
    
    if (![self.model.serviceCommands containsObject:@"MyDVR"] && [self.model.serviceCommands containsObject:@"List"])
    {
        self.dvrButton.title = NSLocalizedString(@"List", nil);
    }
    else if (![self.model.serviceCommands containsObject:@"MyDVR"])
    {
        [buttons removeObject:self.dvrButton];
    }
    
    if (![self.model.serviceCommands containsObject:@"Guide"])
    {
        [buttons removeObject:self.guideButton];
    }
    
    if (buttons.count)
    {
        SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
        configuration.fixedHeight = 60;
        configuration.distributeEvenly = YES;
        configuration.interSpace = CGRectGetWidth(self.directionalSwipeView.frame) / 4 - 60;
        
        UIView *buttonContainer = [UIView sav_viewWithEvenlyDistributedViews:buttons withConfiguration:configuration];
        return buttonContainer;
    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

@end