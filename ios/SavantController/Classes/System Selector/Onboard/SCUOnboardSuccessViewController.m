//
//  SCUOnboardSuccessViewController.m
//  SavantController
//
//  Created by Cameron Pulsford on 10/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUOnboardSuccessViewController.h"
#import "SCUButton.h"
#import <SavantControl/SavantControl.h>
#import <SavantExtensions/SavantExtensions.h>

@interface SCUOnboardSuccessViewController ()

@property (nonatomic) NSString *systemName;
@property (nonatomic, copy) dispatch_block_t continueBlock;

@end

@implementation SCUOnboardSuccessViewController

- (instancetype)initWithSystemName:(NSString *)systemName continueBlock:(dispatch_block_t)continueBlock
{
    self = [super init];

    if (self)
    {
        self.systemName = systemName;
        self.continueBlock = continueBlock;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    SCUButton *continueButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"CONTINUE", nil)];
    continueButton.target = self;
    continueButton.releaseAction = @selector(handleContinue);
    continueButton.borderWidth = [UIScreen screenPixel];
    continueButton.borderColor = [[SCUColors shared] color03shade04];
    continueButton.roundedCorners = YES;
    continueButton.color = [[SCUColors shared] color01];
    continueButton.backgroundColor = [UIColor clearColor];
    continueButton.selectedColor = [[SCUColors shared] color03];
    [self.view addSubview:continueButton];

    [self.view sav_pinView:continueButton withOptions:SAVViewPinningOptionsToBottom withSpace:20];
    [self.view sav_pinView:continueButton withOptions:SAVViewPinningOptionsCenterX];
    [self.view sav_setHeight:60 forView:continueButton isRelative:NO];

    if ([UIDevice isPad])
    {
        [self.view sav_setWidth:300 forView:continueButton isRelative:NO];
    }
    else
    {
        [self.view sav_setWidth:.9 forView:continueButton isRelative:YES];
    }

    UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OnboardSuccess"]];
    backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImage.clipsToBounds = YES;
    [self.view addSubview:backgroundImage];

    [self.view sav_pinView:backgroundImage withOptions:SAVViewPinningOptionsToTop];
    [self.view sav_pinView:backgroundImage withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:backgroundImage withOptions:SAVViewPinningOptionsToTop ofView:continueButton withSpace:20];

    UILabel *marketingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    marketingLabel.numberOfLines = 0;
    marketingLabel.textColor = [[SCUColors shared] color04];
    marketingLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:marketingLabel];
    marketingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"OK! We have successfully associated %@ with %@\n\nWe've also given you 90 days of free remote access, so you can control your Savant System from anywhere.", nil),
                           self.systemName,
                           [SavantControl sharedControl].cloudUser];

    UIView *dummyView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:dummyView];
    [self.view sav_setHeight:[UIScreen screenPixel] forView:dummyView isRelative:NO];
    [self.view sav_pinView:dummyView withOptions:SAVViewPinningOptionsCenterY | SAVViewPinningOptionsHorizontally];

    [self.view sav_pinView:marketingLabel withOptions:SAVViewPinningOptionsToBottom ofView:dummyView withSpace:0];
    [self.view sav_setWidth:.9 forView:marketingLabel isRelative:YES];
    [self.view sav_pinView:marketingLabel withOptions:SAVViewPinningOptionsCenterX];
}

- (void)handleContinue
{
    if (self.continueBlock)
    {
        self.continueBlock();
    }
}

@end
