//
//  SCUOnboardViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 9/30/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUOnboardViewController.h"
#import "SCUButton.h"
#import "SCUOnboardSuccessViewController.h"

@interface SCUOnboardViewController ()

@property (nonatomic) SAVSystem *system;
@property (nonatomic) BOOL showDoNotLink;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) SCUButton *linkButton;
@property (nonatomic) SCUButton *skipButton;

@end

@implementation SCUOnboardViewController

- (instancetype)initWithSystem:(SAVSystem *)system showDoNotLink:(BOOL)showDoNotLink
{
    self = [super init];

    if (self)
    {
        self.system = system;
        self.showDoNotLink = showDoNotLink;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    UILabel *marketingLabel = [[UILabel alloc] initWithFrame:CGRectZero];

    UIImageView *logo = nil;

    if (self.showDoNotLink)
    {
        marketingLabel.text = NSLocalizedString(@"Welcome to your Savant App. Please confirm that you’d like to be the primary administrator of this system.", nil);

        logo = [[UIImageView alloc] initWithImage:[UIImage sav_imageNamed:@"SavantLogo" tintColor:[[SCUColors shared] color03shade06]]];
        logo.contentMode = UIViewContentModeCenter;
        [self.view addSubview:logo];
        [self.view sav_pinView:logo withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsToTop];
        [self.view sav_setHeight:60 forView:logo isRelative:NO];
    }
    else
    {
        marketingLabel.text = NSLocalizedString(@"Please confirm that you’d like to be the primary administrator of this system.", nil);
    }

    marketingLabel.textColor = [[SCUColors shared] color03shade07];
    marketingLabel.numberOfLines = 0;
    marketingLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:marketingLabel];

    if (logo)
    {
        [self.view sav_pinView:marketingLabel withOptions:SAVViewPinningOptionsToBottom ofView:logo withSpace:SAVViewAutoLayoutStandardSpace];
    }
    else
    {
        [self.view sav_pinView:marketingLabel withOptions:SAVViewPinningOptionsToTop withSpace:30];
    }

    [self.view sav_pinView:marketingLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:30];

    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    nameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Associate %@ with %@", nil), self.system.name, [[SavantControl sharedControl] cloudUser]];
    nameLabel.textColor = [[SCUColors shared] color04];
    nameLabel.numberOfLines = 0;
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:nameLabel];

    [self.view sav_pinView:nameLabel withOptions:SAVViewPinningOptionsHorizontally withSpace:30];
    [self.view sav_pinView:nameLabel withOptions:SAVViewPinningOptionsToBottom ofView:marketingLabel withSpace:30];

    SCUButton *linkButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"YES, THIS IS MY SYSTEM", nil)];
    linkButton.releaseAction = @selector(handleLink:);
    linkButton.borderWidth = [UIScreen screenPixel];
    linkButton.borderColor = [[SCUColors shared] color03shade04];
    [self.view addSubview:linkButton];
    self.linkButton = linkButton;

    SCUButton *doNotLinkButton = nil;

    if (self.showDoNotLink)
    {
        doNotLinkButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"No, skip this step", nil)];
        doNotLinkButton.releaseAction = @selector(handleDontLink:);
        [self.view addSubview:doNotLinkButton];
        self.skipButton = doNotLinkButton;

        [self.view sav_setWidth:.9 forView:doNotLinkButton isRelative:YES];
        [self.view sav_setHeight:60 forView:doNotLinkButton isRelative:NO];
        [self.view sav_pinView:doNotLinkButton withOptions:SAVViewPinningOptionsCenterX];
        [self.view sav_pinView:doNotLinkButton withOptions:SAVViewPinningOptionsToBottom withSpace:20];

        [self.view sav_setHeight:60 forView:linkButton isRelative:NO];
        [self.view sav_pinView:linkButton withOptions:SAVViewPinningOptionsCenterX];
        [self.view sav_pinView:linkButton withOptions:SAVViewPinningOptionsToTop ofView:doNotLinkButton withSpace:20];
    }
    else
    {
        [self.view sav_setHeight:60 forView:linkButton isRelative:NO];
        [self.view sav_pinView:linkButton withOptions:SAVViewPinningOptionsCenterX];
        [self.view sav_pinView:linkButton withOptions:SAVViewPinningOptionsToBottom withSpace:20];
    }

    if ([UIDevice isPad])
    {
        [self.view sav_setWidth:300 forView:linkButton isRelative:NO];
    }
    else
    {
        [self.view sav_setWidth:.9 forView:linkButton isRelative:YES];
    }

    for (SCUButton *button in doNotLinkButton ? @[doNotLinkButton, linkButton] : @[linkButton])
    {
        button.target = self;
        button.roundedCorners = YES;
        button.color = [[SCUColors shared] color01];
        button.backgroundColor = [UIColor clearColor];
        button.selectedColor = [[SCUColors shared] color03];
    }

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.hidden = YES;
    [self.view addSubview:self.spinner];
    [self.view sav_addCenteredConstraintsForView:self.spinner];
}

- (void)handleLink:(SCUButton *)sender
{
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    self.linkButton.userInteractionEnabled = NO;
    self.skipButton.userInteractionEnabled = NO;

    dispatch_async_main(^{
        SAVWeakSelf;
        [[SavantControl sharedControl] onboardSystem:self.system completionHandler:^BOOL(BOOL success, NSError *error) {
            SAVStrongWeakSelf;

            sSelf.linkButton.userInteractionEnabled = YES;
            sSelf.skipButton.userInteractionEnabled = YES;
            [sSelf.spinner stopAnimating];

            if (success)
            {
                SCUOnboardSuccessViewController *viewController = [[SCUOnboardSuccessViewController alloc] initWithSystemName:self.system.name continueBlock:^{
                    if ([sSelf.delegate respondsToSelector:@selector(systemDidBind:)])
                    {
                        [sSelf.delegate systemDidBind:sSelf.system];
                    }
                }];

                [sSelf.navigationController pushViewController:viewController animated:YES];
            }
            else
            {
                if ([sSelf.delegate respondsToSelector:@selector(system:didNotBindWithError:)])
                {
                    [sSelf.delegate system:sSelf.system didNotBindWithError:error];
                }
            }

            return NO;
        }];
    });
}

- (void)handleDontLink:(SCUButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(systemBindWasSkipped:)])
    {
        [self.delegate systemBindWasSkipped:self.system];
    }
}

@end
