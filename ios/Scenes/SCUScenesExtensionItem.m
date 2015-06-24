//
//  SCUScenesExtensionItem.m
//  SavantController
//
//  Created by Nathan Trapp on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesExtensionItem.h"
#import "SCUButtonContentView.h"

@import Extensions;

@interface SCUScenesExtensionItem ()

@property (nonatomic) UIImageView *contentImage;
@property (nonatomic) UILabel *contentLabel;
@property (nonatomic) UIView *animationView;

@end

@implementation SCUScenesExtensionItem

+ (instancetype)itemWithImage:(UIImage *)image width:(CGFloat)width andName:(NSString *)name
{
    SCUScenesExtensionItem *view = [[SCUScenesExtensionItem alloc] initWithStyle:SCUButtonStyleCustom contentView:[[UIView alloc] init]];

    view.backgroundColor = [UIColor clearColor];
    view.selectedBackgroundColor = [UIColor clearColor];
    view.disabledBackgroundColor = [UIColor clearColor];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.backgroundColor = [[SCUColors shared] color03];
    imageView.borderColor = [[SCUColors shared] color03shade04];
    imageView.borderWidth = [UIScreen screenPixel];
    view.contentImage = imageView;

    if (!image)
    {
        imageView.image = [UIImage imageNamed:@"No_Image-small"];
    }

    UILabel *label = [[UILabel alloc] init];
    label.text = name;
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = .9;
    view.contentLabel = label;

    [view.contentView addSubview:label];
    [view.contentView addSubview:imageView];

    [view.contentView sav_pinView:imageView withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToTop];
    [view.contentView sav_setHeight:15 forView:label isRelative:NO];
    [view.contentView sav_pinView:label withOptions:SAVViewPinningOptionsHorizontally];
    [view.contentView sav_pinView:label withOptions:SAVViewPinningOptionsToBottom ofView:imageView withSpace:4];
    [view.contentView sav_setSize:CGSizeMake(width, width) forView:imageView isRelative:NO];

    return view;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    if (highlighted && !self.animationView)
    {
        [self performSelectionAnimations];
    }
}

- (void)performSelectionAnimations
{
    self.userInteractionEnabled = NO;

    CGRect frame = self.contentImage.bounds;
    frame.size.width = frame.size.width / 4.0;
    frame.size.height = frame.size.height / 4.0;

    self.animationView = [[UIView alloc] initWithFrame:frame];
    self.animationView.center = self.contentImage.center;
    self.animationView.backgroundColor = [UIColor clearColor];
    self.animationView.clipsToBounds = YES;
    self.animationView.layer.cornerRadius = CGRectGetWidth(self.animationView.frame) / 2;

    [self.contentImage addSubview:self.animationView];

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:10 options:0  animations:^{
        self.animationView.backgroundColor = [[[SCUColors shared] color01] colorWithAlphaComponent:0.92];
        self.animationView.transform = CGAffineTransformMakeScale(6, 6);
    } completion:^ (BOOL finished) {
        [UIView animateWithDuration:.5 delay:0 options:0 animations:^{
            self.animationView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
            [self.animationView removeFromSuperview];
            self.animationView = nil;
        }];
    }];
}

@end
