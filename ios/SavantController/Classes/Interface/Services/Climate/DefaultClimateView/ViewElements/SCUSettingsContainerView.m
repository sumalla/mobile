//
//  SCUSettingsContainerView.m
//  SavantController
//
//  Created by Jason Wolkovitz on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSettingsContainerView.h"
#import "SCUServiceViewController.h"

@interface SCUSettingsContainerView()

@property (nonatomic) UIFont *labelFont;
@property (nonatomic) UIFont *buttonFont;

@property (nonatomic) BOOL loaded;

@end

@implementation SCUSettingsContainerView

- (instancetype)initWithSettingsContainerModel:(SCUSettingsConainerViewModel *)model
{
    self = [super init];
    if (self)
    {
        self.loaded = NO;
        self.model = model;
        self.minimumWidth = 0;
        self.labelFont = [UIFont fontWithName:@"Gotham-Book" size:12.0f];
        self.buttonFont = [UIFont fontWithName:@"Gotham-Book" size:14.0f];
        self.columnsSpacing = 4.0f;//defult for pool but could change it
    }
    return self;
}

- (void)setModel:(SCUSettingsConainerViewModel *)model
{
    _model = model;
    self.model.delegate = self;
    if (self.loaded)
    {
        [self removeConstraints:[self constraints]];
        for (UIView *aView in [self subviews])
        {
            [aView removeFromSuperview];
        }
        [self loadView];
    }
}

- (void)loadView
{
    self.loaded = YES;
    [self setUpSettingsButtons];
    [self layoutSettingsButtons];
}

- (void)setUpSettingsButtons
{
    self.settingsButtonsLabels = [[NSMutableArray alloc] init];
    self.settingsButtons = [[NSMutableArray alloc] init];
    NSNumber *lastObjectOfSettingsGrouping = [self.model.settingsGroup lastObject];
   
    if (lastObjectOfSettingsGrouping)
    {
        for (NSUInteger i = 0; (NSInteger)i <= [lastObjectOfSettingsGrouping integerValue]; i++)
        {
            NSArray *settingCommands = [self.model getSettingsOptionsArrayForSettingIndex:i subsectionIndex:0];
            
            if (self.model.titlesForSettingButtons && [self.model.titlesForSettingButtons count] > i && settingCommands && [settingCommands count] > 0)
            {
                NSString *settingLabel = NSLocalizedString(self.model.titlesForSettingButtons[i], nil);
                
                UILabel *buttonLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                buttonLabel.font = self.labelFont;
                buttonLabel.textColor = [[SCUColors shared] color04];
                buttonLabel.backgroundColor = [UIColor clearColor];
                buttonLabel.textAlignment = NSTextAlignmentLeft;
                buttonLabel.text = settingLabel;
                
                [self.settingsButtonsLabels addObject:buttonLabel];
                
                SCUButton *settingsButton = [[SCUButton alloc] initWithTitle:@"--"];
                settingsButton.imageView.contentMode = UIViewContentModeRight;
                [settingsButton setFrame:CGRectZero];
                
                settingsButton.titleLabel.font =  self.buttonFont;
                settingsButton.titleLabel.textColor = [[SCUColors shared] color04];
                
                settingsButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
                settingsButton.borderWidth = [UIScreen screenPixel];
                settingsButton.borderColor = [UIColor colorWithWhite:0 alpha:0.10];

                settingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                
                settingsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
                settingsButton.clipsToBounds = YES;
                settingsButton.target = self;
                settingsButton.releaseAction = @selector(settingsButtonPressed:);
                settingsButton.tag = i;
                
                [self.settingsButtons addObject:settingsButton];
            }
        }
    }
}

- (CGFloat)longestLocalizeStringLengthInArrayOrNestedArray:(NSArray *)stringsArray withFont:(UIFont *)font
{
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [aLabel setFont:font];
    CGFloat longest = 0;
    for (NSObject *arrayObject in stringsArray)
    {
        if ([arrayObject isKindOfClass:[NSString class]])
        {
            NSString *aString = (NSString *)arrayObject;
            [aLabel setText:NSLocalizedString(aString, nil)];
            [aLabel sizeToFit];
            longest = MAX(longest, aLabel.frame.size.width);
        }
        else if ([arrayObject isKindOfClass:[NSArray class]])
        {
            NSArray *subArray = (NSArray *)arrayObject;
            longest = MAX(longest, [self longestLocalizeStringLengthInArrayOrNestedArray:subArray withFont:font]);
        }
    }
    return longest;
}

- (void)layoutSettingsButtons
{
    if (!self.settingsButtonsLabels || [self.settingsButtonsLabels count] == 0)
    {
        return;
    }
    
    NSDictionary *metrics = [self getMetricsForDefaultLayout];
    
    NSMutableDictionary *views = [self getViewsForDefaultLayout];
    
    for (NSString *viewKey in [views allKeys])
    {
        [self addSubview:views[viewKey]];
        if ([views[viewKey] isKindOfClass:[SCUButton class]])
        {
            [self sendSubviewToBack:(UIView *)views[viewKey]];
            CGFloat buttonInsetLeft = self.minimumWidth - [(NSNumber  *)metrics[@"buttonWidthCalculated"] floatValue];
            [(SCUButton *)views[viewKey] setImageEdgeInsets:(UIEdgeInsetsMake(0, buttonInsetLeft, 0, 0))];
            [(SCUButton *)views[viewKey] setTitleEdgeInsets:(UIEdgeInsetsMake(0, buttonInsetLeft, 0, 0))];
        }
    }
    
    views[@"containerView"] = self;
    
    NSArray *formats = [self getFormatsForDefaultLayout];
//    
//    [[self superview] addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
//                                                                            metrics:metrics
//                                                                              views:views
//                                                                            formats:@[
//                                                                                     //// @"[containerView(BGWidth)]",
//                                                                                     // @"V:[containerView(BGHeight)]"
//                                                                                      ]
//                                      ]];
    
    self.defaultConstraints = [NSLayoutConstraint sav_constraintsWithOptions:0
                                                                     metrics:metrics
                                                                       views:views
                                                                     formats:formats];
    [self addConstraints:self.defaultConstraints];
}

- (NSDictionary *)getMetricsForDefaultLayout
{
    if (self.minimumWidth < 1)
    {
        self.minimumWidth = ([UIDevice isPad] ? 180.0f : 160.0f);
    }
//    self.backgroundColor = [UIColor sav_colorWithRGBValue:0xcbcbcb alpha:0.2];
    
    CGFloat settingsButtonHeight = [UIDevice isPad] ? 45.0f : 45.0f;
    CGFloat settingsInnerSpacingH = [UIDevice isPad] ? 16.0f : 8.0f;
    CGFloat settingsInnerSpacingV = [UIDevice isPad] ? 3.0f : 2.0f;
    NSMutableArray *settingsCommands = [[self.model getSettingsOptionsArrayForSettingIndex:0 subsectionIndex:0] mutableCopy];
    NSNumber *lastObjectOfSettingsGrouping = [self.model.settingsGroup lastObject];
    if (lastObjectOfSettingsGrouping)
    {
        for (NSUInteger i = 1; i < [lastObjectOfSettingsGrouping unsignedIntegerValue]; i++)
        {
            [settingsCommands arrayByAddingObjectsFromArray:[self.model getSettingsOptionsArrayForSettingIndex:i subsectionIndex:0]];
        }
    }
    NSMutableArray *settingsLabels = [[NSMutableArray alloc] initWithCapacity:[settingsCommands count]];
    for (NSNumber *command in settingsCommands)
    {
        NSObject *titleOrImage = [self.model imageOrTitleForState:[command integerValue]];
        if ([titleOrImage isKindOfClass:[NSString class]])
        {
            [settingsLabels addObject:titleOrImage];
        }
    }
    CGFloat lablePadding = 20.0f;
    CGFloat settingsLabelWidth = MAX([self longestLocalizeStringLengthInArrayOrNestedArray:self.model.titlesForSettingButtons withFont:self.labelFont] + lablePadding, [UIDevice isPad] ? 60.0f : 56.0f);
    
    CGFloat settingsButtonWidth = MAX([self longestLocalizeStringLengthInArrayOrNestedArray:settingsLabels withFont:self.buttonFont] + lablePadding, [UIDevice isPad] ? 70.0f : 56.0f);
    CGFloat settingsBGWidth = settingsLabelWidth + settingsButtonWidth + settingsInnerSpacingH * 3;
    CGFloat settingsBGHeight = [self.settingsButtonsLabels count] * (settingsButtonHeight + settingsInnerSpacingV) + settingsInnerSpacingV;
    
    self.minimumWidth = MAX(settingsButtonWidth + settingsLabelWidth, self.minimumWidth);

    NSDictionary *metrics = @{@"BGWidth": @(settingsBGWidth),
                              @"BGHeight": @(settingsBGHeight),
                              @"spacingH": @(settingsInnerSpacingH),
                              @"spacingV": @(settingsInnerSpacingV),
                              @"columnsSpacing": @(self.columnsSpacing),
                              @"buttonWidth": @(self.minimumWidth),
                              @"buttonWidthCalculated": @(settingsButtonWidth),
                              @"buttonHeight": @(settingsButtonHeight),
                              @"labelWidth": @(settingsLabelWidth)
                              };
    return metrics;
}

- (NSMutableDictionary *)getViewsForDefaultLayout
{
    NSMutableDictionary *views = [[NSMutableDictionary alloc] initWithCapacity:[self.settingsButtonsLabels count] * 2];
    
    for (NSUInteger i = 0; i < [self.settingsButtonsLabels count]; i++)
    {
        SCUButton *settingsButton = self.settingsButtons[i];
        UILabel *settingsLabel = self.settingsButtonsLabels[i];
        
        views[scuSettingsButtonKey(i)] = settingsButton;
        views[scuSettingsLabelKey(i)] = settingsLabel;
    }
    return views;
}

- (NSArray *)getFormatsForDefaultLayout
{
    return [self buttonAndLabelConstraintsGroupFromIndex:0
                                               lastIndex:[self.settingsButtonsLabels count]
                                  numberOfItemsPerColumn:[self.settingsButtonsLabels count]
            ];
}

- (NSArray *)getFormatsForMaxColumns:(NSUInteger)maxColumns
{
    NSUInteger totalButtons = [self.settingsButtonsLabels count];
    NSUInteger buttonsPerColumn = totalButtons / (float)maxColumns + 0.5;
    NSUInteger numberOfColumns = 0;
    
    NSMutableArray *formats = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < maxColumns; i++)
    {
        NSUInteger firstIndex = i * buttonsPerColumn;
        NSUInteger lastIndex = (((i + 1) * buttonsPerColumn) - 1);
        if (firstIndex >= totalButtons)
        {
            break;
        }
        if (lastIndex >= totalButtons)
        {
            lastIndex = totalButtons - 1;
        }
        numberOfColumns++;
        
        NSArray *tempFormats = [self buttonAndLabelConstraintsGroupFromIndex:firstIndex
                                                                   lastIndex:lastIndex
                                                      numberOfItemsPerColumn:buttonsPerColumn];
        if ([tempFormats count] > 0)
        {
            [formats addObjectsFromArray:tempFormats];
        }
    }
    if (numberOfColumns > 0)
    {
        NSString *spaceConstraintH = @"-(columnsSpacing)-";
        NSString *settingsButtonKey = scuSettingsButtonKey(0);

        NSMutableString *horizontalButtonConstraint = [[NSString stringWithFormat:@"|[%@]", settingsButtonKey]mutableCopy];
        NSMutableString *horizontalButtonSizeConstraint;

        for (NSUInteger i = 1; i < numberOfColumns; i++)
        {
            settingsButtonKey = scuSettingsButtonKey(i * buttonsPerColumn);
            [horizontalButtonConstraint appendString:[NSString stringWithFormat:@"%@[%@]", spaceConstraintH, settingsButtonKey]];
            horizontalButtonSizeConstraint = [[NSString stringWithFormat:@"[%@(==%@)]", settingsButtonKey, scuSettingsButtonKey(0)]mutableCopy];
            [formats addObject:horizontalButtonSizeConstraint];
        }
        
        [horizontalButtonConstraint appendString:@"|"];
        [formats addObject:horizontalButtonConstraint];
    }
    
    return formats;
}

- (NSArray *)buttonAndLabelConstraintsGroupFromIndex:(NSUInteger)firstIndex lastIndex:(NSUInteger)lastIndex numberOfItemsPerColumn:(NSUInteger)numberOfItems
{
    NSString *spaceConstraintV = @"-(spacingV)-";
    NSMutableString *verticalLabelConstraints = [@"V:|" mutableCopy];
    NSMutableString *verticalButtonConstraints = [@"V:|" mutableCopy];
    
    BOOL singelColumn = (firstIndex == 0 && lastIndex == [self.settingsButtonsLabels count]);
    
    NSMutableArray *formats = [@[] mutableCopy];
    NSString *previousLabelViewKey;
    NSString *previousButtonViewKey;
    
    NSUInteger loopCount = 0;
    for (NSUInteger i = firstIndex; i < MIN([self.settingsButtonsLabels count], lastIndex + 1); i++)
    {
        NSString *settingsButtonKey = scuSettingsButtonKey(i);
        NSString *settingsLabelKey = scuSettingsLabelKey(i);
        
        if (previousLabelViewKey)
        {
            [verticalLabelConstraints appendString:[NSString stringWithFormat:@"%@[%@(==%@)]", spaceConstraintV, settingsLabelKey, previousLabelViewKey]];
        }
        else
        {
            [verticalLabelConstraints appendString:[NSString stringWithFormat:@"%@[%@(%@)]", spaceConstraintV, settingsLabelKey, @"buttonHeight"]];
        }
        previousLabelViewKey = settingsLabelKey;
        [verticalButtonConstraints appendString:[NSString stringWithFormat:@"%@[%@(==%@)]", spaceConstraintV, settingsButtonKey, settingsLabelKey]];
        
        NSString *horizontaLabellConstraint = [NSString stringWithFormat:@"[%@(labelWidth)]", settingsLabelKey];
        [formats addObject:horizontaLabellConstraint];
        
        horizontaLabellConstraint = [NSString stringWithFormat:@"%@.left = %@.left + spacingH", settingsLabelKey, settingsButtonKey];
        [formats addObject:horizontaLabellConstraint];

        NSString *horizontalButtonConstraint;
        if (singelColumn)
        {
            horizontalButtonConstraint = [NSString stringWithFormat:@"|[%@(buttonWidth)]|", settingsButtonKey];
            [formats addObject:horizontalButtonConstraint];
        }
        else
        {
            if (previousButtonViewKey)
            {
                horizontalButtonConstraint = [NSString stringWithFormat:@"%@.centerX = %@.centerX", settingsButtonKey, previousButtonViewKey];
                [formats addObject:horizontalButtonConstraint];
                horizontalButtonConstraint = [NSString stringWithFormat:@"[%@(==%@)]", settingsButtonKey, previousButtonViewKey];
                [formats addObject:horizontalButtonConstraint];
            }
            previousButtonViewKey = settingsButtonKey;
        }
        loopCount++;
    }
    
    if (loopCount == numberOfItems)
    {
        [verticalLabelConstraints appendString:spaceConstraintV];
        [verticalButtonConstraints appendString:spaceConstraintV];
        [verticalLabelConstraints appendString:@"|"];
        [verticalButtonConstraints appendString:@"|"];
    }
    
    [formats addObject:verticalButtonConstraints];
    [formats addObject:verticalLabelConstraints];

    return formats;
}

- (void)settingsButtonPressed:(SCUButton *)button
{
    [self.model settingsButtonTouchedWithIndex:button.tag];
}

- (void)showSettingsPopupPickerForSettingsIndex:(NSUInteger)settingsIndex
{
    if ([self.settingsButtons count] > settingsIndex)
    {
        if (self.tablePopover)
        {
            self.tablePopover = nil;
        }
        if (self.settingsPicker)
        {
            self.settingsPicker = nil;
        }
        self.settingsPicker = [[SCUClimateModeTableViewController alloc] initWithStyle:UITableViewStylePlain withSettingsModel:self.model settingsIndex:settingsIndex];
        self.settingsPicker.delegate = self;

        self.tablePopover = [[SCUPopoverController alloc] initWithContentViewController:self.settingsPicker];
        self.tablePopover.backgroundColor = [UIColor whiteColor];
        self.tablePopover.popoverContentSize = [self.settingsPicker tabelViewSize];

        //self.tablePopover.backgroundColor = self.backgroundColor;
        SCUButton *button = self.settingsButtons[settingsIndex];
        CGRect buttonTitleFrame = button.titleLabel.frame;
        CGPoint p = [button convertPoint:CGPointMake(buttonTitleFrame.origin.x, buttonTitleFrame.origin.y) toView:self];
        buttonTitleFrame.origin.x = p.x;
        buttonTitleFrame.origin.y = p.y;

        [self.tablePopover presentPopoverFromRect:buttonTitleFrame
                                           inView:[button superview]
                         permittedArrowDirections:[self popoverArrowDirection]
                                         animated:YES];
    }
}

- (UIPopoverArrowDirection)popoverArrowDirection
{
    return UIPopoverArrowDirectionDown;
}

- (void)settingsUpdatedWithIndexPath:(NSIndexPath *)indexPath settingsIndex:(NSUInteger)settingsIndex shouldDismissTable:(BOOL)dismiss
{
    //could use indexPath and settings Index temporally set the setting index until the state is returned or timed out
    if (self.tablePopover && dismiss)
    {
        [self.tablePopover dismissPopoverAnimated:YES];
        self.tablePopover = nil;
    }
}

#pragma Model Delegate methods

- (void)didReceiveClimateSetPointMode:(SAVEntityState)mode withIndex:(NSUInteger)index
{
    if ([self.settingsButtons count] > index)
    {
        if (self.settingsPicker)
        {
            [self.settingsPicker.tableView reloadData];
        }
        SCUButton *modeButton = self.settingsButtons[index];
        NSObject *titleOrImage = [self.model imageOrTitleForState:mode];
        if ([titleOrImage isKindOfClass:[UIImage class]])
        {
            [modeButton setTitle:nil];
            [modeButton setImage:(UIImage *)titleOrImage];
//            modeButton.imageView.contentMode = UIViewContentModeRight;
        }
        else
        {
            [modeButton setImage:nil];
            [modeButton setTitle:(NSString *)titleOrImage];
//            modeButton.titleLabel.textAlignment = NSTextAlignmentRight;
        }
    }
}

@end
