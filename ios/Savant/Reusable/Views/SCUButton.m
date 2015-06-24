//
//  SCUButtonBase.m
//  SavantController
//
//  Created by Cameron Pulsford on 11/10/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButton.h"
#import "SCUButtonPrivate.h"

@interface SCUButton ()

@property (nonatomic, getter = isTransactionInProgress) BOOL transactionInProgress;
@property (nonatomic) SCUButtonStyle style;
@property (nonatomic) UIColor *defaultDisabledColor;
@property (nonatomic) UIColor *defaultDisabledBackgroundColor;
@property (nonatomic) UIColor *defaultSelectedColor;
@property (nonatomic) UIColor *defaultSelectedBackgroundColor;
@property (nonatomic, weak) NSTimer *holdTimer;
@property (nonatomic, weak) NSTimer *holdDelayTimer;
@property (nonatomic) BOOL hasAppliedCurrentStyle;

@end

@implementation SCUButton

@synthesize selectedColor = _selectedColor;
@synthesize selectedBackgroundColor = _selectedBackgroundColor;

- (void)dealloc
{
    [self.holdTimer invalidate];
    [self.holdDelayTimer invalidate];
}

- (instancetype)initWithStyle:(SCUButtonStyle)style
{
    self = [[self class] buttonWithType:UIButtonTypeCustom];

    if (self)
    {
        _style = style;
        _holdDelay = .8;
        _tintImage = YES;
        _tintSelectedImage = YES;
        _titlePadding = CGSizeMake(15, 10);
        _contentViewPinning = SAVViewPinningOptionsVertically | SAVViewPinningOptionsHorizontally;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

        //-------------------------------------------------------------------
        // Don't use properties here to avoid initializing UIApperance values
        //-------------------------------------------------------------------
        SCUColors *colors = [SCUColors shared];

        switch (self.style)
        {
            case SCUButtonStyleLight:
            {
                _color = [colors color04];
                _selectedColor = [_color colorWithAlphaComponent:.6];
                _disabledColor = _selectedColor;
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = _backgroundColor;
                _disabledBackgroundColor = _backgroundColor;
                break;
            }
            case SCUButtonStyleLightAccent:
            {
                _color = [colors color04];
                _selectedColor = [colors color01];
                _disabledColor = [_color colorWithAlphaComponent:.6];
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = _backgroundColor;
                _disabledBackgroundColor = _backgroundColor;
                break;
            }
            case SCUButtonStyleAccent:
            {
                _color = [colors color01];
                _selectedColor = [_color colorWithAlphaComponent:.6];
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = _backgroundColor;
                _disabledBackgroundColor = _backgroundColor;
                break;
            }
            case SCUButtonStyleDark:
            {
                _color = [UIColor sav_colorWithRGBValue:0x333333];
                _selectedColor = [_color colorWithAlphaComponent:.6];
                _disabledColor = _selectedColor;
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = _backgroundColor;
                _disabledBackgroundColor = _backgroundColor;
                break;
            }
            case SCUButtonStyleAVStandardSolo:
            {
                self.borderWidth = [UIScreen screenPixel];
                self.borderColor = [colors color03shade04];
                // fallthrough
            }
            case SCUButtonStyleAVStandardGrouped:
            {
                _color = [colors color04];
                _selectedColor = [_color colorWithAlphaComponent:.6];
                _disabledColor = [colors color03];
                _backgroundColor = [colors color03];
                _selectedBackgroundColor = [colors color01];
                _disabledBackgroundColor = _backgroundColor;
                break;
            }
            case SCUButtonStyleStandardPill:
            {
                _color = [colors color04];
                _selectedColor = [colors color03]; // see if we can make this clear
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = [colors color04];
                self.borderWidth = [UIScreen screenPixel] * 2;
                self.borderColor = [colors color04];
                self.clipsToBounds = YES;
                self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:13];
                self.borderColor = [[SCUColors shared] color04];

                if ([UIDevice isShortPhone])
                {
                    self.cornerRadius = 16;
                }
                else
                {
                    self.cornerRadius = 20;
                }

                break;
            }
            case SCUButtonStyleStandardPillDark:
            {
                _color = [UIColor sav_colorWithRGBValue:0x333333];
                _selectedColor = [colors color04];
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = [UIColor sav_colorWithRGBValue:0x333333];
                self.borderWidth = [UIScreen screenPixel] * 2;
                self.borderColor = [UIColor sav_colorWithRGBValue:0x333333];
                self.clipsToBounds = YES;
                self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:13];
                
                if ([UIDevice isShortPhone])
                {
                    self.cornerRadius = 16;
                }
                else
                {
                    self.cornerRadius = 20;
                }
                
                break;
            }
            case SCUButtonStyleUnderlinedText:
            {
                _color = [colors color04];
                _selectedColor = [colors color03shade06]; // see if we can make this clear
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = [UIColor clearColor];
                
                self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:11];
                
                break;
            }
            case SCUButtonStyleUnderlinedTextDark:
            {
                _color = [colors color03];
                _selectedColor = [colors color03shade06];
                _backgroundColor = [UIColor clearColor];
                _selectedBackgroundColor = [UIColor clearColor];
                
                self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:11];
                
                break;
            }
            case SCUButtonStylePinnedButton:
            {
                _color = [colors color04];
                _selectedColor = [colors color03shade06]; // see if we can make this clear
				_backgroundColor = [[colors color04] colorWithAlphaComponent:0.2];
                _selectedBackgroundColor = [UIColor clearColor];
                
                self.titleLabel.font = [UIFont fontWithName:@"Gotham-Book" size:13];
                
                break;
            }
            case SCUButtonStylePinnedButtonDark:
            {
                
            }
            case SCUButtonStyleCustom:
            {
                break;
            }
        }
    }

    return self;
}

- (instancetype)init
{
    self = [self initWithStyle:SCUButtonStyleCustom];
    return self;
}

- (instancetype)initWithStyle:(SCUButtonStyle)style title:(NSString *)title
{
    self = [self initWithStyle:style];

    if (self)
    {
        self.title = title;
    }

    return self;
}

- (instancetype)initWithStyle:(SCUButtonStyle)style attributedTitle:(NSAttributedString *)attributedTitle
{
    self = [self initWithStyle:style];

    if (self)
    {
        self.attributedTitle = attributedTitle;
    }

    return self;
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [self initWithStyle:SCUButtonStyleCustom title:title];
    return self;
}

- (instancetype)initWithStyle:(SCUButtonStyle)style image:(UIImage *)image
{
    self = [self initWithStyle:style];

    if (self)
    {
        self.image = image;
    }

    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [self initWithStyle:SCUButtonStyleCustom image:image];
    return self;
}

- (instancetype)initWithStyle:(SCUButtonStyle)style contentView:(UIView *)contentView
{
    self = [self initWithStyle:style];

    if (self)
    {
        self.contentView = contentView;
    }

    return self;
}

- (instancetype)initWithContentView:(UIView *)contentView
{
    return [self initWithStyle:SCUButtonStyleCustom contentView:contentView];
}

- (void)updateStyleWithBlock:(dispatch_block_t)block
{
    NSParameterAssert(block);
    self.transactionInProgress = YES;
    block();
    self.transactionInProgress = NO;
    [self applyCurrentStyle];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.style == SCUButtonStyleUnderlinedText)
    {
        [self addBottomBorderWithColor:self.color andWidth:([UIScreen screenPixel] * 2)];
    }
    else if (self.style == SCUButtonStyleUnderlinedTextDark)
    {
        [self addBottomBorderWithColor:[[SCUColors shared] color03] andWidth:([UIScreen screenPixel] * 2)];
    }
    else if (self.style == SCUButtonStylePinnedButton)
    {
        [self addTopBorderWithColor:[[[SCUColors shared] color04] colorWithAlphaComponent:0.2] andWidth:[UIScreen screenPixel]];
    }
    else if (self.style == SCUButtonStylePinnedButtonDark)
    {
        [self addTopBorderWithColor:[[[SCUColors shared] color03shade06] colorWithAlphaComponent:0.2] andWidth:[UIScreen screenPixel]];
    }
}

#pragma mark - Behavior property overrides

- (void)setTarget:(id)target
{
    _target = target;
    [self setupBehavior];
}

- (void)setPressAction:(SEL)pressAction
{
    _pressAction = pressAction;
    [self setupBehavior];
}

- (void)setHoldAction:(SEL)holdAction
{
    _holdAction = holdAction;
    [self setupBehavior];
}

- (void)setReleaseAction:(SEL)releaseAction
{
    _releaseAction = releaseAction;
    [self setupBehavior];
}

- (void)setHoldTime:(NSTimeInterval)holdTime
{
    _holdTime = holdTime;
    [self setupBehavior];
}

- (void)setPressCallback:(void (^)(void))pressCallback
{
    _pressCallback = pressCallback;
    [self setupBehavior];
}

- (void)setReleaseCallback:(void (^)(void))releaseCallback
{
    _releaseCallback = releaseCallback;
    [self setupBehavior];
}

- (void)setupBehavior
{
    [self removeTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
    [self removeTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside];
    [self removeTarget:self action:@selector(releasedOutside:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];

    if (self.target)
    {
        if (self.releaseAction)
        {
            [self addTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside];
        }

        if (self.pressAction || self.holdTime)
        {
            [self addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
        }

        if (self.holdTime)
        {
            [self addTarget:self action:@selector(releasedOutside:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        }
    }
    else
    {
        if (self.releaseCallback)
        {
            [self addTarget:self action:@selector(released:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if (self.pressCallback || self.holdTime)
        {
            [self addTarget:self action:@selector(pressed:) forControlEvents:UIControlEventTouchDown];
        }
    }
}

- (void)pressed:(SCUButton *)button
{
    [self.holdTimer invalidate];
    [self.holdDelayTimer invalidate];

    [self handleTouchDownAction];

    if (self.holdTime)
    {
        SAVWeakSelf;
        self.holdDelayTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.holdDelay repeats:NO block:^{
            wSelf.holdDelayTimer = nil;

            wSelf.holdTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.holdTime repeats:YES block:^{
                [wSelf handleHold];
            }];
        }];
    }
}

- (void)released:(SCUButton *)button
{
    [self.holdDelayTimer invalidate];
    [self.holdTimer invalidate];
    [self handleRelease];
}

- (void)releasedOutside:(SCUButton *)button
{
    [self.holdTimer invalidate];
    [self.holdDelayTimer invalidate];
}

- (void)handleTouchDownAction
{
    if (self.pressAction)
    {
        SAVFunctionForSelector(function, self.target, self.pressAction, void, id);
        function(self.target, self.pressAction, self);
    }
    
    if (self.pressCallback)
    {
        self.pressCallback();
    }
}

- (void)handleHold
{
    if (self.holdAction)
    {
        SAVFunctionForSelector(function, self.target, self.holdAction, void, id);
        function(self.target, self.holdAction, self);
    }
    else if (self.releaseAction)
    {
        SAVFunctionForSelector(function, self.target, self.releaseAction, void, id);
        function(self.target, self.releaseAction, self);
    }
    
    if (self.holdCallback)
    {
        self.holdCallback();
    }
}

- (void)handleRelease
{
    if (self.releaseAction)
    {
        SAVFunctionForSelector(function, self.target, self.releaseAction, void, id);
        function(self.target, self.releaseAction, self);
    }
    
    if (self.releaseCallback)
    {
        self.releaseCallback();
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];

    if (self.contentView && self.selectedContentView)
    {
        self.selectedContentView.hidden = !selected;
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    if (self.attributedTitle)
    {
        if (highlighted)
        {
            [self setAttributedTitle:[self attributedStringWithColor:self.selectedColor fromAttirubtedString:self.attributedTitle] forState:UIControlStateNormal];
        }
        else
        {
            [self setAttributedTitle:[self attributedStringWithColor:self.color fromAttirubtedString:self.attributedTitle] forState:UIControlStateNormal];
        }
    }

    if (self.contentView && self.selectedContentView)
    {
        self.selectedContentView.hidden = !highlighted;
    }
}

#pragma mark - Style property overrides

- (void)setColor:(UIColor *)color
{
    if (![color isEqual:_color])
    {
        self.hasAppliedCurrentStyle = NO;
        _color = color;
        UIColor *dimColor = [color colorWithAlphaComponent:.6];
        self.defaultSelectedColor = dimColor;
        self.defaultDisabledColor = dimColor;
        [self attemptUpdate];
    }
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    if (![selectedColor isEqual:_selectedColor])
    {
        self.hasAppliedCurrentStyle = NO;
        _selectedColor = selectedColor;
        [self attemptUpdate];
    }
}

- (UIColor *)selectedColor
{
    return _selectedColor ? _selectedColor : self.defaultSelectedColor;
}

- (void)setDisabledColor:(UIColor *)disabledColor
{
    if (![disabledColor isEqual:_disabledColor])
    {
        self.hasAppliedCurrentStyle = NO;
        _disabledColor = disabledColor;
        [self attemptUpdate];
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    if (![backgroundColor isEqual:_backgroundColor])
    {
        self.hasAppliedCurrentStyle = NO;
        _backgroundColor = backgroundColor;
        UIColor *dimColor = [backgroundColor colorWithAlphaComponent:.6];
        self.defaultSelectedBackgroundColor = dimColor;
        self.defaultDisabledBackgroundColor = dimColor;
        [self attemptUpdate];
    }
}

- (void)setSelectedBackgroundColor:(UIColor *)selectedBackgroundColor
{
    if (![selectedBackgroundColor isEqual:_selectedBackgroundColor])
    {
        self.hasAppliedCurrentStyle = NO;
        _selectedBackgroundColor = selectedBackgroundColor;
        [self attemptUpdate];
    }
}

- (UIColor *)selectedBackgroundColor
{
    return _selectedBackgroundColor ? _selectedBackgroundColor : self.defaultSelectedBackgroundColor;
}

- (void)setDisabledBackgroundColor:(UIColor *)disabledBackgroundColor
{
    if (![disabledBackgroundColor isEqual:_disabledBackgroundColor])
    {
        self.hasAppliedCurrentStyle = NO;
        _disabledBackgroundColor = disabledBackgroundColor;
        [self attemptUpdate];
    }
}

- (void)setRoundedCorners:(BOOL)roundedCorners
{
    _roundedCorners = roundedCorners;

    if (roundedCorners)
    {
        self.layer.cornerRadius = 2;
        self.clipsToBounds = YES;
    }
    else
    {
        self.clipsToBounds = NO;
        self.layer.cornerRadius = 0;
    }
}

#pragma mark - Text overrides

- (void)setTitlePadding:(CGSize)titlePadding
{
    //-------------------------------------------------------------------
    // Don't need to invalidate style here.
    //-------------------------------------------------------------------
    _titlePadding = titlePadding;
    [self invalidateIntrinsicContentSize];
}

- (void)setTitle:(NSString *)title
{
    //-------------------------------------------------------------------
    // Don't need to invalidate style here.
    //-------------------------------------------------------------------
    _title = title;
    [self setTitle:title forState:UIControlStateNormal];

    if (self.image || self.selectedImage)
    {
        self.image = nil;
        self.selectedImage = nil;
    }

    [self invalidateIntrinsicContentSize];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = attributedTitle;
    [self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    self.hasAppliedCurrentStyle = NO;
    [self attemptUpdate];

    if (self.image || self.selectedImage)
    {
        self.image = nil;
        self.selectedImage = nil;
    }

    [self invalidateIntrinsicContentSize];
}

#pragma mark - Image overrides

- (void)setImage:(UIImage *)image
{
    if (!image)
    {
        [self setImage:nil forState:UIControlStateNormal];
        [self sav_setImage:nil forStates:[self selectedStates]];
    }

    _image = image;

    if (image)
    {
        self.hasAppliedCurrentStyle = NO;
        [self attemptUpdate];
    }
}

- (void)setSelectedImage:(UIImage *)selectedImage
{
    self.hasAppliedCurrentStyle = NO;
    _selectedImage = selectedImage;
    [self attemptUpdate];
}

- (UIImage *)scaledTintedImageFromImage:(UIImage *)image tint:(BOOL)tint color:(UIColor *)color
{
    UIImage *scaledTintedImage = image;

    if (tint)
    {
        scaledTintedImage = [image tintedImageWithColor:color];
    }

    if (self.scaleImageToFont)
    {
        scaledTintedImage = [UIImage imageWithImage:scaledTintedImage scaledToFont:self.titleLabel.font];
    }

    return scaledTintedImage;
}

- (void)setTintImage:(BOOL)tintImage
{
    if (tintImage != _tintImage)
    {
        self.hasAppliedCurrentStyle = NO;
        _tintImage = tintImage;
        [self attemptUpdate];
    }
}

- (void)setScaleImageToFont:(BOOL)scaleImageToFont
{
    if (scaleImageToFont != _scaleImageToFont)
    {
        self.hasAppliedCurrentStyle = NO;
        _scaleImageToFont = scaleImageToFont;
        [self attemptUpdate];
    }
}

#pragma mark - Content View overrides

- (void)setContentView:(UIView *)contentView
{
    if (contentView != _contentView)
    {
        if (_contentView)
        {
            [_contentView removeFromSuperview];
        }

        self.hasAppliedCurrentStyle = NO;
        _contentView = contentView;
        contentView.userInteractionEnabled = NO;
        [self attemptUpdate];
    }
}

- (void)setSelectedContentView:(UIView *)selectedContentView
{
    if (selectedContentView != _selectedContentView)
    {
        if (_selectedContentView)
        {
            [_selectedContentView removeFromSuperview];
        }

        self.hasAppliedCurrentStyle = NO;
        _selectedContentView = selectedContentView;
        selectedContentView.userInteractionEnabled = NO;
        [self attemptUpdate];
    }
}

- (void)setContentViewPinning:(SAVViewPinningOptions)contentViewPinning
{
    if (contentViewPinning != _contentViewPinning)
    {
        self.hasAppliedCurrentStyle = NO;
        _contentViewPinning = contentViewPinning;
        [self attemptUpdate];
    }
}

#pragma mark - General overrides

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    if (userInteractionEnabled != super.userInteractionEnabled)
    {
        self.hasAppliedCurrentStyle = NO;
        [super setUserInteractionEnabled:userInteractionEnabled];
        [self attemptUpdate];

        if (self.attributedTitle)
        {
            if (userInteractionEnabled)
            {
                [self setAttributedTitle:[self attributedStringWithColor:self.color fromAttirubtedString:self.attributedTitle] forState:UIControlStateNormal];
            }
            else
            {
                [self setAttributedTitle:[self attributedStringWithColor:self.disabledColor fromAttirubtedString:self.attributedTitle] forState:UIControlStateNormal];
            }
        }
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];

    if (self.title || self.attributedTitle)
    {
        size.height += self.titlePadding.height;
        size.width += self.titlePadding.width;
    }

    if (size.width < 44)
    {
        size.width = 44;
    }

    return size;
}

- (UIEdgeInsets)alignmentRectInsets
{
    return self.buttonInsets;
}

#pragma mark -

- (void)attemptUpdate
{
    if (!self.isTransactionInProgress)
    {
        [self applyCurrentStyle];
    }
}

#pragma mark - Private

- (NSArray *)selectedStates
{
    return @[@(UIControlStateHighlighted),
             @(UIControlStateSelected),
             @(UIControlStateHighlighted | UIControlStateSelected)];
}

- (void)addTopBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
    CALayer *border = [CALayer layer];
    border.backgroundColor = color.CGColor;
    
    border.frame = CGRectMake(0, 0, self.frame.size.width, borderWidth);
    [self.layer addSublayer:border];
}

- (void)addBottomBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
    CALayer *border = [CALayer layer];
    border.backgroundColor = color.CGColor;
    
    border.frame = CGRectMake(0, self.titleLabel.frame.size.height - borderWidth, self.titleLabel.frame.size.width, borderWidth);
    [self.titleLabel.layer addSublayer:border];
}

- (BOOL)applyCurrentStyle
{
    if (!self.hasAppliedCurrentStyle && self.window)
    {
        self.hasAppliedCurrentStyle = YES;

        if (self.backgroundColor)
        {
            [self setBackgroundImage:[UIImage resizableImageOfColor:self.backgroundColor initialSize:1] forState:UIControlStateNormal];
        }
        else
        {
            [self setBackgroundImage:nil forState:UIControlStateNormal];
        }

        if (self.selectedBackgroundColor)
        {
            [self sav_setBackgroundImage:[UIImage resizableImageOfColor:self.selectedBackgroundColor initialSize:1] forStates:[self selectedStates]];
        }
        else
        {
            [self sav_setBackgroundImage:nil forStates:[self selectedStates]];
        }

        if (self.disabledBackgroundColor)
        {
            [self setBackgroundImage:[UIImage resizableImageOfColor:self.disabledBackgroundColor initialSize:1] forState:UIControlStateDisabled];
        }
        else
        {
            [self setBackgroundImage:nil forState:UIControlStateDisabled];
        }

        [self setImage:[self scaledTintedImageFromImage:self.image tint:self.tintImage color:self.color] forState:UIControlStateNormal];

        if (self.selectedImage)
        {
            [self sav_setImage:[self scaledTintedImageFromImage:self.selectedImage tint:self.tintSelectedImage color:self.selectedColor] forStates:[self selectedStates]];
        }
        else
        {
            [self sav_setImage:[self scaledTintedImageFromImage:self.image tint:self.tintSelectedImage color:self.selectedColor] forStates:[self selectedStates]];
        }

        if (self.title || self.attributedTitle)
        {
            if (self.color)
            {
                [self setTitleColor:self.color forState:UIControlStateNormal];
            }

            if (self.selectedColor)
            {
                [self sav_setTitleColor:self.selectedColor forStates:[self selectedStates]];
            }

            if (self.disabledColor)
            {
                [self setTitleColor:self.disabledColor forState:UIControlStateDisabled];
            }

            if (self.attributedTitle)
            {
                [self setAttributedTitle:[self attributedStringWithColor:self.color fromAttirubtedString:self.attributedTitle] forState:UIControlStateNormal];
            }
        }

        if (self.contentView)
        {
            [self insertSubview:self.contentView atIndex:0];

            if (self.selectedContentView)
            {
                [self insertSubview:self.selectedContentView aboveSubview:self.contentView];
                self.selectedContentView.hidden = YES;
            }

            if (self.contentViewPinning != SAVViewPinningOptionsNone)
            {
                [self sav_pinView:self.contentView withOptions:self.contentViewPinning];

                if (self.selectedContentView)
                {
                    [self sav_pinView:self.selectedContentView withOptions:self.contentViewPinning];
                }
            }
        }

        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)didMoveToWindow
{
    [self applyCurrentStyle];
}

- (NSAttributedString *)attributedStringWithColor:(UIColor *)color fromAttirubtedString:(NSAttributedString *)string
{
    NSMutableAttributedString *newString = [string mutableCopy];
    [newString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [newString length])];
    return [newString copy];
}

@end
