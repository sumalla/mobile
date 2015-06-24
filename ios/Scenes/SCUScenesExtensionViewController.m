//
//  SCUScenesExtensionViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 11/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import NotificationCenter;

#import "SCUScenesExtensionViewController.h"
#import "SCUButton.h"
#import "SCUScenesExtensionModel.h"
#import "SCUScenesExtensionItem.h"

@import SDK;

static NSString *const SCUScenesExtensionKeyIdentifiers = @"SCUScenesExtensionKeyIdentifiers";

@interface SCUScenesExtensionViewController () <NCWidgetProviding, SCUScenesExtensionModelDelegate>

@property (nonatomic) SCUScenesExtensionModel *model;
@property (nonatomic) UIView *contentView;
@property (nonatomic) CGFloat tileWidth;
@property (nonatomic) CGFloat pageWidth;
@property (nonatomic) NSArray *sceneViews;
@property (nonatomic) UILabel *noScenes;
@property (nonatomic) BOOL isScrolling;
@property (nonatomic) UILabel *readyLabel;

@end

@implementation SCUScenesExtensionViewController

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[Savant control] disconnect];
}

- (void)cleanup
{
    [self.noScenes removeFromSuperview];
    self.noScenes = nil;

    [self.sceneViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.sceneViews = nil;

    [self.contentView removeFromSuperview];
    self.contentView = nil;
}

- (void)connectionLostToSystem:(NSString *)name
{
    [self displayErrorText:[NSString stringWithFormat:NSLocalizedString(@"Searching for %@...", nil), name]];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SCUScenesExtensionKeyIdentifiers];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.readyLabel.alpha = 0;
}

- (void)showLoadingIndicator
{
    [self displayErrorText:NSLocalizedString(@"Loading...", nil)];
}

- (void)loadScenes:(BOOL)ready
{
    NSArray *identifiers = [[NSUserDefaults standardUserDefaults] objectForKey:SCUScenesExtensionKeyIdentifiers];
    BOOL hasChangedScenes = ![identifiers isEqual:self.model.identifiers];

    if (!self.readyLabel)
    {
        self.readyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.readyLabel.textAlignment = NSTextAlignmentCenter;
        self.readyLabel.textColor = [[SCUColors shared] color04];
        self.readyLabel.alpha = 1;
        [self.view addSubview:self.readyLabel];
        [self.view sav_pinView:self.readyLabel withOptions:SAVViewPinningOptionsCenterX | SAVViewPinningOptionsCenterY];
    }

            self.readyLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Connecting to %@...", nil), [Savant control].currentSystem.name];

    if (hasChangedScenes || ![self.sceneViews count])
    {
        [[NSUserDefaults standardUserDefaults] setObject:self.model.identifiers forKey:SCUScenesExtensionKeyIdentifiers];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self cleanup];

        NSInteger numberOfItems = [self.model numberOfScenes];
        CGFloat itemsPerPage = SCUMaxScenes;
        NSInteger padding = 8;

        if (!numberOfItems)
        {
            [self displayErrorText:NSLocalizedString(@"No Scenes", nil)];
            return;
        }

        CGFloat containerWidth = [UIDevice isPad] ? 593 : CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat pagePercentage = 0.98;
        self.pageWidth = containerWidth * pagePercentage;
        self.tileWidth = (self.pageWidth - (padding * itemsPerPage)) / itemsPerPage;

        self.contentView = [[UIView alloc] init];
        [self.view addSubview:self.contentView];
        [self.view sav_setHeight:1 forView:self.contentView isRelative:YES];
        [self.view sav_setWidth:pagePercentage forView:self.contentView isRelative:YES];
        [self.view sav_pinView:self.contentView withOptions:SAVViewPinningOptionsCenterX];

        NSMutableArray *array = [NSMutableArray array];

        for (NSInteger i = 0; i < numberOfItems; i++)
        {
            SAVScene *scene = [self.model sceneForItem:i];
            SCUScenesExtensionItem *view = [SCUScenesExtensionItem itemWithImage:scene.image width:self.tileWidth andName:scene.name];

            scene.imageChangeCallback = ^(UIImage *image, UIImage *blurredImage){
                view.contentImage.image = image;
            };

            SAVWeakSelf;
            [view sav_forControlEvent:UIControlEventTouchUpInside performBlock:^{
                [wSelf.model selectItem:i];
            }];

            [array addObject:view];
        }

        self.sceneViews = array;

        SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
        config.fixedWidth = self.tileWidth;
        config.interSpace = padding;

        UIView *view = [UIView sav_viewWithEvenlyDistributedViews:array withConfiguration:config];

        [self.contentView addSubview:view];

        CGFloat height = self.tileWidth + 20;
        view.frame = CGRectMake(0, 0, self.tileWidth * numberOfItems + padding * (numberOfItems - 1), height);

        self.view.backgroundColor = [UIColor clearColor];
        self.preferredContentSize = CGSizeMake(0, height);
    }

    [self.view bringSubviewToFront:self.readyLabel];

    if (ready)
    {
        self.contentView.userInteractionEnabled = YES;

        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.alpha = 1;
            self.readyLabel.alpha = 0;
        }];
    }
    else
    {
        self.contentView.userInteractionEnabled = NO;

        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.alpha = 0.2;
            self.readyLabel.alpha = 1.0;
        }];
    }
}

- (void)displayErrorText:(NSString *)error
{
    [self cleanup];

    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor grayColor];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = error;
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    [self.view sav_addFlushConstraintsForView:label];
    self.readyLabel.alpha = 0;

    self.noScenes = label;

    self.preferredContentSize = CGSizeMake(0, 45);
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))completionHandler
{
    self.model = [[SCUScenesExtensionModel alloc] initWithDelegate:self];

    if ([self.model loadPreviousConnection])
    {
        if (![self.sceneViews count])
        {
            [self displayErrorText:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@...", nil), [Savant control].currentSystem.name]];
        }

        completionHandler(NCUpdateResultNoData);
    }
    else
    {
        [self displayErrorText:NSLocalizedString(@"Connect to a system to access scenes.", nil)];
        completionHandler(NCUpdateResultNewData);
    }
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets
{
    return UIEdgeInsetsMake(4, 4, 4, 4);
}

@end
