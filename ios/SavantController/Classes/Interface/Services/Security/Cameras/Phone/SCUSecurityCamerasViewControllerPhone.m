//
//  SCUSecurityCamerasViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/19/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSecurityCamerasViewControllerPhone.h"

@implementation SCUSecurityCamerasViewControllerPhone

- (UICollectionViewLayout *)preferredCollectionViewLayout
{
    SCUCollectionViewFlowLayout *layout = (SCUCollectionViewFlowLayout *)[super preferredCollectionViewLayout];

    //-------------------------------------------------------------------
    // This will need to change if we support iPhone rotation.
    //-------------------------------------------------------------------
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    layout.itemSize = CGSizeMake(width, width * .75);
    layout.headerReferenceSize = CGSizeMake(width, 70);
    layout.minimumLineSpacing = 25;

    return layout;
}

@end
