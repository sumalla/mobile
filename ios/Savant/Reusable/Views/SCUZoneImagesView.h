//
//  SCUZoneImagesView.h
//  SavantController
//
//  Created by Stephen Silber on 11/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@interface SCUZoneImagesView : UIView

- (void)setImagesFromArray:(NSArray *)images;
- (void)setSelected:(BOOL)selected;
- (void)next;

@property (nonatomic) UIButton *imageButton;

@end
