//
//  SCUHVACPickerModel.h
//  SavantController
//
//  Created by Jason Wolkovitz on 10/26/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import Foundation;
#import <SavantControl/SavantControl.h>

typedef NS_ENUM(NSUInteger, SCUClimateServiceType)
{
    SCUClimateServiceTypeNone,
    SCUClimateServiceTypeTemperature,
    SCUClimateServiceTypeHumidity,
    SCUClimateServiceTypeHistory
};

@protocol SCUHVACPickerModelDelegate <NSObject>

- (void)internalSetNewCurrentEntity:(NSObject *)hvacEntity;

@end

@protocol SCUHVACPickerModelViewDelegate <NSObject>

- (void)setHvacLabelText;
- (void)hvacPickerChangedZone:(NSString *)zone;

@end

@protocol SCUHVACPickerModelViewSchedulingDelegate <NSObject>

- (void)hvacPickerChangedZone:(NSString *)zone;

@end

@interface SCUHVACPickerModel : NSObject

@property (nonatomic, weak) id<SCUHVACPickerModelDelegate> delegate;
@property (nonatomic, weak) id<SCUHVACPickerModelViewDelegate> viewDelegate;
@property (nonatomic, weak) id<SCUHVACPickerModelViewSchedulingDelegate> schedulingDelegate;

@property (nonatomic, readonly) NSArray *HVACEntities;
@property (nonatomic, readonly) NSInteger currentZoneIndex;

- (instancetype)initWithHVACArray:(NSArray *)hvacArray serviceType:(SCUClimateServiceType)serviceType;

- (NSInteger)startEntityForRoomID:(NSString *)roomID otherKeys:(NSArray *)otherKeys;
- (NSInteger)HVACEntityIndexForZoneName:(NSString *)zoneName;
//- (NSInteger)currentZoneIndex;
- (NSInteger)zoneIndexForEntity:(SAVHVACEntity *)entity;

- (NSArray *)HVACEntitiesZoneNames;
- (void)changeHVACForUpdateZoneName:(NSString *)zoneName;
- (void)setCurrentZoneIndexFromPicker:(NSInteger)newZoneIndex;

- (SAVHVACEntity *)currentHVACEntity;
- (NSString *)currentHVACZone;

- (NSObject *)findFirstHVACEntityWithPosibleZoneNames:(NSArray *)zoneNames;
- (NSString *)zoneNameForEntity:(NSObject *)entity;

- (NSString *)currentHVACEntityName;

- (void)unregisterForStates;

@end
