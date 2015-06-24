//
//  SCUTabBarController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/2/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTabBarController.h"
#import "SCUToolbar.h"
#import "SCUToolbarButton.h"
#import "SCUServiceViewController.h"
@import SDK;
@import Extensions;

NSString *const SCUSavedTabsPrefix = @"savedTabs";

@interface SCUTabBarController ()

@property SCUToolbar *toolbar;
@property (nonatomic) UIView *contentView;
@property (nonatomic) SCUButton *activeButton;
@property NSArray *buttons;
@property NSArray *currentConstraints;
@property NSArray *kvoRegistrations;

@end

@implementation SCUTabBarController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.toolbar = [[SCUToolbar alloc] initWithFrame:CGRectZero];
        self.toolbar.scrolling = YES;
        _toolbarHeight = [UIDevice isPad] ? 65 : 52;
    }
    return self;
}

- (instancetype)initWithViewControllers:(NSArray *)viewControllers
{
    self = [self init];
    if (self)
    {
        self.viewControllers = viewControllers;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view addSubview:self.toolbar];
    
    self.toolbar.barTintColor = [[SCUColors shared] color03];


    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:contentView];

    self.contentView = contentView;

    [self setupConstraints];

}

- (void)setupConstraints
{
    if (self.currentConstraints)
    {
        [self.view removeConstraints:self.currentConstraints];
    }

    self.currentConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                     metrics:@{@"toolbarHeight": @(self.toolbarHeight)}
                                                                       views:@{@"contentView": self.contentView,
                                                                               @"toolbar": self.toolbar}
                                                                     formats:@[@"|[contentView]|",
                                                                               @"|[toolbar]|",
                                                                               @"V:|[contentView][toolbar(toolbarHeight)]|"]];

    [self.view addConstraints:self.currentConstraints];
}

- (void)viewWillLayoutSubviews
{
    [self configureToolbar];
}

- (void)configureButtons
{
    NSMutableArray *buttons = [NSMutableArray array];

    for (id <SCUTabBarControllerContentView> viewController in self.viewControllers)
    {
        SCUToolbarButton *button = [[SCUToolbarButton alloc] init];

        if ([viewController respondsToSelector:@selector(tabBarTitle)])
        {
            button.title = [viewController tabBarTitle];
        }

        if ([viewController respondsToSelector:@selector(tabBarIcon)])
        {
            button.image = [viewController tabBarIcon];
        }

        if (button)
        {
            [self setupToolbarButton:button];

            if ([viewController respondsToSelector:@selector(tabBarButtonColor)])
            {
                button.selectedColor = [viewController tabBarButtonColor];
            }

            button.selected = [viewController isEqual:self.activeVC] ? YES : NO;
            [buttons addObject:button];
        }
    }
    
    self.buttons = [buttons copy];
}

- (void)reconfigureToolbar
{
    self.buttons = nil;
    [self configureToolbar];
    [self.view setNeedsLayout];
}

- (void)configureToolbar
{
    if (!self.buttons)
    {
        [self configureButtons];
    }

    CGFloat buttonWidths = 0;

    for (SCUButton *button in self.buttons)
    {
        buttonWidths += CGRectGetWidth([button bounds]);
    }
    
    CGFloat space = (CGRectGetWidth(self.view.bounds) - buttonWidths) / ([self.buttons count] + 1);

    if (space < 0)
    {
        space = 0;
    }

    [self.toolbar configureWithItems:@{SCUToolbarLeftItemsKey:self.buttons, SCUToolbarLeftItemSpacingKey: @(space)}];

    if (!self.activeVC)
    {
        if ([self.savedKey length])
        {
            NSNumber *savedIndex = [[SAVSettings localSettings] objectForKey:[NSString stringWithFormat:@"%@.%@", SCUSavedTabsPrefix, self.savedKey]];

            if (savedIndex)
            {
                NSUInteger idx = [savedIndex unsignedIntegerValue];
                if (idx < [self.buttons count])
                {
                    [self switchTabs:self.buttons[idx]];
                }
            }
        }

        if (!self.activeVC)
        {
            if (self.defaultVC && ([self.viewControllers indexOfObject:self.defaultVC] != NSNotFound))
            {
                [self switchTabs:self.buttons[[self.viewControllers indexOfObject:self.defaultVC]]];
            }
            else
            {
                [self switchTabs:[self.buttons firstObject]];
            }
        }
    }
    else
    {
        self.activeButton = self.buttons[[self.viewControllers indexOfObject:self.activeVC]];
    }
}

- (void)setupToolbarButton:(SCUToolbarButton *)toolbarButton
{
    toolbarButton.color = [[SCUColors shared] color04];
    toolbarButton.selectedBackgroundColor = [[SCUColors shared] color03];
    toolbarButton.target = self;
    toolbarButton.releaseAction = @selector(switchTabs:);

    CGFloat padding = [UIDevice isPad] ? 86 : 44;

    toolbarButton.contentEdgeInsets = UIEdgeInsetsMake(0, padding / 2, 0, padding / 2);
}

- (void)switchTabs:(SCUToolbarButton *)sender
{
    if (self.activeButton != sender)
    {
        NSUInteger idx = [self.buttons indexOfObject:sender];
        NSUInteger oldIdx = [self.buttons indexOfObject:self.activeButton];

        UIViewController *viewController = nil;

        if ([self.viewControllers count] > idx)
        {
            viewController = self.viewControllers[idx];
        }

        if (viewController)
        {
            self.activeVC = viewController;
        }
        
        if ([viewController isKindOfClass:[SCUServiceViewController class]])
        {
            SCUServiceViewController *serviceView = (SCUServiceViewController *)viewController;
            if (serviceView.hasCustomPresentation)
            {
                [serviceView presentCustomView];
                
                if ([self.viewControllers count ] > oldIdx)
                {
                    viewController = self.viewControllers[oldIdx];
                    if (viewController)
                    {
                         self.activeVC = viewController;   
                    }
                }
                
            }
        }
    }
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    if (_viewControllers == viewControllers)
    {
        return;
    }

    _viewControllers = viewControllers;

    NSMutableArray *kvoRegistrations = [NSMutableArray array];

    SAVWeakSelf;
    SAVKVORegistrationBlock handler = ^(NSDictionary *changeDictionary){
        [wSelf reconfigureToolbar];
    };

    for (UIViewController <SCUTabBarControllerContentView> *viewController in viewControllers)
    {
        if ([viewController respondsToSelector:@selector(tabBarTitle)])
        {
            [kvoRegistrations addObject:[[SAVKVORegistration alloc] initWithObserver:self target:viewController selector:@selector(tabBarTitle) options:NSKeyValueObservingOptionNew handler:handler]];
        }

        if ([viewController respondsToSelector:@selector(tabBarIcon)])
        {
            [kvoRegistrations addObject:[[SAVKVORegistration alloc] initWithObserver:self target:viewController selector:@selector(tabBarIcon) options:NSKeyValueObservingOptionNew handler:handler]];
        }

        if ([viewController respondsToSelector:@selector(tabBarButtonColor)])
        {
            [kvoRegistrations addObject:[[SAVKVORegistration alloc] initWithObserver:self target:viewController selector:@selector(tabBarButtonColor) options:NSKeyValueObservingOptionNew handler:handler]];
        }
    }

    self.kvoRegistrations = kvoRegistrations;

    [self reconfigureToolbar];
}

- (void)setActiveVC:(UIViewController *)activeVC
{
    if (_activeVC == activeVC)
    {
        return;
    }

    [self.activeVC sav_removeFromParentViewController];

    _activeVC = activeVC;

    if (!self.buttons)
    {
        [self configureToolbar];
    }

    NSUInteger idx = [self.viewControllers indexOfObject:activeVC];

    NSAssert(idx != NSNotFound, @"The active view controller must be part of the view controllers array");

    if (activeVC)
    {
        [self addChildViewController:activeVC];
        [self.contentView addSubview:activeVC.view];
        [self.contentView sav_addFlushConstraintsForView:activeVC.view];
        [self.view bringSubviewToFront:self.toolbar];
        if (activeVC.title)
        {
            self.title = activeVC.title;
        }
    }

    SCUButton *activeVCButton = self.buttons[idx];

    self.activeButton.selected = NO;
    self.activeButton = activeVCButton;
    self.activeButton.selected = YES;
    [self.toolbar scrollToItem:self.activeButton animated:YES];

    if ([self.savedKey length])
    {
        [[SAVSettings localSettings] setObject:@([self.viewControllers indexOfObject:activeVC]) forKey:[NSString stringWithFormat:@"%@.%@", SCUSavedTabsPrefix, self.savedKey]];
        [[SAVSettings localSettings] synchronize];
    }
}

- (void)setToolbarHeight:(NSInteger)toolbarHeight
{
    _toolbarHeight = toolbarHeight;

    self.toolbar.hidden = !toolbarHeight;

    [self setupConstraints];
}

- (NSString *)savedKey
{
    return nil;
}

@end
