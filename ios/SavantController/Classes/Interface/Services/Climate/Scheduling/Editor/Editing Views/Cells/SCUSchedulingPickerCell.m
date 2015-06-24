//
//  SCUSchedulingPickerCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/17/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSchedulingPickerCell.h"
#import "SCUPickerView.h"
#import "SCUButton.h"
#import "SCUSchedulingHumidityModel.h"
#import <SavantControl/SAVClimateSchedule.h>

typedef NS_ENUM(NSInteger, SCUPickerType)
{
    SCUPickerType_Min,
    SCUPickerType_Max
};

NSString *const SCUSchedulingPickerCellKeyTime          = @"SCUSchedulingPickerCellKeyTime";
NSString *const SCUSchedulingPickerCellKeySetPoint1     = @"SCUSchedulingPickerCellKeySetPoint1";
NSString *const SCUSchedulingPickerCellKeySetPoint2     = @"SCUSchedulingPickerCellKeySetPoint2";
NSString *const SCUSchedulingPickerCellKeyMinTitle      = @"SCUSchedulingPickerCellKeyMinTitle";
NSString *const SCUSchedulingPickerCellKeyMaxTitle      = @"SCUSchedulingPickerCellKeyMaxTitle";
NSString *const SCUSchedulingPickerCellKeyMinColor      = @"SCUSchedulingPickerCellKeyMinColor";
NSString *const SCUSchedulingPickerCellKeyMaxColor      = @"SCUSchedulingPickerCellKeyMaxColor";
NSString *const SCUSchedulingPickerCellKeyUnitsString   = @"SCUSchedulingPickerCellKeyUnitsString";
NSString *const SCUSchedulingPickerCellKeyCellType      = @"SCUSchedulingPickerCellKeyCellType";
NSString *const SCUSchedulingPickerCellKeyCellModeTitle = @"SCUSchedulingPickerCellKeyCellModeTitle";
NSString *const SCUSchedulingPickerCellKeyMode          = @"SCUSchedulingPickerCellKeyMode";
NSString *const SCUSchedulingPickerCellKeyModeEnabled   = @"SCUSchedulingPickerCellKeyModeEnabled";

@interface SCUSchedulingPickerCell ()

@property SCUPickerView *minPickerView, *maxPickerView;
@property NSString *unitString;
@property SCUButton *timeButton;
@property SCUButton *modeButton;
@property SCUButton *addButton, *deleteButton;
@property (weak) UIView *minPickerContainer, *maxPickerContainer;
@property UILabel *minValueLabel, *maxValueLabel;
@property UILabel *timeLabel, *modeLabel;

@end

@implementation SCUSchedulingPickerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [[SCUColors shared] color03shade03];

        SCUButton *timeButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        timeButton.color = [[SCUColors shared] color04];
        timeButton.backgroundColor = nil;
        timeButton.selectedBackgroundColor = nil;
        timeButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:15];
        [self.contentView addSubview:timeButton];
        [self.contentView sav_pinView:timeButton withOptions:SAVViewPinningOptionsToTop withSpace:20];
        [self.contentView sav_pinView:timeButton withOptions:SAVViewPinningOptionsToLeft withSpace:40];

        self.timeButton = timeButton;
        
        SCUButton *modeButton = [[SCUButton alloc] initWithFrame:CGRectZero];
        modeButton.color = [[SCUColors shared] color04];
        modeButton.backgroundColor = nil;
        modeButton.selectedBackgroundColor = [[SCUColors shared] color01];
        modeButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:15];
        [self.contentView addSubview:modeButton];
        [self.contentView sav_pinView:modeButton withOptions:SAVViewPinningOptionsCenterX withSpace:22];
        [self.contentView sav_pinView:modeButton withOptions:SAVViewPinningOptionsCenterY withSpace:0];
        
        self.modeButton = modeButton;
        
        SCUButton *deleteButton = [[SCUButton alloc] initWithTitle:@"x"];
        deleteButton.titleLabel.font = [UIFont fontWithName:@"Gotham" size:24];
        deleteButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:deleteButton];
        [self.contentView sav_setSize:CGSizeMake(40, 40) forView:deleteButton isRelative:NO];
        [self.contentView sav_pinView:deleteButton withOptions:SAVViewPinningOptionsToTop];
        [self.contentView sav_pinView:deleteButton withOptions:SAVViewPinningOptionsToRight withSpace:10];

        self.deleteButton = deleteButton;

        SCUButton *addButton = [[SCUButton alloc] initWithTitle:@"+"];
        addButton.backgroundColor = nil;
        addButton.color = [UIColor sav_colorWithRGBValue:0xfc7321];
        addButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:32];
        [self.contentView addSubview:addButton];
        [self.contentView sav_pinView:addButton withOptions:SAVViewPinningOptionsToBottom|SAVViewPinningOptionsCenterX withSpace:[UIScreen screenPixel]];
        [self.contentView sav_setWidth:.83 forView:addButton isRelative:YES];

        self.addButton = addButton;
        
        UILabel *modeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        modeLabel.text = [NSLocalizedString(@"mode", nil) uppercaseString];
        modeLabel.font = [UIFont systemFontOfSize:11];
        modeLabel.textColor = [[SCUColors shared] color04];
        
        [self.contentView addSubview:modeLabel];
        [self.contentView sav_pinView:modeLabel withOptions:SAVViewPinningOptionsToLeft ofView:modeButton withSpace:7];
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                  views:@{@"modeLabel" : modeLabel, @"modeButton": self.modeButton}
                                                                                formats:@[@"modeLabel.centerY = modeButton.centerY"]]];
        
        self.modeLabel = modeLabel;
        
        [self.contentView addSubview:modeLabel];
        [self.contentView sav_pinView:modeLabel withOptions:SAVViewPinningOptionsToLeft ofView:modeButton withSpace:8];

        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        timeLabel.text = [NSLocalizedString(@"at", nil) uppercaseString];
        timeLabel.font = [UIFont systemFontOfSize:11];
        timeLabel.textColor = [[SCUColors shared] color04];
        
        [self.contentView addSubview:timeLabel];
        [self.contentView sav_pinView:timeLabel withOptions:SAVViewPinningOptionsToLeft ofView:timeButton withSpace:5];
        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:nil
                                                                                  views:@{@"timeLabel" : timeLabel, @"timeButton": self.timeButton}
                                                                                formats:@[@"timeLabel.centerY = timeButton.centerY"]]];
        
        self.timeLabel = timeLabel;
        
        [self.contentView addSubview:timeLabel];
        [self.contentView sav_pinView:timeLabel withOptions:SAVViewPinningOptionsToLeft ofView:timeButton withSpace:8];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.timeButton.hidden      = YES;
    self.addButton.hidden       = YES;
    self.timeLabel.hidden       = YES;
    self.deleteButton.hidden    = YES;
    self.modeButton.hidden      = YES;
    self.modeLabel.hidden       = YES;
}

- (void)setMinSetPoint:(NSInteger)value
{
    self.minValueLabel.text = [[@(value) stringValue] stringByAppendingString:self.unitString];
}

- (void)setMaxSetPoint:(NSInteger)value
{
    self.maxValueLabel.text = [[@(value) stringValue] stringByAppendingString:self.unitString];
}

- (void)configureWithInfo:(NSDictionary *)info
{
    if ([info[SCUSchedulingPickerCellKeyCellType] isEqual: @(SCUSchedulingPickerCellTypeTemp)] || [info[SCUSchedulingPickerCellKeyCellType] isEqual: @(SCUSchedulingPickerCellTypeHumidity)])
    {
        self.addButton.hidden  = NO;
        self.timeButton.hidden = NO;
        self.timeLabel.hidden = NO;
        self.deleteButton.hidden = NO;
        self.modeButton.hidden = YES;
        self.modeLabel.hidden  = YES;
        
        self.unitString = info[SCUSchedulingPickerCellKeyUnitsString];

        [self.minPickerContainer removeFromSuperview];
        [self.maxPickerContainer removeFromSuperview];
        
        if ([info[SCUSchedulingPickerCellKeyCellType] isEqual: @(SCUSchedulingPickerCellTypeTemp)])
        {
            SAVClimateScheduleMode mode = [info[SCUSchedulingPickerCellKeyMode] integerValue];

            switch (mode)
            {
                case SAVClimateScheduleMode_Auto:
                {
                    [self setupBothPickersWithInfo:info];
                    break;
                }
                case SAVClimateScheduleMode_Heat:
                {
                    [self setupMinPickerWithInfo:info];
                    break;
                }
                case SAVClimateScheduleMode_Cool:
                {
                    [self setupMaxPickerWithInfo:info];
                    break;
                }
            }
        }
        else if ([info[SCUSchedulingPickerCellKeyCellType] isEqual: @(SCUSchedulingPickerCellTypeHumidity)])
        {
            self.addButton.hidden  = NO;
            self.timeButton.hidden = NO;
            self.timeLabel.hidden = NO;
            
            SCUSchedulingHumidityMode mode = [info[SCUSchedulingPickerCellKeyMode] integerValue];
            
            switch (mode)
            {
                case SCUSchedulingHumidityModeBoth:
                    [self setupBothPickersWithInfo:info];
                    break;
                case SCUSchedulingHumidityModeDehumidify:
                    [self setupMaxPickerWithInfo:info];
                    break;
                case SCUSchedulingHumidityModeHumidity:
                case SCUSchedulingHumidityModeHumidify:
                    [self setupMinPickerWithInfo:info];
                    break;
            }
    
        }
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"HH:mm:ss";

        NSDate *date = [df dateFromString:info[SCUSchedulingPickerCellKeyTime]];
        df.timeStyle = NSDateFormatterShortStyle;

        self.timeButton.title = [df stringFromDate:date];
    }
    else if ([info[SCUSchedulingPickerCellKeyCellType] isEqual: @(SCUSchedulingPickerCellTypeMode)])
    {
        self.addButton.hidden    = YES;
        self.deleteButton.hidden = YES;
        self.timeButton.hidden   = YES;
        self.modeButton.hidden   = NO;
        self.modeLabel.hidden    = NO;
        self.timeLabel.hidden    = YES;
        
        if (info[SCUSchedulingPickerCellKeyCellModeTitle])
        {
            self.modeButton.title = info[SCUSchedulingPickerCellKeyCellModeTitle];
        }
        
        if (![info[SCUSchedulingPickerCellKeyModeEnabled] boolValue])
        {
            self.modeButton.titleLabel.textColor = [[SCUColors shared] color03shade06];
        }
        
        self.modeButton.enabled = [info[SCUSchedulingPickerCellKeyModeEnabled] boolValue];
        
    }
    else
    {
        self.addButton.hidden    = NO;
        self.deleteButton.hidden = YES;
        self.timeButton.hidden   = YES;
        self.modeButton.hidden   = YES;
        self.modeLabel.hidden   = YES;
        self.timeLabel.hidden    = YES;
    }
}

- (void)setupBothPickersWithInfo:(NSDictionary *)info
{
    NSString *point1 = [NSString stringWithFormat:@"%.0f", [info[SCUSchedulingPickerCellKeySetPoint1] floatValue]];
    NSString *point2 = [NSString stringWithFormat:@"%.0f", [info[SCUSchedulingPickerCellKeySetPoint2] floatValue]];
    
    UIView *minContainer = [[UIView alloc] initWithFrame:CGRectZero];
    UIView *maxContainer = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIView *minPicker = [self setupPickerViewWithTitle:info[SCUSchedulingPickerCellKeyMinTitle] value:point2 type:SCUPickerType_Min andColor:info[SCUSchedulingPickerCellKeyMinColor]];
    UIView *maxPicker = [self setupPickerViewWithTitle:info[SCUSchedulingPickerCellKeyMaxTitle] value:point1 type:SCUPickerType_Max andColor:info[SCUSchedulingPickerCellKeyMaxColor]];
    
    [self.contentView addSubview:minContainer];
    [self.contentView sav_setHeight:90 forView:minContainer isRelative:NO];
    [self.contentView sav_setWidth:0.45 forView:minContainer isRelative:YES];
    [self.contentView sav_pinView:minContainer withOptions:SAVViewPinningOptionsToLeft withSpace:10];
    [self.contentView sav_pinView:minContainer withOptions:SAVViewPinningOptionsToBottom withSpace:60];
    
    [self.contentView addSubview:maxContainer];
    [self.contentView sav_setHeight:90 forView:maxContainer isRelative:NO];
    [self.contentView sav_setWidth:0.45 forView:maxContainer isRelative:YES];
    [self.contentView sav_pinView:maxContainer withOptions:SAVViewPinningOptionsToRight withSpace:10];
    [self.contentView sav_pinView:maxContainer withOptions:SAVViewPinningOptionsToBottom withSpace:60];
    
    [minContainer addSubview:minPicker];
    [minContainer sav_addCenteredConstraintsForView:minPicker];
    
    [maxContainer addSubview:maxPicker];
    [maxContainer sav_addCenteredConstraintsForView:maxPicker];
    
    
    self.minPickerContainer = minPicker;
    self.maxPickerContainer = maxPicker;
}

- (void)setupMinPickerWithInfo:(NSDictionary *)info
{
    NSString *point2 = [NSString stringWithFormat:@"%.0f", [info[SCUSchedulingPickerCellKeySetPoint2] floatValue]];
    UIView *minPicker = [self setupPickerViewWithTitle:info[SCUSchedulingPickerCellKeyMinTitle] value:point2 type:SCUPickerType_Min andColor:info[SCUSchedulingPickerCellKeyMinColor]];
    
    [self.contentView addSubview:minPicker];
    [self.contentView sav_pinView:minPicker withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_pinView:minPicker withOptions:SAVViewPinningOptionsToBottom withSpace:60];
    [self.contentView sav_setHeight:90 forView:minPicker isRelative:NO];
    [self.contentView sav_setWidth:0.4 forView:minPicker isRelative:YES];
    
    self.minPickerContainer = minPicker;
}

- (void)setupMaxPickerWithInfo:(NSDictionary *)info
{
    NSString *point1 = [NSString stringWithFormat:@"%.0f", [info[SCUSchedulingPickerCellKeySetPoint1] floatValue]];
    UIView *maxPicker = [self setupPickerViewWithTitle:info[SCUSchedulingPickerCellKeyMaxTitle] value:point1 type:SCUPickerType_Max andColor:info[SCUSchedulingPickerCellKeyMaxColor]];
    
    [self.contentView addSubview:maxPicker];
    [self.contentView sav_pinView:maxPicker withOptions:SAVViewPinningOptionsCenterX];
    [self.contentView sav_pinView:maxPicker withOptions:SAVViewPinningOptionsToBottom withSpace:60];
    [self.contentView sav_setHeight:90 forView:maxPicker isRelative:NO];
    [self.contentView sav_setWidth:0.4 forView:maxPicker isRelative:YES];
    
    self.maxPickerContainer = maxPicker;
}

- (UIView *)setupPickerViewWithTitle:(NSString *)title value:(NSString *)value type:(SCUPickerType)type andColor:(UIColor *)color
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectZero];

    SCUPickerView *pickerView = [[SCUPickerView alloc] initWithConfiguration:SCUPickerViewConfigurationTwoArrowsVerticalClimate];
    pickerView.tintColor = color;
    pickerView.holdTime = .2;
    [containerView addSubview:pickerView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = [title uppercaseString];
    titleLabel.textColor = color;
    titleLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isShortPhone] ? 14 : 17];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = .5;
    [containerView addSubview:titleLabel];

    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    valueLabel.textColor = color;
    valueLabel.font = [UIFont fontWithName:@"Gotham-Extra-light-Savant" size:[UIDevice isShortPhone] ? 36 : 42];
    valueLabel.adjustsFontSizeToFitWidth = YES;
    valueLabel.minimumScaleFactor = 0.8;
    [containerView addSubview:valueLabel];
    valueLabel.text = [value stringByAppendingString:self.unitString];
    
    [containerView addConstraints:[NSLayoutConstraint sav_constraintsWithMetrics:@{@"pickerWidth" : @40}
                                                                           views:@{@"picker": pickerView,
                                                                                   @"title": titleLabel,
                                                                                   @"value": valueLabel}
                                                                         formats:@[@"|[picker(pickerWidth)]-(5)-[value]|",
                                                                                   @"|[picker(pickerWidth)]-(5)-[title]|",
                                                                                   @"V:|[picker(90)]|",
                                                                                   @"V:|[title][value]|"]]];
    
    switch (type)
    {
        case SCUPickerType_Max:
            self.maxPickerView = pickerView;
            self.maxValueLabel = valueLabel;
            break;
        case SCUPickerType_Min:
            self.minPickerView = pickerView;
            self.minValueLabel = valueLabel;
            break;
    }

    return containerView;
}

@end
