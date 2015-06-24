//
//  SCURangeDataSource.h
//  SavantController
//
//  Created by Nathan Trapp on 7/4/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

typedef NS_ENUM(NSUInteger, SCURangeDataSourceType)
{
    SCURangeDataSourceType_Range,
    SCURangeDataSourceType_Picker
};

typedef NS_ENUM(NSInteger, SCURangeDateType)
{
    SCURangeDateType_Start,
    SCURangeDateType_End
};

@interface SCURangeDataSource : SCUDataSourceModel

@property (nonatomic) NSDate *startDate, *endDate, *minDate;
@property (nonatomic) BOOL endOnly;

@property (nonatomic) NSIndexPath *pickerIndexPath;
@property (nonatomic) NSString *datePickerFormat;
@property (nonatomic) NSString *dateFormat;

@end
