//
//  SCUHVACPickerView.m
//  SavantController
//
//  Created by Jason Wolkovitz on 10/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUHVACPickerView.h"
#import "SCUServiceViewController.h"
#import "SCUPopoverMenu.h"

#import <SavantControl/SavantControl.h>

@interface SCUHVACPickerView()

@property (nonatomic) UIFont *labelFont;
@property (nonatomic) UIFont *buttonFont;

@property (nonatomic) SCUButton *hvacSelector;
@property (nonatomic) UILabel *hvacLabel;
@property SCUPopoverMenu *popoverMenu;

@end

@implementation SCUHVACPickerView

- (instancetype)initWithHVACPickerModel:(SCUHVACPickerModel *)model
{
    self = [super init];
    if (self)
    {
        self.model = model;
        self.model.viewDelegate = self;
        
        self.labelFont = [UIFont fontWithName:@"Gotham-Book" size:12.0f];
        self.buttonFont = [UIFont fontWithName:@"Gotham-Book" size:14.0f];
        
        self.hvacSelector = [[SCUButton alloc] initWithTitle:@""] ;//]modelObject[SCUDefaultTableViewCellKeyTitle]];
        self.hvacSelector.target = self;
        self.hvacSelector.releaseAction = @selector(hvacSelectorTapped:);
        self.hvacSelector.frame = CGRectMake(0, 0, 200, 30);
        self.hvacSelector.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        self.hvacSelector.selectedBackgroundColor = [[SCUColors shared] color01];
        self.hvacSelector.borderWidth = [UIScreen screenPixel];
        
        self.hvacLabel = [[UILabel alloc] initWithFrame:self.hvacSelector.frame];
        self.hvacLabel.textColor = [UIColor whiteColor];
        self.hvacLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
        self.hvacLabel.textAlignment = NSTextAlignmentCenter;
        [self setHvacLabelText];
    }
    return self;
}

- (UIView *)labelOrHVACSelector
{
    UIView *viewToAdd = nil;
    if ([self.model.HVACEntities count] > 1)
    {
        viewToAdd = self.hvacSelector;
    }
    else
    {
        viewToAdd = self.hvacLabel;
    }
    return viewToAdd;
}

- (BOOL)hasHVACHistory
{
    BOOL hasHistory = NO;

    for (SAVHVACEntity *entity in self.model.HVACEntities)
    {
        if (entity.history)
        {
            hasHistory = YES;
            break;
        }
    }

    return hasHistory;
}

- (BOOL)hasHVACService
{
    return ([self.model.HVACEntities count] > 0);
}

- (void)hvacSelectorTapped:(SCUButton *)button
{
    self.popoverMenu = [[SCUPopoverMenu alloc] initWithButtonTitles:[self.model HVACEntitiesZoneNames]];
    self.popoverMenu.selectedIndex = self.model.currentZoneIndex;
    SAVWeakSelf;
    self.popoverMenu.callback = ^(NSInteger buttonIndex) {
        if (buttonIndex > -1 && buttonIndex < (NSInteger)[wSelf.model.HVACEntities count])
        {
            if (wSelf.model)
            {
                [wSelf.model setCurrentZoneIndexFromPicker:buttonIndex];
            }
            [wSelf setHvacLabelText];
        }
    };
    [self.popoverMenu showFromButton:button animated:YES];
}

#pragma Model Delegate methods

- (void)hvacPickerChangedZone:(NSString *)zone
{
    ;
}

- (void)setHvacLabelText
{
    NSString *entityLabel = [self.model currentHVACEntityName];
    
    if (entityLabel)
    {
        [self.hvacSelector setTitle:entityLabel];
        [self.hvacLabel setText:entityLabel];
    }
}

@end
