//
//  SCUCameraCollectionViewCell.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraCollectionViewCell.h"
#import "SCUGradientView.h"

#import <SavantExtensions/SavantExtensions.h>
#import <SavantControl/SavantControl.h>

@interface SCUCameraCollectionViewCell ()

@property (weak) UIImageView *imageView;

@end

@implementation SCUCameraCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Light" size:19];
        self.textLabel.textColor = [[SCUColors shared] color04];

        UIImageView *cameraImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        cameraImage.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView = cameraImage;

        UIView *imageContainer = [[UIView alloc] init];
        [imageContainer addSubview:cameraImage];
        imageContainer.backgroundColor = [[SCUColors shared] color03shade03];

        [imageContainer sav_addFlushConstraintsForView:cameraImage withPadding:5];

        [self.contentView addSubview:imageContainer];


        if ([UIDevice isPhone])
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                    metrics:nil
                                                                                      views:@{@"label": self.textLabel,
                                                                                              @"image": imageContainer}
                                                                                    formats:@[@"|-(10)-[label]",
                                                                                              @"|-(10)-[image]-(10)-|",
                                                                                              @"V:|[label]-(5)-[image]|"]]];
        }
        else
        {
            [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                    metrics:nil
                                                                                      views:@{@"label": self.textLabel,
                                                                                              @"image": imageContainer}
                                                                                    formats:@[@"|-(15)-[label]",
                                                                                              @"|[image]|",
                                                                                              @"V:|[image]-(5)-[label]|"]]];
        }
    }
    return self;
}

- (void)configureWithInfo:(id)info
{
    SAVCameraEntity *entity = nil;
    if ([info isKindOfClass:[SAVCameraEntity class]])
    {
        entity = (SAVCameraEntity *)info;
    }

    self.textLabel.text = entity.label;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.imageView.image = nil;
}

@end
