//
//  SCUButtonCollectionViewCell.h
//  
//
//  Created by Jason Wolkovitz on 4/16/14.
//
//

#import "SCUDefaultCollectionViewCell.h"
#import "SCUButton.h"

extern NSString *const SCUCollectionViewCellFillCellKey;
extern NSString *const SCUCollectionViewCellImageNameKey;
extern NSString *const SCUCollectionViewCellPreferredOrderKey;
extern NSString *const SCUEmptyButtonViewCellCommand;

@interface SCUButtonCollectionViewCell : SCUDefaultCollectionViewCell

@property (nonatomic, strong) SCUButton *cellButton;

@end
