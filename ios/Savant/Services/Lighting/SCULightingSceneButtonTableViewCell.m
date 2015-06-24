//
//  SCULightingSceneButtonTableViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCULightingSceneButtonTableViewCell.h"
#import "SCUSwipeCellPrivate.h"

NSString *const SCULightingSceneButtonTableViewCellKeyEnabled = @"SCULightingSceneButtonTableViewCellKeyEnabled";

@interface SCULightingSceneButtonTableViewCell () <UIGestureRecognizerDelegate>

@property (nonatomic) UILongPressGestureRecognizer *holdGesture;
@property (nonatomic, getter = isActive) BOOL active;

@end

@implementation SCULightingSceneButtonTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.holdGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        self.holdGesture.delegate = self;
        [self.contentView addGestureRecognizer:self.holdGesture];
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if ([info[SCULightingSceneButtonTableViewCellKeyEnabled] boolValue])
    {
        self.active = YES;
        self.backgroundColor = [[SCUColors shared] color03shade05];
    }
    else
    {
        self.active = NO;
        self.backgroundColor = [[SCUColors shared] color03shade03];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return self.tableView.panGestureRecognizer.state == UIGestureRecognizerStatePossible;
}

- (void)handleHold:(UILongPressGestureRecognizer *)gesture
{
    //-------------------------------------------------------------------
    // Disable/enable the pan while the gesture is enabled.
    //-------------------------------------------------------------------
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.tableView.panGestureRecognizer.enabled = NO;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            self.tableView.panGestureRecognizer.enabled = YES;
            break;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted)
    {
        if (self.active)
        {
            self.backgroundColor = [[SCUColors shared] color03shade06];
        }
        else
        {
            self.backgroundColor = [[SCUColors shared] color03shade04];
        }
    }
    else
    {
        if (self.active)
        {
            self.backgroundColor = [[SCUColors shared] color03shade05];
        }
        else
        {
            self.backgroundColor = [[SCUColors shared] color03shade03];
        }
    }
}

@end
