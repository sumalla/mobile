//
//  SCUSecurityPanelModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityModel.h"

@class SAVSecurityEntity;
@protocol SCUSecurityPanelModelDelegate;

@interface SCUSecurityPanelModel : SCUSecurityModel

@property (weak) id <SCUSecurityPanelModelDelegate, SCUSecurityModelDelegate> delegate;

/**
 *  Select a partition from the list of available security partitions.
 *
 *  @param partition the desired partition
 */
- (void)selectSecurityPartition:(SAVSecurityEntity *)partition;

/**
 *  The currently selected security system partition.
 */
@property (readonly) SAVSecurityEntity *currentPartition;

@property (readonly) NSString *armingStatus;

@end

@protocol SCUSecurityPanelModelDelegate <SCUSecurityModelDelegate>

- (void)securityPartition:(SAVSecurityEntity *)partition userNumberDidChange:(NSUInteger)userNumber;
- (void)securityPartition:(SAVSecurityEntity *)partition statusDidChange:(NSString *)status;
- (void)securityPartition:(SAVSecurityEntity *)partition line1DidChange:(NSString *)line1;
- (void)securityPartition:(SAVSecurityEntity *)partition line2DidChange:(NSString *)line2;
- (void)securityPartition:(SAVSecurityEntity *)partition accessCodeDidChange:(NSString *)accessCode;
- (void)securityPartition:(SAVSecurityEntity *)partition armingStatusDidChange:(NSString *)armingStatus;
- (void)securityPartitionDidChange:(SAVSecurityEntity *)partition;

@end