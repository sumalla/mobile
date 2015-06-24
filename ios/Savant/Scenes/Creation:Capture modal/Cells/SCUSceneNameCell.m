//
//  SCUSceneNameCell.m
//  SavantController
//
//  Created by Nathan Trapp on 7/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSceneNameCell.h"
#import "SCUButton.h"

@interface SCUSceneNameCell ()

@property SCUButton *addPhotoButton;
@property UITextField *textField;

@end

@implementation SCUSceneNameCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.addPhotoButton = [[SCUButton alloc] initWithTitle:NSLocalizedString(@"Add\nPhoto", nil)];
        self.addPhotoButton.selectedBackgroundColor = [[SCUColors shared] color03shade02];
        self.addPhotoButton.borderColor = [[SCUColors shared] color03shade07];
        self.addPhotoButton.borderWidth = [UIScreen screenPixel];
        self.addPhotoButton.color = [[SCUColors shared] color03shade07];
        self.addPhotoButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:12];
        self.addPhotoButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.addPhotoButton.titleLabel.numberOfLines = 0;
        self.addPhotoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.addPhotoButton.tintImage = NO;

        [self.contentView addSubview:self.addPhotoButton];

        self.textField = [[UITextField alloc] init];
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Scene Name", nil) attributes:@{NSForegroundColorAttributeName: [[SCUColors shared] color03shade07]}];
        self.textField.textColor = [[SCUColors shared] color04];
        self.textField.font = [UIFont fontWithName:@"Gotham-Book" size:15];
        self.textField.returnKeyType = UIReturnKeyDone;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        [self.contentView addSubview:self.textField];

        [self.contentView sav_pinView:self.addPhotoButton withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToLeft withSpace:15];
        [self.contentView sav_setWidth:70 forView:self.addPhotoButton isRelative:NO];

        [self.contentView sav_pinView:self.textField withOptions:SAVViewPinningOptionsToRight ofView:self.addPhotoButton withSpace:15];
        [self.contentView sav_pinView:self.textField withOptions:SAVViewPinningOptionsVertically|SAVViewPinningOptionsToRight withSpace:15];
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    self.textField.text = info[SCUDefaultTableViewCellKeyTitle];
}

- (void)setImage:(UIImage *)image
{
    _image = image;

    self.addPhotoButton.image = image;

    if (image)
    {
        self.addPhotoButton.title = nil;
    }
    else
    {
        self.addPhotoButton.title = NSLocalizedString(@"Add\nPhoto", nil);
    }
}

@end
