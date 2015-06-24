//
//  SCUButtonCollectionViewCell.m
//
//
//  Created by Jason Wolkovitz on 4/16/14.
//
//

#import "SCUButtonCollectionViewCell.h"

@import SDK;
@import Extensions;

NSString *const SCUCollectionViewCellFillCellKey = @"SCUCollectionViewCellFillCellKey";
NSString *const SCUCollectionViewCellImageNameKey = @"SCUCollectionViewCellImageNameKey";
NSString *const SCUCollectionViewCellPreferredOrderKey = @"SCUCollectionViewCellPreferredOrderKey";
NSString *const SCUEmptyButtonViewCellCommand = @"SCUEmpty";

@implementation SCUButtonCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.cellButton = [[SCUButton alloc] initWithStyle:SCUButtonStyleAVStandardGrouped];
        self.cellButton.clipsToBounds = YES;
        self.cellButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.cellButton.userInteractionEnabled = NO;
        self.cellButton.disabledColor = nil;
        self.cellButton.backgroundColor = [[SCUColors shared] color03shade03];
        
        self.cellButton.titleLabel.textColor = [[SCUColors shared] color04];
        self.cellButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.cellButton.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:17];
        self.cellButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.cellButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.cellButton.titleLabel.minimumScaleFactor = 0.4;
        self.cellButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.cellButton.titleLabel.numberOfLines = 0;

        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.cellButton];
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.cellButton.frame = self.bounds;
}

- (void)setNumberOfLinesForTitle
{
    if (self.cellButton)
    {
        if ([self.cellButton.title containsString:@"\n"])
        {
            [self.cellButton.titleLabel setNumberOfLines:0];
        }
        else
        {
            [self.cellButton.titleLabel setNumberOfLines:1];
        }        
        [self.cellButton setNeedsLayout];
        [self.cellButton layoutIfNeeded];
    }
}

- (void)configureWithInfo:(id)info
{
    NSString *imageName = info[SCUCollectionViewCellImageNameKey];

    if ([imageName length] > 0)
    {
        UIImage *buttonImage = [UIImage imageNamed:imageName];
        
        if (([imageName hasSuffix:@".jpg"] || [imageName hasSuffix:@".png"] || [imageName hasSuffix:@".gif"]) || ([info[SCUCollectionViewCellFillCellKey] boolValue]))
        {
            UIImageView *buttonImageView = [[UIImageView alloc] initWithImage:buttonImage];
            
            buttonImageView.contentMode = UIViewContentModeScaleAspectFill;
            buttonImageView.clipsToBounds = YES;

            [self.cellButton setContentView:buttonImageView];
        }
        else
        {
            [self.cellButton setImage:buttonImage];
        }
        
        if ([info[SCUDefaultCollectionViewCellKeyModelObject] containsString:@"Toggle"])
        {
            self.cellButton.selectedColor = self.cellButton.selectedBackgroundColor;
            self.cellButton.selectedBackgroundColor = nil;
        }
    }
    else
    {
        NSString *title = [info[SCUDefaultCollectionViewCellKeyTitle] uppercaseString];
        [self.cellButton setTitle:title];
        [self setNumberOfLinesForTitle];
    }

    if ([info[SCUDefaultCollectionViewCellKeyModelObject] isEqualToString:SCUEmptyButtonViewCellCommand])
    {
        self.alpha = 0;
        self.userInteractionEnabled = NO;
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    //-------------------------------------------------------------------
    // Don't show the hidden buttons when the collection view calls layoutSubviews
    //-------------------------------------------------------------------
    if ([self.cellButton.title isEqualToString:SCUEmptyButtonViewCellCommand])
    {
        [super setAlpha:0];
    }
    else
    {
        [super setAlpha:alpha];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.cellButton.title = nil;
    self.cellButton.image = nil;

    self.cellButton.contentView = nil;

    self.userInteractionEnabled = YES;
    self.alpha = 1;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.cellButton.selected = selected;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.cellButton.highlighted = highlighted;
}

@end
