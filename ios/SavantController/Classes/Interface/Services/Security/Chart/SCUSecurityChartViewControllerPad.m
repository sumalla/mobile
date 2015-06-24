//
//  SCUSecurityChartViewControllerPad.m
//  SavantController
//
//  Created by Nathan Trapp on 5/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityChartViewControllerPad.h"
#import "SCUSecurityChartViewControllerPrivate.h"

@implementation SCUSecurityChartViewControllerPad

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    {
        
        UIView *topButtons = [[UIView alloc] initWithFrame:CGRectZero];
        UIView *bottomButtons = [[UIView alloc] initWithFrame:CGRectZero];
        
        [topButtons addSubview:self.unknownButton];
        [topButtons addSubview:self.criticalButton];
        [bottomButtons addSubview:self.troubleButton];
        [bottomButtons addSubview:self.readyButton];

        NSDictionary *metrics = @{@"buttonWidth": @125,
                                  @"spacer"     : @10};
        
        [topButtons addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:@{@"unknown" : self.unknownButton,
                                                                                    @"critical": self.criticalButton}
                                                                             formats:@[@"|[unknown(buttonWidth)]-(spacer)-[critical(==unknown)]|",
                                                                                       @"unknown.centerY = super.centerY",
                                                                                       @"critical.centerY = super.centerY"]]];

        
        [bottomButtons addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                               views:@{@"trouble" : self.troubleButton,
                                                                                       @"ready": self.readyButton}
                                                                             formats:@[@"|[trouble(buttonWidth)]-(spacer)-[ready(==trouble)]|",
                                                                                       @"trouble.centerY = super.centerY",
                                                                                       @"ready.centerY = super.centerY"]]];

        [headerView addSubview:self.roomsSelector];
        [headerView addSubview:self.roomsTitle];
        [headerView addSubview:bottomButtons];
        [headerView addSubview:topButtons];
        [headerView addSubview:self.allButton];
        
        NSDictionary *views = @{@"rooms": self.roomsSelector,
                                @"roomTitle": self.roomsTitle,
                                @"all": self.allButton,
                                @"top": topButtons,
                                @"bottom": bottomButtons};
        
        metrics = @{@"spacer": @5,
                    @"largeSpacer": @15,
                    @"buttonHeight": @71,
                    @"buttonWidth": @238};

        [headerView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                            views:views
                                                                          formats:@[@"|-(largeSpacer)-[roomTitle][rooms(buttonWidth)]-(largeSpacer)-[all]-(30)-[top]",
                                                                                    @"|-(largeSpacer)-[roomTitle][rooms(buttonWidth)]-(largeSpacer)-[all]-(30)-[bottom]",
                                                                                    @"roomTitle.centerY = super.centerY",
                                                                                    @"V:|[rooms(buttonHeight)]|",
                                                                                    @"V:|[top][bottom]|",
                                                                                    @"all.centerY = super.centerY",
                                                                                    @"top.top = super.top",
                                                                                    @"top.bottom = super.centerY",
                                                                                    @"bottom.top = super.centerY",
                                                                                    @"bottom.bottom = super.bottom"]]];
        
    }
    
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.2];
    
    [self.contentView addSubview:headerView];
    [self.contentView addSubview:self.sensorTableViewController.view];
    [self.contentView addSubview:separator];
    
    NSDictionary *views = @{@"header": headerView,
                            @"tableView": self.sensorTableViewController.view,
                            @"separator": separator};
    
    NSDictionary *metrics = @{@"topSpacing": @16,
                              @"midSpacing": @10,
                              @"separatorHeight": @2,
                              @"sidePadding": @122};
    
    [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                              views:views
                                                                            formats:@[@"V:|-(topSpacing)-[header]-(midSpacing)-[separator(separatorHeight)][tableView]|"]]];
    
    self.portraitConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                        views:views
                                                                      formats:@[@"|[header]|",
                                                                                @"|[tableView]|",
                                                                                @"|[separator]|"]];
    
    self.landscapeConstraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics
                                                                         views:views
                                                                       formats:@[@"|-(sidePadding)-[header]-(sidePadding)-|",
                                                                                 @"|-(sidePadding)-[tableView]-(sidePadding)-|",
                                                                                 @"|-(sidePadding)-[separator]-(sidePadding)-|"]];
    
    [self setupConstraintsForOrientation:[UIDevice deviceOrientation]];
}

#pragma mark - Main Toolbar Items

- (SCUMainToolbarItems)mainToolbarItems
{
    return SCUMainToolbarItemsCenterButtons;
}

- (NSArray *)mainToolbarCenterItems
{
    return @[self.systemSelector];
}

@end
