//
//  SCUSecurityPanelViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityPanelViewControllerPad.h"
#import "SCUSecurityPanelViewControllerPrivate.h"

@implementation SCUSecurityPanelViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.pickerViews];
    [self.contentView addSubview:self.partitionTitle];
    [self.contentView addSubview:self.partitionSelector];
    [self.contentView addSubview:self.panicButtons.view];
    [self.contentView addSubview:self.armingStatusTitle];
    [self.contentView addSubview:self.armingSelector];

    UIView *keypadBlock = [[UIView alloc] initWithFrame:CGRectZero];
    [keypadBlock addSubview:self.label1];
    [keypadBlock addSubview:self.label2];
    [keypadBlock addSubview:self.label3];

    {
        NSDictionary *views = @{@"label1": self.label1,
                                @"label2": self.label2,
                                @"label3": self.label3};
        NSDictionary *metrics = @{@"spacer": @15,
                                  @"leftSpacing": @5};

        [keypadBlock addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"|-(leftSpacing)-[label1]|",
                                                                                     @"|-(leftSpacing)-[label2]|",
                                                                                     @"|-(leftSpacing)-[label3]|",
                                                                                     @"V:|[label1]-(spacer)-[label2]-(spacer)-[label3]|"]]];
    }

    [self.contentView addSubview:keypadBlock];

    NSDictionary *views = @{@"numberPad": self.numberPad.view,
                            @"pickerViews": self.pickerViews,
                            @"partitionTitle": self.partitionTitle,
                            @"keypadBlock": keypadBlock,
                            @"partitionSelector": self.partitionSelector,
                            @"panicButtons": self.panicButtons.view,
                            @"armingSelector": self.armingSelector,
                            @"armingTitle": self.armingStatusTitle};


    {
        NSDictionary *metrics = @{@"spacer": @4,
                                  @"largeSpacer": @15,
                                  @"leftSpacing": @103,
                                  @"buttonsHeight": @75,
                                  @"pickerWidth": @238,
                                  @"partitionSelectorWidth": @170,
                                  @"partitionSelectorHeight": @53,
                                  @"pickerHeight": @71,
                                  @"numberPadHeight": @262,
                                  @"blockHeight": @124};

        self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:views
                                                                          formats:@[@"|[numberPad]|",
                                                                                    @"[pickerViews(pickerWidth)]",
                                                                                    @"pickerViews.centerX = super.centerX",
                                                                                    @"|[panicButtons]|",
                                                                                    @"|-(leftSpacing)-[partitionTitle]",
                                                                                    @"|-(leftSpacing)-[keypadBlock]",
                                                                                    @"|-(leftSpacing)-[partitionSelector(partitionSelectorWidth)]",
                                                                                    @"V:|-[partitionTitle]-(largeSpacer)-[partitionSelector(partitionSelectorHeight)]-(48)-[keypadBlock(blockHeight)]-(145)-[pickerViews(pickerHeight)]-(largeSpacer)-[panicButtons(buttonsHeight)]-(spacer)-[numberPad(numberPadHeight)]|",
                                                                                    @"armingTitle.top = partitionTitle.top",
                                                                                    @"armingSelector.top = partitionSelector.top",
                                                                                    @"armingSelector.right = super.right - leftSpacing",
                                                                                    @"armingTitle.left = armingSelector.left",
                                                                                    @"armingSelector.width = partitionSelector.width",
                                                                                    @"armingSelector.height = partitionSelector.height"]];
        
    }

    {
        NSDictionary *metrics = @{@"spacer": @4,
                                  @"largeSpacer": @15,
                                  @"leftSpacing": @103,
                                  @"buttonsWidth": @289,
                                  @"buttonsHeight": @266,
                                  @"pickerWidth": @238,
                                  @"partitionSelectorWidth": @170,
                                  @"partitionSelectorHeight": @53,
                                  @"pickerHeight": @71,
                                  @"blockHeight": @124};

        self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"|[panicButtons]-(spacer)-[numberPad(buttonsWidth)]|",
                                                                                     @"|-(250)-[pickerViews(pickerWidth)]",
                                                                                     @"|-(leftSpacing)-[partitionTitle]",
                                                                                     @"|-(leftSpacing)-[keypadBlock]",
                                                                                     @"|-(leftSpacing)-[partitionSelector(partitionSelectorWidth)]",
                                                                                     @"V:|[numberPad]|",
                                                                                     @"V:|-[partitionTitle]-(largeSpacer)-[partitionSelector(partitionSelectorHeight)]-(48)-[keypadBlock(blockHeight)]-(152)-[pickerViews(pickerHeight)]-(25)-[panicButtons]|",
                                                                                     @"armingTitle.top = partitionTitle.top",
                                                                                     @"armingSelector.top = partitionSelector.top",
                                                                                     @"armingSelector.right = numberPad.left - leftSpacing",
                                                                                     @"armingTitle.left = armingSelector.left",
                                                                                     @"armingSelector.width = partitionSelector.width",
                                                                                     @"armingSelector.height = partitionSelector.height"]];
    }

    self.panicButtons.numberOfColumns = 4;
    self.panicButtons.numberOfRows = 1;

    [self setupConstraintsForOrientation:[UIDevice deviceOrientation]];
}

#pragma mark - Main Toolbar Items

- (SCUMainToolbarItems)mainToolbarItems
{
    return SCUMainToolbarItemsRightButtons  | SCUMainToolbarItemsCenterButtons | SCUMainToolbarItemsRightSpacing;
}

- (NSArray *)mainToolbarCenterItems
{
    return @[self.systemSelector];
}

- (NSArray *)mainToolbarRightItems
{
    UIView *spacer1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    UIView *spacer2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    UIView *spacer3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];

    return @[self.unknownCount, self.unknownLabel, spacer1, self.criticalCount, self.criticalLabel, spacer2, self.troubleCount, self.troubleLabel, spacer3];
}

- (NSNumber *)mainToolbarItemRightSpacing
{
    return @2;
}

@end
