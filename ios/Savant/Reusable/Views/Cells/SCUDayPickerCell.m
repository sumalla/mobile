//
//  SCUDayPickerCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDayPickerCell.h"
#import "SCUButton.h"

NSString *const SCUDayPickerCellKeySelectedDays  = @"SCUDayPickerCellKeySelectedDays";
NSString *const SCUDayPickerCellKeyAvailableDays = @"SCUDayPickerCellKeyAvailableDays";

typedef NS_ENUM(NSInteger, SCUDay)
{
    SCUDay_Sunday    = 0,
    SCUDay_Monday    = 1,
    SCUDay_Tuesday   = 2,
    SCUDay_Wednesday = 3,
    SCUDay_Thursday  = 4,
    SCUDay_Friday    = 5,
    SCUDay_Saturday  = 6
};

@interface SCUDayPickerCell ()

@property NSArray *dayButtons;
@property NSArray *days;
@property NSArray *selectedDayTypes;
@property UIView *buttonView;

@end

@implementation SCUDayPickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.availableDays = SCUDayPickerDays_All;
        self.selectedDays = SCUDayPickerDays_None;
    }
    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if (info[SCUDayPickerCellKeySelectedDays])
    {
        self.selectedDays = [info[SCUDayPickerCellKeySelectedDays] integerValue];
    }

    if (info[SCUDayPickerCellKeyAvailableDays])
    {
        self.availableDays = [info[SCUDayPickerCellKeyAvailableDays] integerValue];
    }
}

- (void)setSelectedDays:(SCUDayPickerDays)selectedDays
{
    if (_selectedDays != selectedDays)
    {
        _selectedDays = selectedDays;

        NSMutableArray *selectedDayTypes = [NSMutableArray array];

        if (self.selectedDays & SCUDayPickerDays_Sunday)
        {
            [selectedDayTypes addObject:@(SCUDay_Sunday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Monday)
        {
            [selectedDayTypes addObject:@(SCUDay_Monday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Tuesday)
        {
            [selectedDayTypes addObject:@(SCUDay_Tuesday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Wednesday)
        {
            [selectedDayTypes addObject:@(SCUDay_Wednesday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Thursday)
        {
            [selectedDayTypes addObject:@(SCUDay_Thursday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Friday)
        {
            [selectedDayTypes addObject:@(SCUDay_Friday)];
        }

        if (self.selectedDays & SCUDayPickerDays_Saturday)
        {
            [selectedDayTypes addObject:@(SCUDay_Saturday)];
        }

        for (SCUButton *button in self.dayButtons)
        {
            if ([selectedDayTypes containsObject:@(button.tag)])
            {
                button.selected = YES;
            }
            else
            {
                button.selected = NO;
            }
        }
        
        self.selectedDayTypes = selectedDayTypes;
        
        if (self.callback)
        {
            self.callback(selectedDays);
        }
    }
}

- (void)setAvailableDays:(SCUDayPickerDays)availableDays
{
    if (_availableDays != availableDays)
    {
        _availableDays = availableDays;

        NSMutableArray *days = [NSMutableArray array];

        if (self.availableDays & SCUDayPickerDays_Sunday)
        {
            [days addObject:@(SCUDay_Sunday)];
        }

        if (self.availableDays & SCUDayPickerDays_Monday)
        {
            [days addObject:@(SCUDay_Monday)];
        }

        if (self.availableDays & SCUDayPickerDays_Tuesday)
        {
            [days addObject:@(SCUDay_Tuesday)];
        }

        if (self.availableDays & SCUDayPickerDays_Wednesday)
        {
            [days addObject:@(SCUDay_Wednesday)];
        }

        if (self.availableDays & SCUDayPickerDays_Thursday)
        {
            [days addObject:@(SCUDay_Thursday)];
        }

        if (self.availableDays & SCUDayPickerDays_Friday)
        {
            [days addObject:@(SCUDay_Friday)];
        }

        if (self.availableDays & SCUDayPickerDays_Saturday)
        {
            [days addObject:@(SCUDay_Saturday)];
        }

        self.days = days;

        [self prepareDayButtons];
    }
}

- (void)prepareDayButtons
{
    NSMutableArray *dayButtons = [NSMutableArray array];

    for (NSNumber *day in self.days)
    {
        SCUDay dayType = [day integerValue];

        SCUButton *dayButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        dayButton.target = self;
        dayButton.releaseAction = @selector(dayButtonToggle:);
        dayButton.tag = dayType;
        dayButton.roundedCorners = YES;
        dayButton.layer.cornerRadius = 19;
        dayButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9];
        dayButton.backgroundColor = [[SCUColors shared] color03shade05];
        dayButton.selectedBackgroundColor = [[SCUColors shared] color01];
        dayButton.selectedColor = [[SCUColors shared] color04];

        if ([self.selectedDayTypes containsObject:day])
        {
            dayButton.selected = YES;
        }

        switch (dayType)
        {
            case SCUDay_Sunday:
                dayButton.title = NSLocalizedString(@"Su", nil);
                break;
            case SCUDay_Monday:
                dayButton.title = NSLocalizedString(@"M", nil);
                break;
            case SCUDay_Tuesday:
                dayButton.title = NSLocalizedString(@"T", nil);
                break;
            case SCUDay_Wednesday:
                dayButton.title = NSLocalizedString(@"W", nil);
                break;
            case SCUDay_Thursday:
                dayButton.title = NSLocalizedString(@"Th", nil);
                break;
            case SCUDay_Friday:
                dayButton.title = NSLocalizedString(@"F", nil);
                break;
            case SCUDay_Saturday:
                dayButton.title = NSLocalizedString(@"Sa", nil);
                break;
        }

        [dayButtons addObject:dayButton];

        [self.buttonView removeFromSuperview];

        SAVViewDistributionConfiguration *config = [[SAVViewDistributionConfiguration alloc] init];
        config.distributeEvenly = YES;
        config.fixedWidth = 38;
        config.fixedHeight = 38;
        self.buttonView = [UIView sav_viewWithEvenlyDistributedViews:dayButtons withConfiguration:config];

        [self.contentView addSubview:self.buttonView];
        [self.contentView sav_pinView:self.buttonView withOptions:SAVViewPinningOptionsCenterY|SAVViewPinningOptionsCenterX];
    }

    self.dayButtons = dayButtons;
}

- (void)dayButtonToggle:(SCUButton *)button
{
    button.selected = !button.selected;

    SCUDayPickerDays selectedDays = SCUDayPickerDays_None;

    for (SCUButton *button in self.dayButtons)
    {
        SCUDay buttonDay = button.tag;

        if (button.selected)
        {
            switch (buttonDay)
            {
                case SCUDay_Sunday:
                    selectedDays |= SCUDayPickerDays_Sunday;
                    break;
                case SCUDay_Monday:
                    selectedDays |= SCUDayPickerDays_Monday;
                    break;
                case SCUDay_Tuesday:
                    selectedDays |= SCUDayPickerDays_Tuesday;
                    break;
                case SCUDay_Wednesday:
                    selectedDays |= SCUDayPickerDays_Wednesday;
                    break;
                case SCUDay_Thursday:
                    selectedDays |= SCUDayPickerDays_Thursday;
                    break;
                case SCUDay_Friday:
                    selectedDays |= SCUDayPickerDays_Friday;
                    break;
                case SCUDay_Saturday:
                    selectedDays |= SCUDayPickerDays_Saturday;
                    break;
            }
        }
    }

    self.selectedDays = selectedDays;
}

@end
