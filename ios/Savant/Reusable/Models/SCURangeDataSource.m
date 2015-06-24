//
//  SCURangeDataSource.m
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCURangeDataSource.h"
#import "SCUDateCell.h"
#import "SCUDatePickerCell.h"

@import Extensions;

#define kSecondsInDay 86400

@interface SCURangeDataSource ()

@property NSArray *dataSource;

@end

@implementation SCURangeDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _datePickerFormat = @"yyyyMMMdd";
        _dateFormat = @"MMMM d, yyyy";
        _endDate = [NSDate today];
        _startDate = [NSDate dateWithTimeIntervalSince1970:[_endDate timeIntervalSince1970] - (kSecondsInDay * 6)];
        _minDate = nil;

        [self buildDataSource];
    }
    return self;
}

- (void)buildDataSource
{
    NSMutableArray *dataSource = nil;

    if (self.endOnly)
    {
        dataSource = [@[@{SCUDateCellKeyDate: self.endDate,
                          SCUDateCellKeyDateFormat: self.dateFormat}] mutableCopy];
    }
    else
    {
        dataSource = [@[@{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Starts", nil),
                          SCUDateCellKeyDate: self.startDate,
                          SCUDateCellKeyDateFormat: self.dateFormat},
                        @{SCUDefaultTableViewCellKeyTitle: NSLocalizedString(@"Ends", nil),
                          SCUDateCellKeyDate: self.endDate,
                          SCUDateCellKeyDateFormat: self.dateFormat}] mutableCopy];
    }

    if (self.pickerIndexPath)
    {
        NSUInteger idx = self.pickerIndexPath.row;
        NSUInteger dateIdx = idx - 1;
        
        NSDate *minDate = self.minDate;
        NSDate *maxDate = nil;
        NSDate *date = nil;
        
        SCURangeDateType dateType = SCURangeDateType_End;
        

        if (self.endOnly)
        {
            maxDate = [NSDate today];
            minDate = [NSDate dateWithTimeIntervalSince1970:[minDate timeIntervalSince1970] - (kSecondsInDay * 6)];

            date = self.endDate;
        }
        else
        {
            if (dateIdx == 0)
            {
                minDate = [NSDate dateWithTimeIntervalSince1970:[minDate timeIntervalSince1970] - (kSecondsInDay * 6)];
                maxDate = [NSDate dateWithTimeIntervalSince1970:[[NSDate today] timeIntervalSince1970] - (kSecondsInDay * 6)];
                date = self.startDate;
                dateType = SCURangeDateType_Start;
            }
            else
            {
                minDate = self.minDate;
                maxDate = [NSDate today];
                date = self.endDate;
            }
        }

        if ([dataSource count] >= idx)
        {
            if (self.minDate)
            {
                [dataSource insertObject:@{SCUPickerCellKeyDate: date,
                                           SCUPickerCellKeyMaxDate: maxDate,
                                           SCUPickerCellKeyMinDate: minDate,
                                           SCUPickerCellKeyDateType: @(dateType),
                                           SCUPickerCellKeyDateFormat: self.datePickerFormat}
                                 atIndex:idx];
            }
            else
            {
                [dataSource insertObject:@{SCUPickerCellKeyDate: date,
                                           SCUPickerCellKeyMaxDate: maxDate,
                                           SCUPickerCellKeyDateType: @(dateType),
                                           SCUPickerCellKeyDateFormat: self.datePickerFormat}
                                 atIndex:idx];
            }
        }
    }

    self.dataSource = dataSource;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)setStartDate:(NSDate *)startDate
{
    _startDate = startDate;
    _endDate = [NSDate dateWithTimeIntervalSince1970:[startDate timeIntervalSince1970] + (kSecondsInDay * 6)];

    [self buildDataSource];
}

- (void)setEndDate:(NSDate *)endDate
{
    _endDate = endDate;
    _startDate = [NSDate dateWithTimeIntervalSince1970:[endDate timeIntervalSince1970] - (kSecondsInDay * 6)];

    [self buildDataSource];
}

#pragma clang diagnostic pop

- (void)setEndOnly:(BOOL)endOnly
{
    _endOnly = endOnly;

    [self buildDataSource];
}

- (void)setPickerIndexPath:(NSIndexPath *)datePickerIndexPath
{
    _pickerIndexPath = datePickerIndexPath;

    [self buildDataSource];
}

- (void)setDateFormat:(NSString *)dateFormat
{
    _dateFormat = dateFormat;

    [self buildDataSource];
}

- (void)setDatePickerFormat:(NSString *)datePickerFormat
{
    _datePickerFormat = datePickerFormat;

    [self buildDataSource];
}

- (NSUInteger)cellTypeForIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.pickerIndexPath] ? SCURangeDataSourceType_Picker : SCURangeDataSourceType_Range;
}

@end
