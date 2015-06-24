//
//  SCUScenesCollectionViewCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 7/22/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUScenesCollectionViewCell.h"
#import "SCUGradientView.h"
@import SDK;

NSString *const SCUScenesCellKeyIsInEditMode = @"SCUScenesCellKeyIsInEditMode";
NSString *const SCUScenesCellKeyIsWaitingForSceneToEdit = @"SCUScenesCellKeyIsWaitingForSceneToEdit";
NSString *const SCUScenesCellKeyIsMoving = @"SCUScenesCellKeyIsMoving";
NSString *const SCUScenesCellKeyScheduleCountdown = @"SCUScenesCellKeyScheduleCountdown";
NSString *const SCUScenesCellKeyScheduleType = @"SCUScenesCellKeyScheduleType";
NSString *const SCUScenesCellKeyScheduleActive = @"SCUScenesCellKeyScheduleActive";
NSString *const SCUScenesCellKeyIsActionCell = @"SCUScenesCellKeyIsActionCell";

@interface SCUScenesCollectionViewCell ()

@property (nonatomic) UIView *editMask;
@property (nonatomic) UIView *movingMask;
@property (nonatomic) UIView *normalMask;
@property (nonatomic) UIView *animationView;
@property (nonatomic) BOOL shouldAnimateSelection;
@property (nonatomic) SCUButton *deleteSceneButton;
@property (nonatomic) SCUButton *editSceneButton;
@property (nonatomic) SCUButton *scheduleSceneButton;
@property (nonatomic) UILabel *countdownLabel;
@property (nonatomic) UIActivityIndicatorView *editLoadingSpinner;
@property (nonatomic) UIView *editContainer;
@property (nonatomic) SAVKVORegistration *imageViewRegistration;
@property (nonatomic) SCUGradientView *gradientView;

@end

@implementation SCUScenesCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.editMask = [self createEditMask];
        self.movingMask = [self createMovingMask];
        self.normalMask = [self createNormalMask];
        self.clipsToBounds = YES;
        self.shouldAnimateSelection = YES;
        
        [self.textLabel removeFromSuperview];
        [self.contentView addSubview:self.textLabel];
        
        CGFloat fontSize = [UIDevice isPad] ? [[SCUDimens dimens] regular].h7 : [[SCUDimens dimens] regular].h9;
        CGFloat bottomMargin = [UIDevice isPad] ? 44 : 30;

        
        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsToBottom
                            withSpace:bottomMargin];
        [self.contentView sav_pinView:self.textLabel
                          withOptions:SAVViewPinningOptionsHorizontally
                            withSpace:SAVViewAutoLayoutStandardSpace];

        
        self.textLabel.font = [UIFont fontWithName:@"Gotham-Book" size:fontSize];
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    [super configureWithInfo:info];

    if ([info[SCUScenesCellKeyIsMoving] boolValue])
    {
        self.movingMask.hidden = NO;
        [self.contentView addSubview:self.movingMask];
        [self.contentView sav_addFlushConstraintsForView:self.movingMask];
        self.shouldAnimateSelection = NO;
        return;
    }
    else
    {
        self.shouldAnimateSelection = YES;
        self.movingMask.hidden = YES;
        [self.movingMask removeFromSuperview];
    }

    if ([info[SCUScenesCellKeyIsInEditMode] boolValue])
    {
        self.editMask.hidden = NO;
        [self.contentView addSubview:self.editMask];
        [self.contentView sav_addFlushConstraintsForView:self.editMask];
        self.movingMask.hidden = YES;
        self.shouldAnimateSelection = NO;
        [self.animationView removeFromSuperview];
    }
    else
    {
        self.editMask.hidden = YES;
        self.shouldAnimateSelection = YES;
        [self.editMask removeFromSuperview];
    }
    
    if ([info[SCUScenesCellKeyIsActionCell] boolValue])
    {
        self.shouldAnimateSelection = NO;
        [self.animationView removeFromSuperview];
    }

    if ([info[SCUScenesCellKeyIsWaitingForSceneToEdit] boolValue])
    {
        self.editSceneButton.hidden = YES;
        self.editLoadingSpinner.hidden = NO;
        [self.editLoadingSpinner startAnimating];
    }
    else
    {
        self.editSceneButton.hidden = NO;
        self.editLoadingSpinner.hidden = YES;
    }

    if (self.editMask.hidden && self.movingMask.hidden)
    {
        if (info[SCUScenesCellKeyScheduleType])
        {
            SAVSceneScheduleType type = [info[SCUScenesCellKeyScheduleType] integerValue];
            switch (type)
            {
                case SAVSceneScheduleType_Celestial:
                case SAVSceneScheduleType_Normal:
                    self.scheduleSceneButton.image = [UIImage sav_imageNamed:@"clock" tintColor:[[SCUColors shared] color04]];
                    self.scheduleSceneButton.selectedImage = [UIImage sav_imageNamed:@"clock-filled" tintColor:[[SCUColors shared] color01]];
                    break;
                case SAVSceneScheduleType_Countdown:
                    self.scheduleSceneButton.image = [UIImage sav_imageNamed:@"stopwatch" tintColor:[[SCUColors shared] color04]];
                    self.scheduleSceneButton.selectedImage = [UIImage sav_imageNamed:@"stopwatch-filled" tintColor:[[SCUColors shared] color01]];
                    break;
            }

            self.scheduleSceneButton.hidden = NO;
            self.scheduleSceneButton.selected = [info[SCUScenesCellKeyScheduleActive] boolValue];
        }

        if (info[SCUScenesCellKeyScheduleCountdown] && [info[SCUScenesCellKeyScheduleActive] boolValue])
        {
            self.countdownLabel.hidden = NO;
            self.countdownLabel.text = info[SCUScenesCellKeyScheduleCountdown];
        }
        else
        {
            self.countdownLabel.hidden = YES;
        }

        self.normalMask.hidden = NO;
        [self.contentView insertSubview:self.normalMask aboveSubview:self.backgroundImageView];
        [self.contentView sav_addFlushConstraintsForView:self.normalMask];

        self.backgroundImageView.alpha = 1;
    }
    else
    {
        self.backgroundImageView.alpha = .4;
        self.normalMask.hidden = YES;
        self.scheduleSceneButton.hidden = YES;
        self.countdownLabel.hidden = YES;
        [self.normalMask removeFromSuperview];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.normalMask.hidden = YES;
    self.scheduleSceneButton.hidden = YES;
    self.countdownLabel.hidden = YES;
    [self.normalMask removeFromSuperview];
    [self.animationView removeFromSuperview];
    [self.contentView sav_setUserInteractionEnabledForSubviews:YES];
}

#pragma mark -

- (void)setNoGradientView:(BOOL)noGradientView
{
    _noGradientView = noGradientView;

    if (noGradientView)
    {
        self.gradientView.hidden = YES;
    }
}

- (UIView *)createNormalMask
{
    UIView *containerView = [[UIView alloc] init];

    SCUGradientView *gradientView = [[SCUGradientView alloc] initWithFrame:CGRectZero
                                                                 andColors:@[[UIColor sav_colorWithRGBValue:0x000000 alpha:.7], [UIColor clearColor], [UIColor sav_colorWithRGBValue:0x000000 alpha:.7]]];
    gradientView.hidden = YES;
    [containerView addSubview:gradientView];
    [containerView sav_addFlushConstraintsForView:gradientView];
    self.gradientView = gradientView;

    self.scheduleSceneButton = [[SCUButton alloc] init];
    self.scheduleSceneButton.imageEdgeInsets = UIEdgeInsetsMake(23, 5, 5, 24);
    [containerView addSubview:self.scheduleSceneButton];
    [containerView sav_pinView:self.scheduleSceneButton withOptions:SAVViewPinningOptionsToTop];
    [containerView sav_pinView:self.scheduleSceneButton withOptions:SAVViewPinningOptionsToRight];
    [containerView sav_setSize:CGSizeMake(60, 60) forView:self.scheduleSceneButton isRelative:NO];

    self.scheduleSceneButton.backgroundColor = nil;
    self.scheduleSceneButton.selectedBackgroundColor = nil;
    self.scheduleSceneButton.color = [[SCUColors shared] color04];
    self.scheduleSceneButton.selectedColor = [[SCUColors shared] color01];
    self.scheduleSceneButton.hidden = YES;

    self.countdownLabel = [[UILabel alloc] init];
    self.countdownLabel.textColor = [[SCUColors shared] color04];
    self.countdownLabel.hidden = YES;
    [containerView addSubview:self.countdownLabel];
    [containerView sav_pinView:self.countdownLabel withOptions:SAVViewPinningOptionsToTop|SAVViewPinningOptionsToLeft withSpace:24];

    SAVWeakSelf;
    self.imageViewRegistration = [[SAVKVORegistration alloc] initWithObserver:self target:self.backgroundImageView selector:@selector(image) handler:^(NSDictionary *changeDictionary) {

        SAVStrongWeakSelf;

        if (sSelf.isDisplayingDefaultImage || !sSelf.backgroundImageView.image || sSelf.noGradientView)
        {
            gradientView.hidden = YES;
        }
        else
        {
            gradientView.hidden = NO;
        }
    }];

    return containerView;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (!self.shouldAnimateSelection)
    {
        [super setHighlighted:highlighted];
    }
    else
    {
        [super setHighlighted:NO];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected && self.shouldAnimateSelection)
    {
        [self performSelectionAnimations];
    }
}

- (void)performSelectionAnimations
{
    [self.contentView sav_setUserInteractionEnabledForSubviews:NO];
    
    CGFloat cellWidth = CGRectGetWidth(self.contentView.bounds);

    self.animationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cellWidth / 3, cellWidth / 3)];
    self.animationView.center = self.contentView.center;
    self.animationView.backgroundColor = [UIColor clearColor];
    self.animationView.clipsToBounds = YES;
    self.animationView.layer.cornerRadius = CGRectGetWidth(self.animationView.frame) / 2;

    [self.contentView insertSubview:self.animationView belowSubview:self.textLabel];
    
    [UIView animateWithDuration:.15 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:10 options:0  animations:^{
        self.animationView.backgroundColor = [[[SCUColors shared] color01] colorWithAlphaComponent:0.92];
        self.animationView.transform = CGAffineTransformMakeScale(5, 5);
    } completion:^ (BOOL finished) {
        [UIView animateWithDuration:.5 delay:0 options:0 animations:^{
            self.animationView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [self.contentView sav_setUserInteractionEnabledForSubviews:YES];
            [self.animationView removeFromSuperview];
        }];
    }];
}

- (UIView *)createEditMask
{
    SCUGradientView *gradientView = [[SCUGradientView alloc] initWithFrame:CGRectZero
                                                                 andColors:@[[UIColor clearColor], [[SCUColors shared] color03]]];

    gradientView.radial = YES;
    gradientView.hidden = YES;
    gradientView.startRadius = .1;
    gradientView.endRadius = 1;
    
    self.deleteSceneButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"trash"]];
    self.deleteSceneButton.imageEdgeInsets = UIEdgeInsetsMake(23, 24, 5, 5);
    [gradientView addSubview:self.deleteSceneButton];
    [gradientView sav_pinView:self.deleteSceneButton withOptions:SAVViewPinningOptionsToTop];
    [gradientView sav_pinView:self.deleteSceneButton withOptions:SAVViewPinningOptionsToLeft];
    [gradientView sav_setSize:CGSizeMake(60, 60) forView:self.deleteSceneButton isRelative:NO];

    self.editSceneButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"edit"]];
    self.editSceneButton.imageEdgeInsets = UIEdgeInsetsMake(28, 5, 5, 29);
    [gradientView addSubview:self.editSceneButton];
    [gradientView sav_pinView:self.editSceneButton withOptions:SAVViewPinningOptionsToTop];
    [gradientView sav_pinView:self.editSceneButton withOptions:SAVViewPinningOptionsToRight];
    [gradientView sav_setSize:CGSizeMake(60, 60) forView:self.editSceneButton isRelative:NO];

    self.editLoadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.editLoadingSpinner.hidden = YES;
    self.editLoadingSpinner.hidesWhenStopped = YES;
    [self.editContainer addSubview:self.editLoadingSpinner];
    [self.editContainer sav_addFlushConstraintsForView:self.editLoadingSpinner];

    for (SCUButton *button in @[self.editSceneButton, self.deleteSceneButton])
    {
        button.backgroundColor = [UIColor clearColor];
        button.selectedBackgroundColor = [UIColor clearColor];
        button.selectedColor = [[[SCUColors shared] color04] colorWithAlphaComponent:.6];
    }

    return gradientView;
}

- (UIView *)createMovingMask
{
    UIView *movingMask = [UIView sav_viewWithColor:[[SCUColors shared] color03shade01]];
    movingMask.borderColor = [[SCUColors shared] color03shade05];
    movingMask.borderWidth = [UIScreen screenPixel] * 2;
    return movingMask;
}

@end
