//
//  SCUBezelView.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/31/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAlertView.h"
#import "SCUAlertViewPrivate.h"
#import "SCUButton.h"
@import Extensions;

@interface SCUAlertView ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *contentButtonSeparatorView;
@property (nonatomic) NSArray *buttons;
@property (nonatomic) UIView *buttonView;
@property (weak) UIView *containingView;

@end

@implementation SCUAlertView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithTitle:(NSString *)title contentView:(UIView *)contentView buttonTitles:(NSArray *)buttonTitles
{
    self = [super initWithFrame:CGRectZero];

    if (self)
    {
        self.containingView = [UIView sav_topView];
        self.presentationStyle = SCUAlertAnimationDefault;
        self.tapToDismiss = YES;
        //-------------------------------------------------------------------
        // Set general properties.
        //-------------------------------------------------------------------
        UIColor *backgroundColor = [[self class] defaultBackgroundColor];
        self.backgroundColor = backgroundColor;
        self.layer.cornerRadius = [[self class] cornerRadius];
        self.clipsToBounds = YES;

        //-------------------------------------------------------------------
        // Setup title label.
        //-------------------------------------------------------------------
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [[SCUColors shared] color03];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.text = title;
        [self addSubview:self.titleLabel];

        //-------------------------------------------------------------------
        // Setup content view.
        //-------------------------------------------------------------------
        self.contentView = contentView ? contentView : [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.contentView];

        //-------------------------------------------------------------------
        // Setup the content/button separator view.
        //-------------------------------------------------------------------
        self.contentButtonSeparatorView = [UIView sav_viewWithColor:[[self class] defaultButtonSeparatorColor]];
        [self addSubview:self.contentButtonSeparatorView];

        //-------------------------------------------------------------------
        // Setup button view.
        //-------------------------------------------------------------------
        if ([buttonTitles count])
        {
            NSArray *buttons = [buttonTitles arrayByMappingBlock:^id(NSString *buttonTitle) {
                SCUButton *button = [[SCUButton alloc] initWithTitle:buttonTitle];
                button.color = [[SCUColors shared] color01];
                button.selectedColor = [[[SCUColors shared] color01] colorWithAlphaComponent:.6];
                button.backgroundColor = backgroundColor;
                button.selectedBackgroundColor = [backgroundColor colorWithAlphaComponent:.2];
                [button addTarget:self action:@selector(didPressButton:) forControlEvents:UIControlEventTouchUpInside];
                button.titleLabel.adjustsFontSizeToFitWidth = YES;
                button.titleLabel.minimumScaleFactor = .7;
                return button;
            }];

            self.buttons = buttons;

            SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
            configuration.interSpace = 0;
            configuration.distributeEvenly = YES;
            configuration.separatorSize = [UIScreen screenPixel];
            configuration.separatorBlock = ^UIView *{
                return [UIView sav_viewWithColor:[[self class] defaultButtonSeparatorColor]];
            };

            self.buttonView = [UIView sav_viewWithEvenlyDistributedViews:buttons withConfiguration:configuration];
        }
        else
        {
            self.buttonView = [[UIView alloc] initWithFrame:CGRectZero];
        }

        [self addSubview:self.buttonView];

        {
            //-------------------------------------------------------------------
            // Setup autolayout. "Hide" anything that doesn't exist (keep it at
            // size zero).
            //-------------------------------------------------------------------
            CGFloat titleHeight = title ? 35 : 0;
            CGFloat titlePadding = title ? 4 : 0;
            CGFloat separatorHeight = [buttonTitles count] ? [UIScreen screenPixel] : 0;
            CGFloat buttonHeight = [buttonTitles count] ? 35 : 0;
            CGFloat contentHeight = contentView ? 10 : 0;


            NSDictionary *metrics = @{@"titleHeight": @(titleHeight),
                                      @"titlePadding": @(titlePadding),
                                      @"separatorHeight": @(separatorHeight),
                                      @"contentHeight": @(contentHeight),
                                      @"buttonHeight": @(buttonHeight),
                                      @"buttonWidth": @([self buttonWidth]),
                                      @"contentPadding": @([self contentPadding]),
                                      @"bottomContentPadding": @([[self.contentView subviews] count] ? [self contentPadding] : 8)};

            NSDictionary *views = @{@"title": self.titleLabel,
                                    @"content": self.contentView,
                                    @"separator": self.contentButtonSeparatorView,
                                    @"buttons": self.buttonView};

            [self addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                        metrics:metrics
                                                                          views:views
                                                                        formats:@[@"|[title]|",
                                                                                  @"|-contentPadding-[content]-contentPadding-|",
                                                                                  @"|[separator]|",
                                                                                  @"|[buttons(==buttonWidth)]|",
                                                                                  @"V:|-titlePadding-[title(>=titleHeight)]-contentPadding-[content(>=contentHeight)]-bottomContentPadding-[separator(separatorHeight)][buttons(buttonHeight)]|"]]];
            
            //-------------------------------------------------------------------
            // Setup the masking view.
            //-------------------------------------------------------------------
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(maskingViewTapped:)];

            self.maskingView = [[UIView alloc] initWithFrame:CGRectZero];
            self.maskingView.translatesAutoresizingMaskIntoConstraints = NO;
            self.maskingView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.85];
            self.maskingView.opaque = NO;

            [self.maskingView addGestureRecognizer:tap];
        }
    }

    return self;
}

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message buttonTitles:(NSArray *)buttonTitles
{
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];

    self = [self initWithTitle:title contentView:messageLabel buttonTitles:buttonTitles];

    if (self)
    {
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.text = message;
        messageLabel.textColor = [[SCUColors shared] color03];
        messageLabel.font = [UIFont systemFontOfSize:14];
    }

    return self;
}

- (instancetype)initWithError:(NSError *)error
{
    return [self initWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription buttonTitles:@[NSLocalizedString(@"OK", nil)]];
}

- (instancetype)initInvalidPasswordAlert
{
    return [self initErrorAlertWithMessage:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your password must have at least:", nil)]
                                   bullets:@[@"Eight characters", @"One lower case letter",  @"One upper case letter",  @"One number"]
                             buttontTitles:@[NSLocalizedString(@"OK", nil)]];


}

- (instancetype)initErrorAlertWithMessage:(NSAttributedString *)message bullets:(NSArray *)bullets buttontTitles:(NSArray *)buttonTitles
{
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];

    UILabel *centerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    centerLabel.textAlignment = NSTextAlignmentCenter;
    centerLabel.attributedText = message;
    [contentView addSubview:centerLabel];

    NSMutableString *bulletText = [NSMutableString string];

    for (NSString *bullet in bullets)
    {
        [bulletText appendFormat:@"  • %@\n", bullet];
    }

    if ([bulletText length])
    {
        [bulletText deleteCharactersInRange:NSMakeRange(bulletText.length - 1, 1)];
    }

    UILabel *guidelines = [[UILabel alloc] initWithFrame:CGRectZero];
    guidelines.textAlignment = NSTextAlignmentNatural;
    guidelines.text = bulletText;
    guidelines.font = [UIFont systemFontOfSize:14];
    [contentView addSubview:guidelines];

    [contentView sav_pinView:centerLabel withOptions:SAVViewPinningOptionsToTop | SAVViewPinningOptionsHorizontally];
    [contentView sav_pinView:guidelines withOptions:SAVViewPinningOptionsToBottom ofView:centerLabel withSpace:SAVViewAutoLayoutStandardSpace];
    [contentView sav_pinView:guidelines withOptions:SAVViewPinningOptionsHorizontally | SAVViewPinningOptionsToBottom];

    for (UILabel *label in @[centerLabel, guidelines])
    {
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.textColor = [[SCUColors shared] color03];
    }

    return [self initWithTitle:nil
                   contentView:contentView
                  buttonTitles:buttonTitles];
}

- (void)show
{
    [self showWithAnimation:self.presentationStyle andCompletion:nil];
}

- (void)hide
{
    [self hideWithAnimation:self.presentationStyle andCompletion:nil];
}

- (void)setPrimaryButtons:(NSIndexSet *)primaryButtons
{
    _primaryButtons = primaryButtons;
    
    for (NSUInteger i = 0; i < [self.buttons count]; i++)
    {
        UIColor *color = nil;
        
        if ([primaryButtons containsIndex:i])
        {
            color = [[SCUColors shared] color01];
        }
        else
        {
            color = [[SCUColors shared] color03shade05];
        }
        
        SCUButton *button = self.buttons[i];
        button.color = color;
        button.selectedColor = [color colorWithAlphaComponent:.6];
    }
}

- (void)maskingViewTapped:(UITapGestureRecognizer *)gesture
{
    if (self.tapToDismiss)
    {
        [self hideWithAnimation:self.presentationStyle andCompletion:nil];
    }
}

- (void)hideWithCompletion:(dispatch_block_t)completionHandler
{
    [self hideWithAnimation:self.presentationStyle andCompletion:completionHandler];
}

- (void)animateInWithDefaultAnimation:(dispatch_block_t)completionHandler
{
    //-------------------------------------------------------------------
    // Set the initial properties on the alert view. We want it to start
    // a little larger and lighter and animate to the correct position.
    //-------------------------------------------------------------------
    self.transform = CGAffineTransformMakeScale(1.15, 1.15);
    self.alpha = 0.1;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1;
        self.maskingView.alpha = 1.0;
        self.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^ (BOOL finished) {
        if (completionHandler)
        {
            completionHandler();
        }
    }];
}

- (void)animateOutWithDefaultAnimation:(dispatch_block_t)completionHandler
{
    [UIView animateWithDuration:0.15 animations:^{
        self.transform = CGAffineTransformMakeScale(0.85, 0.85);
        self.alpha = 0.1;
        self.maskingView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.containingView sav_setUserInteractionEnabledForSubviews:YES];
        [self removeFromSuperview];
        [self.maskingView removeFromSuperview];
        [self removeFromSuperview];

        if (completionHandler)
        {
            completionHandler();
        }
    }];
}

- (void)animateWithSlideInFromDirection:(SCUAlertAnimationDirection)direction withCompletionHandler:(dispatch_block_t)completionHandler
{
    [self setNeedsLayout];
    [self layoutIfNeeded];

    CGRect finalFrame = self.frame;
    CGRect fromFrame = [self finalFrame:self.frame forAnimationDirection:direction];

    self.frame = fromFrame;

    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.3 options:0 animations:^{
        self.frame = finalFrame;

    } completion:^ (BOOL finished) {
        if (completionHandler)
        {
            completionHandler();
        }
    }];
}

- (void)animateWithSlideOutFromDirection:(SCUAlertAnimationDirection)direction withCompletionHandler:(dispatch_block_t)completionHandler
{
    CGRect firstFrame = [self intermediateFrame:self.frame forAnimationDirection:direction];
    CGRect finalFrame = [self finalFrame:self.frame forAnimationDirection:direction];

    [UIView animateWithDuration:0.1 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:15 options:UIViewAnimationOptionCurveEaseOut animations:^ {
        self.frame = firstFrame;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.frame = finalFrame;
        } completion:^(BOOL finished) {
            [self.containingView sav_setUserInteractionEnabledForSubviews:YES];
            [self removeFromSuperview];

            if (completionHandler)
            {
                completionHandler();
            }
        }];
    }];
}

- (CGRect)intermediateFrame:(CGRect)frame forAnimationDirection:(SCUAlertAnimationDirection)direction
{
    switch (direction)
    {
        case SCUAlertAnimationDirectionTop:
            frame.origin.y += 50;
            break;
        case SCUAlertAnimationDirectionBottom:
            frame.origin.y -= 50;
            break;
        case SCUAlertAnimationDirectionLeft:
            frame.origin.x += 50;
            break;
        case SCUAlertAnimationDirectionRight:
            frame.origin.x -= 50;
            break;
    }

    return frame;
}

- (CGRect)finalFrame:(CGRect)frame forAnimationDirection:(SCUAlertAnimationDirection)direction
{
    switch (direction)
    {
        case SCUAlertAnimationDirectionTop:
            frame.origin.y = -400;
            break;
        case SCUAlertAnimationDirectionBottom:
            frame.origin.y = [UIDevice isPad] ? 1024 : 480;
            break;
        case SCUAlertAnimationDirectionLeft:
            frame.origin.x = -400;
            break;
        case SCUAlertAnimationDirectionRight:
            frame.origin.x = [UIDevice isPad] ? 1024 : 480;
            break;
    }
    
    return frame;
}

- (void)showWithAnimation:(SCUAlertAnimation)animation andCompletion:(dispatch_block_t)completionHandler
{
    if (!self.containingView)
    {
        self.containingView = [UIApplication sharedApplication].keyWindow;
    }
    
    //-------------------------------------------------------------------
    // Add the masking view and its constraints.
    //-------------------------------------------------------------------
    [self.containingView addSubview:self.maskingView];
    [self.containingView addConstraints:[self maskingViewConstraints]];
//    [self.containingView sav_setUserInteractionEnabledForSubviews:NO];
    [self.containingView addSubview:self];
    [self positionInView:self.containingView];

    switch (animation)
    {
        case SCUAlertAnimationDefault:
            [self animateInWithDefaultAnimation:completionHandler];
            break;
        case SCUAlertAnimationSlideInTop:
            [self animateWithSlideInFromDirection:SCUAlertAnimationDirectionTop withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInLeft:
            [self animateWithSlideInFromDirection:SCUAlertAnimationDirectionLeft withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInRight:
            [self animateWithSlideInFromDirection:SCUAlertAnimationDirectionRight withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInBottom:
            [self animateWithSlideInFromDirection:SCUAlertAnimationDirectionBottom withCompletionHandler:completionHandler];
            break;
        default:
            break;
    }
}

- (void)hideWithAnimation:(SCUAlertAnimation)animation andCompletion:(dispatch_block_t)completionHandler
{
    switch (animation)
    {
        case SCUAlertAnimationDefault:
            [self animateOutWithDefaultAnimation:completionHandler];
            break;
        case SCUAlertAnimationSlideInTop:
            [self animateWithSlideOutFromDirection:SCUAlertAnimationDirectionBottom withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInBottom:
            [self animateWithSlideOutFromDirection:SCUAlertAnimationDirectionTop withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInLeft:
            [self animateWithSlideOutFromDirection:SCUAlertAnimationDirectionRight withCompletionHandler:completionHandler];
            break;
        case SCUAlertAnimationSlideInRight:
            [self animateWithSlideOutFromDirection:SCUAlertAnimationDirectionLeft withCompletionHandler:completionHandler];
            break;
        default:
            break;
    }
}

#pragma mark - Private

+ (UIColor *)defaultBackgroundColor
{
    return [[SCUColors shared] color04];
}

+ (UIColor *)defaultButtonSeparatorColor
{
    return [[SCUColors shared] color02];
}

+ (CGFloat)cornerRadius
{
    return 7;
}

- (void)setButtonViewHidden:(BOOL)hidden
{
    self.contentButtonSeparatorView.hidden = hidden;
    self.buttonView.hidden = hidden;
}

- (void)positionInView:(UIView *)containingView
{
    [self.containingView sav_addCenteredConstraintsForView:self];
}

- (CGFloat)buttonWidth
{
    return 300;
}

- (CGFloat)contentPadding
{
    if ([[self.contentView subviews] count] || ([self.contentView isKindOfClass:[UILabel class]] && ![self.titleLabel.text length]))
    {
        return 16;
    }
    else
    {
        return 0;
    }
}

#pragma mark -

- (void)didPressButton:(UIButton *)sender
{
    [self hide];

    if (self.callback)
    {
        NSUInteger index = 0;

        for (UIButton *button in self.buttons)
        {
            if (button == sender)
            {
                self.callback(index);
                break;
            }

            index++;
        }
    }
}

- (NSArray *)maskingViewConstraints
{
    return [NSLayoutConstraint sav_constraintsWithOptions:0 metrics:nil views:@{@"view": self.maskingView} formats:@[@"|[view]|", @"V:|[view]|"]];
}

@end
