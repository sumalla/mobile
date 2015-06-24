//
//  SCUShadeSliderTableViewCell.h
//  SavantController
//
//  Created by Cameron Pulsford on 2/6/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUSceneLightingSliderTableViewCell.h"
#import "SCUButton.h"

@interface SCUShadeSliderTableViewCell : SCUSceneLightingSliderTableViewCell

@property (nonatomic, readonly) SCUButton *closeButton;

@property (nonatomic, readonly) SCUButton *openButton;

@end
