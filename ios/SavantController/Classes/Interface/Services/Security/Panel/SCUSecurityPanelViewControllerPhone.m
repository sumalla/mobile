//
//  SCUSecurityPanelViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityPanelViewControllerPhone.h"
#import "SCUSecurityPanelViewControllerPrivate.h"

@implementation SCUSecurityPanelViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.contentView addSubview:self.systemSelector];
    [self.contentView addSubview:self.numberPad.view];
    [self.contentView addSubview:self.pickerViews];
    [self.contentView addSubview:self.partitionSelector];
    [self.contentView addSubview:self.panicButtons.view];
    [self.contentView addSubview:self.armingSelector];

    UIView *countBlock = [[UIView alloc] initWithFrame:CGRectZero];
    [countBlock addSubview:self.unknownCount];
    [countBlock addSubview:self.unknownLabel];
    [countBlock addSubview:self.criticalCount];
    [countBlock addSubview:self.criticalLabel];
    [countBlock addSubview:self.troubleCount];
    [countBlock addSubview:self.troubleLabel];

    {
        NSDictionary *views = @{@"unknownCount": self.unknownCount,
                                @"unknownLabel": self.unknownLabel,
                                @"criticalCount": self.criticalCount,
                                @"criticalLabel": self.criticalLabel,
                                @"troubleCount": self.troubleCount,
                                @"troubleLabel": self.troubleLabel};
        NSDictionary *metrics = @{@"spacer": @2,
                                  @"largeSpacer": @15,
                                  @"bubbleWidth": @23};

        [countBlock addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"|[unknownCount(bubbleWidth)]-(spacer)-[unknownLabel]-(largeSpacer)-[criticalCount(bubbleWidth)]-(spacer)-[criticalLabel]-(largeSpacer)-[troubleCount(bubbleWidth)]-(spacer)-[troubleLabel]|",
                                                                                     @"V:|[unknownCount(bubbleWidth)]|",
                                                                                     @"V:|[unknownLabel(bubbleWidth)]|",
                                                                                     @"V:|[criticalCount(bubbleWidth)]|",
                                                                                     @"V:|[criticalLabel(bubbleWidth)]|",
                                                                                     @"V:|[troubleCount(bubbleWidth)]|",
                                                                                     @"V:|[troubleLabel(bubbleWidth)]|"]]];
    }

    [self.contentView addSubview:countBlock];

    UIView *keypadBlock = [[UIView alloc] initWithFrame:CGRectZero];
    [keypadBlock addSubview:self.label1];
    [keypadBlock addSubview:self.label2];
    [keypadBlock addSubview:self.label3];

    {
        NSDictionary *views = @{@"label1": self.label1,
                                @"label2": self.label2,
                                @"label3": self.label3};
        NSDictionary *metrics = @{@"spacer": @0,
                                  @"largeSpacer":@15};

        [keypadBlock addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                             views:views
                                                                           formats:@[@"label1.centerX = super.centerX",
                                                                                     @"label2.centerX = super.centerX",
                                                                                     @"label3.centerX = super.centerX",
                                                                                     @"V:|[label1]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[label2]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[label3]|"]]];
    }

    [self.contentView addSubview:keypadBlock];

    NSDictionary *views = @{@"numberPad": self.numberPad.view,
                            @"pickerViews": self.pickerViews,
                            @"keypadBlock": keypadBlock,
                            @"partitionSelector": self.partitionSelector,
                            @"systemSelector": self.systemSelector,
                            @"panicButtons": self.panicButtons.view,
                            @"armingSelector": self.armingSelector,
                            @"countBlock": countBlock};


    {
        NSDictionary *metrics = @{@"spacer": @5,
                                  @"largeSpacer": @25,
                                  @"swipeViewWidth": @121,
                                  @"numberPadMaxHeight": @350,
                                  @"numberPadMinHeight": @165,
                                  @"transportsMaxHeight": @174,
                                  @"transportsMinHeight": @80,
                                  @"keypadBlockMaxHeight": @88,
                                  @"keypadBlockMinHeight": @60,
                                  @"selectorMaxHeight": @35,
                                  @"selectorMinHeight": @25};

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:views
                                                                          formats:@[@"|-(spacer)-[systemSelector]-(spacer)-[partitionSelector(==systemSelector)]-(spacer)-|",
                                                                                    @"|-(spacer)-[armingSelector]-(spacer)-[pickerViews(==armingSelector)]-(spacer)-|",
                                                                                    @"|[keypadBlock]|",
                                                                                    @"countBlock.centerX = super.centerX",
                                                                                    @"|[numberPad]-(spacer)-[panicButtons(swipeViewWidth)]|",
                                                                                    @"V:|-(spacer)-[systemSelector(<=selectorMaxHeight,>=selectorMinHeight,==selectorMaxHeight@500)]-[armingSelector(==systemSelector)]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[keypadBlock(<=keypadBlockMaxHeight,>=keypadBlockMinHeight,==keypadBlockMaxHeight@500)]-(<=largeSpacer,>=spacer,==largeSpacer@500)-[countBlock(25)]-(spacer)-[numberPad(<=numberPadMaxHeight,>=numberPadMinHeight,==numberPadMaxHeight@600)]|",
                                                                                    @"V:|-(spacer)-[partitionSelector(==systemSelector)]-[pickerViews(==systemSelector)]-[keypadBlock]-[countBlock]-[panicButtons(==numberPad)]|"]]];

    }

    self.panicButtons.numberOfRows = 4;
    self.panicButtons.numberOfColumns = 1;
}

@end
