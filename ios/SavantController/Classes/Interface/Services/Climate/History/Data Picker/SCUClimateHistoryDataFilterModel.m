//
//  SCUClimateHistoryDataFilterModel.m
//  SavantController
//
//  Created by Nathan Trapp on 7/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClimateHistoryDataFilterModel.h"
#import "SCUClimateHistoryDataFilterCell.h"
#import "SCUClimateHistoryDayViewController.h"

#import <SavantExtensions/SavantExtensions.h>

@implementation SCUClimateHistoryDataFilterModel

- (void)listenToSwitch:(UISwitch *)toggleSwith forIndexPath:(NSIndexPath *)indexPath
{
    SAVWeakSelf;
    toggleSwith.sav_didChangeHandler = ^(BOOL on){
        if (on != [wSelf.delegate chartIsVisible:indexPath.row])
        {
            [wSelf.delegate toggleChart:indexPath.row];
        }
    };
}

- (NSString *)chartNameForType:(SCUClimateHistoryDayPlotType)type
{
    NSString *name = nil;

    switch (type)
    {
        case SCUClimateHistoryDayPlotType_IndoorTemp:
            name = NSLocalizedString(@"Indoor Temp", nil);
            break;
        case SCUClimateHistoryDayPlotType_HeatPoint:
            name = NSLocalizedString(@"Heat Point", nil);
            break;
        case SCUClimateHistoryDayPlotType_CoolPoint:
            name = NSLocalizedString(@"Cool Point", nil);
            break;
        case SCUClimateHistoryDayPlotType_Humidity:
            name = NSLocalizedString(@"Humidity", nil);
            break;
        case SCUClimateHistoryDayPlotType_Heating:
            name = NSLocalizedString(@"Heating", nil);
            break;
        case SCUClimateHistoryDayPlotType_Cooling:
            name = NSLocalizedString(@"Cooling", nil);
            break;
        case SCUClimateHistoryDayPlotType_FanOn:
            name = NSLocalizedString(@"Fan On", nil);
            break;
    }

    return name;
}

- (UIView *)chartStyleForType:(SCUClimateHistoryDayPlotType)type
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    CGRect frame = CGRectZero;

    switch (type)
    {
        case SCUClimateHistoryDayPlotType_IndoorTemp:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0xed145b];
            frame.size.width = 15;
            frame.size.height = 6;
            break;
        case SCUClimateHistoryDayPlotType_HeatPoint:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0xe46a08];
            frame.size.width = 16;
            frame.size.height = 16;
            view.layer.cornerRadius = 8;
            view.clipsToBounds = YES;
            break;
        case SCUClimateHistoryDayPlotType_CoolPoint:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0x00b4d5];
            frame.size.width = 16;
            frame.size.height = 16;
            view.layer.cornerRadius = 8;
            view.clipsToBounds = YES;
            break;
        case SCUClimateHistoryDayPlotType_Humidity:
        {
            frame.size.width = 15;
            frame.size.height = 2;

            CAShapeLayer *layer = [[CAShapeLayer alloc] init];
            layer.frame = frame;
            layer.strokeColor = [UIColor sav_colorWithRGBValue:0x00cc00].CGColor;
            layer.lineWidth = 2;
            layer.lineJoin = kCALineJoinMiter;
            layer.lineDashPattern = @[@2, @2];

            CGMutablePathRef path = CGPathCreateMutable();
            CGPathMoveToPoint(path, NULL, 0, 0);
            CGPathAddLineToPoint(path, NULL, 15, 0);

            layer.path = path;

            CGPathRelease(path);

            [view.layer addSublayer:layer];
        }
            break;
        case SCUClimateHistoryDayPlotType_Heating:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0xe46a08];
            frame.size.width = 15;
            frame.size.height = 8;
            break;
        case SCUClimateHistoryDayPlotType_Cooling:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0x00b4d5];
            frame.size.width = 15;
            frame.size.height = 8;
            break;
        case SCUClimateHistoryDayPlotType_FanOn:
            view.backgroundColor = [UIColor sav_colorWithRGBValue:0x999999];
            frame.size.width = 15;
            frame.size.height = 8;
            break;
    }
    
    view.frame = frame;
    
    return view;
}

#pragma mark - Data Source

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return 7;
}

- (id)modelObjectForIndexPath:(NSIndexPath *)indexPath
{
    SCUClimateHistoryDayPlotType type = (SCUClimateHistoryDayPlotType)indexPath.row;

    return @{SCUDefaultTableViewCellKeyTitle: [self chartNameForType:indexPath.row],
             SCUClimateHistoryDataFilterCellKeyState: @([self.delegate chartIsVisible:type]),
             SCUClimateHistoryDataFilterCellKeyStyle: [self chartStyleForType:type]};
}

@end
