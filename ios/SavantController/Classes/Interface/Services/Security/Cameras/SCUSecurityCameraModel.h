//
//  SCUSecurityCameraModel.h
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"
#import "SCUServiceViewModel.h"

#import <SAVCameraEntity.h>

@protocol SCUSecurityCameraModelDelegate;
@class SAVCameraEntity;

@interface SCUSecurityCameraModel : SCUServiceViewModel <SCUDataSourceModel>

@property (weak) id <SCUSecurityCameraModelDelegate> delegate;

- (NSIndexPath *)indexPathForEntity:(SAVCameraEntity *)entity;

@end

@protocol SCUSecurityCameraModelDelegate <NSObject>

- (void)receivedImage:(UIImage *)image ofScale:(SAVCameraEntityScale)scale forIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)visibleIndexes;

@end
