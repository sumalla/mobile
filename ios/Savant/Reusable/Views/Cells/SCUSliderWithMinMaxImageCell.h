//
//  SCUSceneVolumeCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/28/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"
#import "SCUSlider.h"

extern NSString *const SCUSliderMinMaxCellKeyValue;
extern NSString *const SCUSliderMinMaxCellKeyMinValue;
extern NSString *const SCUSliderMinMaxCellKeyMaxValue;
extern NSString *const SCUSliderMinMaxCellKeyDelta;
extern NSString *const SCUSliderMinMaxCellKeyMinImage;
extern NSString *const SCUSliderMinMaxCellKeyMaxImage;

@interface SCUSliderWithMinMaxImageCell : SCUDefaultTableViewCell

@property (readonly) SCUSlider *slider;
@property (nonatomic) UIImage *minImage, *maxImage UI_APPEARANCE_SELECTOR;
@property (weak, readonly) UIImageView *minImageView, *maxImageView;

@end
