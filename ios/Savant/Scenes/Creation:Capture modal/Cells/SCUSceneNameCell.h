//
//  SCUSceneNameCell.h
//  SavantController
//
//  Created by Nathan Trapp on 7/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDefaultTableViewCell.h"

@class SCUButton;

@interface SCUSceneNameCell : SCUDefaultTableViewCell

@property (readonly) SCUButton *addPhotoButton;
@property (nonatomic) UIImage *image;
@property (readonly) UITextField *textField;

@end
