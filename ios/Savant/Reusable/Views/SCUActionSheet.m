//
//  SCUActionSheet.m
//  SavantController
//
//  Created by Stephen Silber on 9/03/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUButton.h"
#import "SCUActionSheet.h"
#import "SCUGradientView.h"
@import Extensions;

#define kPadding 5

/**
 Arrow directions for SCUActionSheet
 */
typedef NS_ENUM(NSUInteger, SCUActionSheetArrowDirection) {
    SCUActionSheetArrowDirectionUp,
    SCUActionSheetArrowDirectionDown
};

@interface SCUActionSheetCell ()

@property (nonatomic) UIView *topLineView;
@property (nonatomic) UIView *bottomLineView;

@end

@implementation SCUActionSheetCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.topLineView = [[UIView alloc] initWithFrame:CGRectZero];
        self.topLineView.backgroundColor = [[[SCUColors shared] color03shade06] colorWithAlphaComponent:.4];
        self.topLineView.hidden = YES;
        [self.contentView addSubview:self.topLineView];
        [self.contentView sav_pinView:self.topLineView withOptions:SAVViewPinningOptionsToTop | SAVViewPinningOptionsCenterX];
        [self.contentView sav_setWidth:.8 forView:self.topLineView isRelative:YES];
        [self.contentView sav_setHeight:[UIScreen screenPixel] forView:self.topLineView isRelative:NO];

        self.bottomLineView = [[UIView alloc] initWithFrame:CGRectZero];
        self.bottomLineView.backgroundColor = [[[SCUColors shared] color03shade06] colorWithAlphaComponent:.4];
        self.bottomLineView.hidden = YES;
        [self.contentView addSubview:self.bottomLineView];
        [self.contentView sav_pinView:self.bottomLineView withOptions:SAVViewPinningOptionsToBottom | SAVViewPinningOptionsCenterX];
        [self.contentView sav_setWidth:.8 forView:self.bottomLineView isRelative:YES];
        [self.contentView sav_setHeight:[UIScreen screenPixel] forView:self.bottomLineView isRelative:NO];

        self.textLabel.textColor = [[SCUColors shared] color04];
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

- (void)setFrame:(CGRect)frame
{
    frame.origin.x += kPadding;
    frame.size.width -= 2 * kPadding;
    
    [super setFrame:frame];
}

@end

@interface SCUActionSheet () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL animatedIn;

@property (nonatomic) NSString *headerTitle;
@property (nonatomic) NSString *cancelButtonTitle;
@property (nonatomic) NSString *destructiveButtonTitle;
@property (nonatomic) NSArray  *buttonTitles;
@property (nonatomic) SCUButton *cancelButton;

@property (nonatomic) UITableViewController *tableViewController;
@property (nonatomic) UICollectionViewController *collectionViewController;

@property (nonatomic) NSArray *dataSource;
@property (weak) UIView *containingView;
@property (nonatomic) UIBezierPath *triangle;
@property (nonatomic) NSInteger cancelSection;
@property (nonatomic) NSInteger destructiveIndex;
@property (nonatomic) UIDynamicAnimator *animator;

@property (nonatomic) CGFloat anchorX;
@property (nonatomic) CGFloat maxWidth;
@property (nonatomic) UITapGestureRecognizer *maskTapGesture;

@property (nonatomic) UIView *tableContainer;

@end

@implementation SCUActionSheet

- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles
{
    return [self initWithTitle:nil buttonTitles:buttonTitles cancelTitle:nil destructiveTitle:nil];
}

- (instancetype)initWithButtonTitles:(NSArray *)buttonTitles cancelTitle:(NSString *)cancelTitle
{
    return [self initWithTitle:nil buttonTitles:buttonTitles cancelTitle:cancelTitle destructiveTitle:nil];
}

- (instancetype)initWithTitle:(NSString *)title buttonTitles:(NSArray *)buttonTitles
{
    return [self initWithTitle:title buttonTitles:buttonTitles cancelTitle:nil destructiveTitle:nil];
}

- (instancetype)initWithTitle:(NSString *)title buttonTitles:(NSArray *)buttonTitles cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
{
    self = [super init];
    if (self)
    {
        self.maximumTableHeightPercentage = 1;
        self.visible = NO;
        self.backgroundColor = [UIColor clearColor];
        self.buttonTitles = buttonTitles;
        self.headerTitle = title;
        self.cancelButtonTitle = cancelTitle ? cancelTitle : @"Cancel";
        self.destructiveButtonTitle = destructiveTitle;
        
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
        
        self.destructiveIndex = -1;
        self.cancelSection    = -1;
        
        UITapGestureRecognizer *maskViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelActionSheet)];
        maskViewTap.numberOfTapsRequired = 1;
        maskViewTap.delegate = self;
        self.maskTapGesture = maskViewTap;

        self.maskingView = [[UIView alloc] initWithFrame:CGRectZero];
        self.maskingView.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.65];
        
        SCUGradientView *gradientView = [[SCUGradientView alloc] initWithFrame:CGRectZero andColors:@[[[[SCUColors shared] color03] colorWithAlphaComponent:0.1], [[SCUColors shared] color03]]];
        gradientView.locations = @[@(0), @(0.8)];
        self.maskingView = gradientView;
        
        [self buildDataSource];
        [self setupFontsAndColors];

        [self buildTableView];
        
        [self.tableViewController.tableView registerClass:[SCUActionSheetCell class] forCellReuseIdentifier:@"cell"];
    }
    
    return self;
}

- (void)setMaskingView:(UIView *)maskingView
{
    if (_maskingView)
    {
        [_maskingView removeGestureRecognizer:self.maskTapGesture];
    }
    _maskingView = maskingView;
    _maskingView.alpha = 0;
    [_maskingView addGestureRecognizer:self.maskTapGesture];
}

- (void)buildTableView
{
    self.tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.tableViewController.tableView.dataSource = self;
    self.tableViewController.tableView.delegate = self;
    self.tableViewController.tableView.backgroundColor = [UIColor clearColor];
    self.tableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewController.tableView.separatorColor = [UIColor clearColor];
    self.tableViewController.tableView.sectionFooterHeight = 0;
    self.tableViewController.tableView.sectionHeaderHeight = 0;
    self.tableViewController.tableView.allowsMultipleSelection = NO;
    self.tableViewController.tableView.scrollEnabled = NO;
    self.tableViewController.tableView.rowHeight = 50.0f;

    self.tableContainer = [[UIView alloc] init];
    [self.tableContainer addSubview:self.tableViewController.tableView];
    [self.tableContainer sav_addFlushConstraintsForView:self.tableViewController.tableView];
}

- (void)setTableHeader
{
    if (self.headerTitle)
    {
        self.tableViewController.tableView.tableHeaderView = [self tableHeaderView];
    }
    else
    {
        self.tableViewController.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, .1)];
    }
}

/**
 *  Sets default fonts and colors for SCUActionSheet
 */
- (void)setupFontsAndColors
{
    // Font styling
    self.titleFont        = [UIFont fontWithName:@"Gotham-Book" size:14.0f];
    self.buttonFont       = [UIFont fontWithName:@"Gotham-Book" size:17.0f];
    self.cancelButtonFont = [UIFont boldSystemFontOfSize:14.0f];

    // Text styling
    self.cancelTextColor      = [[SCUColors shared] color03shade07];

    self.titleTextColor = [[SCUColors shared] color04];
    self.buttonTextColor = [[SCUColors shared] color04];
    self.buttonTextSelectedColor = [[SCUColors shared] color01];

    self.titleTextSelectedColor  = [[SCUColors shared] color04];
    self.buttonTextSelectedColor = [[SCUColors shared] color04];
    self.cancelTextSelectedColor = [[SCUColors shared] color04];
    
    // Button styling
    self.separatorColor                = [UIColor clearColor];
    self.buttonBackgroundColor         = [UIColor clearColor];
    self.buttonBackgroundSelectedColor = [UIColor clearColor];

    self.cancelBackgroundColor         = [UIColor clearColor];
    self.cancelBackgroundSelectedColor = [UIColor clearColor];
    
    self.destructiveBackgroundColor         = [UIColor clearColor];
    self.destructiveBackgroundSelectedColor = [UIColor clearColor];
}

/**
 * Separating this from init allows us to add new buttons and/or cance/delete after init
 */
- (void)buildDataSource
{
    NSMutableArray *dataSource = [NSMutableArray array];
    
    if (self.destructiveButtonTitle && self.buttonTitles)
    {
        NSMutableArray *buttons = [self.buttonTitles mutableCopy];

        self.destructiveIndex = buttons.count;
        [buttons addObject:self.destructiveButtonTitle];
        self.buttonTitles = [buttons copy];
    }
    else if (self.destructiveButtonTitle)
    {
        [dataSource addObject:@[self.destructiveButtonTitle]];
        self.destructiveIndex = 0;
    }
    
    if (self.buttonTitles.count)
    {
        [dataSource addObject:self.buttonTitles];
    }
 
    self.dataSource = [dataSource copy];
}

/**
 *  Animates view from bottom of the screen
 *
 *  @param view - view that SCUActionSheet gets added to
 */
- (void)showInView:(UIView *)view
{
    NSAssert(!self.visible, @"SCUActionSheet is already visible!");
    [self setTableHeader];

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    // This call will update any user-specified fonts or colors
    [self.tableViewController.tableView reloadData];
    [self scrollViewDidScroll:self.tableViewController.tableView];

    self.containingView    = [UIView sav_topView];
    self.maskingView.frame = self.containingView.frame;
    
    [self addSubview:self.tableContainer];
    [self.containingView addSubview:self.maskingView];
    [self.containingView sav_addFlushConstraintsForView:self.maskingView];
    
    self.frame = self.containingView.frame;
    
    // Table frame lets us add in a custom cancel button underneath the other buttons
    CGRect tableFrame = self.frame;
    tableFrame.size.height = self.tableViewController.tableView.contentSize.height;

    CGFloat tableBottomOffset = 40;

    if (CGRectGetHeight(tableFrame) > CGRectGetHeight(self.containingView.frame) * self.maximumTableHeightPercentage)
    {
        tableFrame.size.height = CGRectGetHeight(self.containingView.frame) * self.maximumTableHeightPercentage;
        tableFrame.size.height -= tableBottomOffset;
    }

    tableFrame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(tableFrame) - tableBottomOffset;

    self.tableContainer.frame = CGRectIntegral(tableFrame);

    if (CGRectGetHeight(tableFrame) < self.tableViewController.tableView.contentSize.height)
    {
        self.tableViewController.tableView.scrollEnabled = YES;
    }
    
    CGFloat startPosition = self.containingView.bounds.origin.y + self.containingView.bounds.size.height;

    // Adjust frame of ActionSheet to be below rect
    CGRect frame   = self.frame;
    frame.origin.y = startPosition;
    self.frame     = frame;
    
    [self.containingView addSubview:self];
    
    self.cancelButton = [self cancelButtonWithFrame:self.tableContainer.frame];
    [self addSubview:self.cancelButton];
    
    CGRect cancelFrame = self.cancelButton.frame;
    cancelFrame.origin.y = self.containingView.bounds.origin.y + self.containingView.bounds.size.height;
    self.cancelButton.frame = cancelFrame;
    
    CGRect cancelEndFrame = cancelFrame;
    cancelEndFrame.origin.y = CGRectGetHeight(self.containingView.frame) - CGRectGetHeight(self.cancelButton.frame) - kPadding;
    
    // We no longer are set as the delegate for tableView
    // Have to reset it to self. Assuming it's from adding
    // To the top view controller for some reason
    self.tableViewController.tableView.delegate = self;
    
    [UIView animateWithDuration:0.25 delay:0.3 usingSpringWithDamping:.75 initialSpringVelocity:20 options:0 animations:^{
        self.cancelButton.frame = cancelEndFrame;
    } completion:nil];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect endFrame = self.frame;
        self.maskingView.alpha = 1.0;
        endFrame.origin.y = 0;
        self.frame = endFrame;

    } completion:^ (BOOL finished) {

        self.visible = YES;
        self.animatedIn = YES;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

- (void)drawIndicatorFromRect:(CGRect)rect withDirection:(SCUActionSheetArrowDirection)direction
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineJoinStyle = kCGLineJoinRound;
    path.lineCapStyle  = kCGLineCapRound;
    
    self.anchorX = CGRectGetMidX(rect) - self.frame.origin.x;
    
    // Make sure the indicator isn't getting cut off on the edge of the screen
    if (self.anchorX < 20)
    {
        self.anchorX += 20;
    }

    switch (direction)
    {
        case SCUActionSheetArrowDirectionUp:
            [path moveToPoint:CGPointMake(self.anchorX, - 15)];
            [path addLineToPoint:CGPointMake(self.anchorX - 20, 2)];
            [path addLineToPoint:CGPointMake(self.anchorX + 20, 2)];
            break;
            
        case SCUActionSheetArrowDirectionDown:
        {
            CGFloat height = [self fullTableHeightWithCancelButton:NO];
            [path moveToPoint:CGPointMake(self.anchorX, height + 8)];
            [path addLineToPoint:CGPointMake(self.anchorX - 20, height - 12)];
            [path addLineToPoint:CGPointMake(self.anchorX + 20, height - 12)];
            break;
        }
    }
    
    [path closePath];
    
    CAShapeLayer *triangle = [[CAShapeLayer alloc] init];
    triangle.fillColor = self.buttonBackgroundColor.CGColor;
    [triangle setPath:path.CGPath];
    [[self layer] addSublayer:triangle];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view withMaxWidth:(CGFloat)maxWidth
{
    NSAssert(!self.visible, @"SCUActionSheet is already visible!");

    [self setTableHeader];
    
    if ([UIDevice isPad])
    {
        maxWidth = 320.0f;
    }
    
    self.maxWidth = (maxWidth == 0) ? CGRectGetWidth(view.frame) : maxWidth;
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    self.containingView = [UIView sav_topView];
    rect = [view convertRect:rect toView:self.containingView];

    // This call will update any user-specified fonts or colors
    [self.tableViewController.tableView reloadData];
    
    [self.containingView addSubview:self.maskingView];
    [self.containingView sav_addFlushConstraintsForView:self.maskingView];

    CGRect viewFrame = view.frame;
    
    // Support for shrinking actionSheet on pad
    if (maxWidth > 0)
    {
        viewFrame.origin.x = CGRectGetMinX(rect) - maxWidth / 2;
        viewFrame.size.width = maxWidth;
        if ((viewFrame.origin.x + maxWidth) > CGRectGetMaxX(self.containingView.frame))
        {
            viewFrame.origin.x = CGRectGetMaxX(self.containingView.frame) - maxWidth;
        }
        else if (viewFrame.origin.x < 0)
        {
            viewFrame.origin.x = 0;
        }
    }
    
    self.frame = viewFrame;
    
    // Table frame lets us add in a custom cancel button underneath the other buttons
    CGRect sizedFrame = self.frame;
    sizedFrame.size.height = self.tableViewController.tableView.contentSize.height;
    self.frame = sizedFrame;

    [self addSubview:self.tableContainer];
    [self sav_addFlushConstraintsForView:self.tableContainer];
    
    CGRect endFrame = self.frame;

    SCUActionSheetArrowDirection direction = [self getDirectionFromRect:rect inView:view];
    CGFloat angle = 0.5;
    
    if (direction == SCUActionSheetArrowDirectionUp)
    {
        endFrame.origin.y = CGRectGetMaxY(rect) + 15;
        [self setAnchorPoint:CGPointMake(0.5, 0) forView:self];
    }
    else
    {
        endFrame.origin.y = CGRectGetMinY(rect) - [self fullTableHeightWithCancelButton:NO] - 15;
        [self setAnchorPoint:CGPointMake(0.5, 0) forView:self];
        angle = -0.75;
    }
    
    self.frame = endFrame;
    
    // Draw triangle and add it to the action sheet
    [self drawIndicatorFromRect:rect withDirection:direction];

    // Start actionsheet at 90º
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 500.0;
    transform = CATransform3DRotate(transform, angle * -M_PI_2, 1, 0, 0);
    self.layer.transform = transform;
    
    // Helps with view clipping
    self.layer.zPosition = 999;
    view.layer.zPosition = 100;
    self.maskingView.layer.zPosition = 500;
    
    [self.containingView addSubview:self];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:1 options:0 animations:^{
        // Swing actionSheet from rect
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = -1 / 500.0;
        transform = CATransform3DRotate(transform, 0, 1, 0, 0);
        self.layer.transform = transform;
        
        // Fade in maskingView
        self.maskingView.alpha = 1.0;
    } completion:^ (BOOL finished) {
        self.visible = YES;
        self.animatedIn = NO;
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated
{
    [self showFromRect:rect inView:view withMaxWidth:0];
}

- (void)closeActionSheetByFallingFromAngle:(CGFloat)angle completionHandler:(dispatch_block_t)completion
{
    [self.animator removeAllBehaviors];

    UIGravityBehavior *gravityBehaviour = [[UIGravityBehavior alloc] initWithItems:@[self]];
    gravityBehaviour.gravityDirection = CGVectorMake(0, 5);
    [self.animator addBehavior:gravityBehaviour];
    
    UIDynamicItemBehavior *itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:@[self]];
    [itemBehaviour addAngularVelocity:angle forItem:self];
    [self.animator addBehavior:itemBehaviour];
    
    // Fade out the maskingView, then remove it
    [UIView animateWithDuration:0.3 animations:^{
        self.maskingView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        [self.maskingView removeFromSuperview];
        self.visible = NO;
        self.animator = nil;

        if (completion)
        {
            completion();
        }
    }];
}

/**
 *  Closes action sheet by animating offscreen
 *
 *  @param index button index that was selected (not cancel)
 */
- (void)closeActionSheetWithValue:(NSInteger)index
{
    CGFloat ratio = (self.anchorX / CGRectGetWidth(self.tableViewController.tableView.frame)) * 10;

    if (ratio > 6)
    {
        ratio = -ratio;
    }
    CGFloat angle = M_PI_2 / ratio;
    
    if (self.animatedIn || (ratio > 4 && ratio < 6))
    {
        angle = 0;
    }
    
    [self closeActionSheetByFallingFromAngle:angle completionHandler:^{
        if (self.callback)
        {
            self.callback(index);
        }

        if ([self.delegate respondsToSelector:@selector(actionSheet:clickedButtonAtIndex:)])
        {
            [self.delegate actionSheet:self clickedButtonAtIndex:index];
        }
    }];
}

/**
 *  Closes action sheet and sends a -1 value to the callback and/or delegate
 */
- (void)cancelActionSheet
{
    [self closeActionSheetWithValue:-1];
}

/**
 *  Takes into account the presence of a title/cancel button and calculates the full table height (only the height of content)
 *
 *  @return height of tableView cells + header
 */
- (CGFloat)fullTableHeightWithCancelButton:(BOOL)cancelButtonPresent
{
    NSInteger count = cancelButtonPresent ? 1 : 0;
    for (NSArray *buttons in self.dataSource)
    {
        count += buttons.count;
    }
    return (50 * count) + 10 + CGRectGetHeight(self.tableViewController.tableView.tableHeaderView.frame);
}

- (void)setDestructiveButtonText:(NSString *)destructiveButtonTitle
{
    self.destructiveButtonTitle = destructiveButtonTitle;
    [self buildDataSource];
    [self.tableViewController.tableView reloadData];
}

- (void)setCancelButtonText:(NSString *)cancelButtonTitle
{
    self.cancelButtonTitle = cancelButtonTitle;
    [self buildDataSource];
    [self.tableViewController.tableView reloadData];
}

- (void)setButtonTitlesFromArray:(NSArray *)buttonTitles
{
    self.buttonTitles = buttonTitles;
    [self buildDataSource];
    [self.tableViewController.tableView reloadData];
}

- (NSInteger)addButton:(NSString *)buttonTitle
{
    NSMutableArray *buttons = [self.buttonTitles mutableCopy];
    NSInteger index = buttons.count;
    [buttons addObject:buttonTitle];
    [self buildDataSource];
    [self.tableViewController.tableView reloadData];
    
    return index;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 0) ? 0 : kPadding;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource[section] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.cancelSection)
    {
        [self closeActionSheetWithValue:-1];
    }
    else if (indexPath.row == self.destructiveIndex)
    {
        [self closeActionSheetWithValue:-2];
    }
    else
    {
        [self closeActionSheetWithValue:indexPath.row];
    }
}

- (SCUButton *)cancelButtonWithFrame:(CGRect)frame
{
    frame.size.height = self.tableViewController.tableView.rowHeight;
    frame.origin.x = kPadding;
    frame.size.width -= kPadding * 2;

    SCUButton *cancel = [[SCUButton alloc] initWithFrame:frame];
    
    cancel.target = self;
    cancel.pressAction = @selector(cancelActionSheet);
    
    cancel.selectedBackgroundColor = self.cancelBackgroundSelectedColor;
    cancel.backgroundColor = self.cancelBackgroundColor;
    
    cancel.titleLabel.textAlignment = NSTextAlignmentCenter;
    cancel.titleLabel.font = self.cancelButtonFont;
    [cancel setTitle:self.cancelButtonTitle];
    
    [cancel setTitleColor:self.cancelTextColor forState:UIControlStateNormal];
    [cancel setTitleColor:self.cancelTextSelectedColor forState:UIControlStateHighlighted];
    
    cancel.cornerRadius = 2.5;
    cancel.clipsToBounds = YES;
    
    return cancel;
}

- (UITableViewCell *)cancelButtonCell
{
    SCUActionSheetCell *cell = [[SCUActionSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    
    cell.backgroundColor = self.cancelBackgroundColor;
    
    cell.textLabel.font = self.cancelButtonFont;
    cell.textLabel.text = self.cancelButtonTitle;
    cell.textLabel.textColor = self.cancelTextColor;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

- (UITableViewCell *)destructiveButtonCell
{
    SCUActionSheetCell *cell = [[SCUActionSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    
    cell.backgroundColor = self.buttonBackgroundColor;
    
    cell.textLabel.font = self.cancelButtonFont;
    cell.textLabel.text = self.destructiveButtonTitle;
    cell.textLabel.textColor = self.destructiveTextColor;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return cell;
}

- (UIView *)tableHeaderView
{
    CGFloat textHeight = [self.tableViewController.tableView sav_heightForText:self.headerTitle font:self.titleFont] - 10;
    CGRect headerFrame = CGRectMake(0, 0, CGRectGetWidth(self.tableViewController.tableView.frame), textHeight);
    
    UIView *container  = [[UIView alloc] initWithFrame:headerFrame];
    UIView *header     = [[UIView alloc] initWithFrame:CGRectInset(headerFrame, 5, 0)];
    UIView *lineView   = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(header.frame) - 1, CGRectGetWidth(header.frame), 1)];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text          = self.headerTitle;
    titleLabel.textColor     = self.titleTextColor;
    titleLabel.font          = self.titleFont;
    titleLabel.numberOfLines = 0;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    container.backgroundColor = [UIColor clearColor];
    header.backgroundColor    = self.buttonBackgroundColor;
    lineView.backgroundColor  = self.separatorColor;
    
    [header addSubview:lineView];
    [container addSubview:header];
    [header addSubview:titleLabel];
    
    [header sav_addFlushConstraintsForView:titleLabel withPadding:10];
    
    CALayer *headerLayer = header.layer;
    
    CGRect bounds = headerLayer.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                         cornerRadii:CGSizeMake(2.5, 2.5)];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    
    [headerLayer addSublayer:maskLayer];
    headerLayer.mask = maskLayer;
    
    return container;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.cancelSection)
    {
        return [self cancelButtonCell];
    }
    
    if (indexPath.row == self.destructiveIndex)
    {
        return [self destructiveButtonCell];
    }
    
    SCUActionSheetCell *cell = [[SCUActionSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cancel"];
    
    cell.backgroundColor = self.buttonBackgroundColor;
    
    cell.textLabel.font = self.buttonFont;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = self.buttonTextColor;
    cell.textLabel.text = self.buttonTitles[indexPath.row];

    if (self.showTableSeparatorLines)
    {
        NSUInteger row = (NSUInteger)indexPath.row;
        cell.bottomLineView.hidden = NO;

        if (row == 0)
        {
            cell.topLineView.hidden = NO;
        }
        else
        {
            cell.topLineView.hidden = YES;
        }
    }
    else
    {
        cell.topLineView.hidden = YES;
        cell.bottomLineView.hidden = YES;
    }
    
    return cell;
}

/**
 *  This is used to added rounded corners for top or bottom corners based on cell position
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isRoundedCell  = NO;
    BOOL needsSeparator = NO;
    
    CALayer *cellLayer = cell.layer;
    CGRect bounds = cellLayer.bounds;
    UIBezierPath *maskPath;
    if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 1 && !(self.headerTitle && indexPath.section == 0))
    {
        cell.layer.cornerRadius = 2.5;
        cell.layer.masksToBounds = YES;
        return;
    }
    else if (indexPath.row == 0 && !self.headerTitle)
    {
        isRoundedCell = YES;
        needsSeparator = YES;
        maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                         byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                               cornerRadii:CGSizeMake(2.5, 2.5)];
    }
    else if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
    {
        isRoundedCell = YES;
        maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                         byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight)
                                               cornerRadii:CGSizeMake(2.5, 2.5  )];
    }
    else
    {
        needsSeparator = YES;
    }
    
    if (isRoundedCell)
    {
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = bounds;
        maskLayer.path = maskPath.CGPath;
        
        [cellLayer addSublayer:maskLayer];
        cellLayer.mask = maskLayer;
    }
    
    if (needsSeparator)
    {
        UIView *lineView   = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(cell.frame) - [UIScreen screenPixel], CGRectGetWidth(self.tableViewController.tableView.frame), [UIScreen screenPixel])];
        lineView.backgroundColor  = self.separatorColor;
        [cell.contentView addSubview:lineView];
    }
}

#pragma mark - Custom UITableViewSelection color

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUActionSheetCell *cell = (SCUActionSheetCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == self.cancelSection)
    {
        [self setCellColor:self.cancelBackgroundSelectedColor ForCell:cell];
        cell.textLabel.textColor = self.cancelTextSelectedColor;
    }
    else if (indexPath.row == self.destructiveIndex)
    {
        [self setCellColor:self.destructiveBackgroundSelectedColor ForCell:cell];
        cell.textLabel.textColor = self.destructiveTextSelectedColor;
    }
    else
    {
        [self setCellColor:self.buttonBackgroundSelectedColor ForCell:cell];
        cell.textLabel.textColor = self.buttonTextSelectedColor;
    }
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCUActionSheetCell *cell = (SCUActionSheetCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == self.cancelSection)
    {
        [self setCellColor:self.cancelBackgroundColor ForCell:cell];
        cell.textLabel.textColor = self.cancelTextColor;
    }
    else if (indexPath.row == self.destructiveIndex)
    {
        [self setCellColor:self.destructiveBackgroundColor ForCell:cell];
        cell.textLabel.textColor = self.destructiveTextColor;
    }
    else
    {
        [self setCellColor:self.buttonBackgroundColor ForCell:cell];
        cell.textLabel.textColor = self.buttonTextColor;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    point = [self.tableViewController.tableView convertPoint:point fromView:self.maskingView];

    BOOL touchIsCell = NO;
    
    for (UITableViewCell *cell in self.tableViewController.tableView.visibleCells)
    {
        if (CGRectContainsPoint(cell.frame, point))
        {
            touchIsCell = YES;
        }
    }
    
    return touchIsCell;
}

#pragma mark - helper methods

- (void)setCellColor:(UIColor *)color ForCell:(UITableViewCell *)cell
{
    cell.contentView.backgroundColor = color;
    cell.backgroundColor = color;
}

- (SCUActionSheetArrowDirection)getDirectionFromRect:(CGRect)rect inView:(UIView *)view
{
    return [self isRect:rect inTopHalfOfView:view] ? SCUActionSheetArrowDirectionUp : SCUActionSheetArrowDirectionDown;
}

- (BOOL)isRect:(CGRect)rect inTopHalfOfView:(UIView *)view
{
    if (CGRectGetMaxY(rect) > CGRectGetMidY(view.frame))
    {
        return NO;
    }
    
    return YES;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect rect = self.tableViewController.tableView.tableHeaderView.frame;
    rect.origin.y = 0;
    self.tableViewController.tableView.tableHeaderView.frame = rect;

    // Fades out top and bottom cells in table view as they leave the screen
    NSArray *visibleCells = [self.tableViewController.tableView visibleCells];

    if ([visibleCells count])
    {
        UITableViewCell *topCell = [visibleCells firstObject];
        UITableViewCell *bottomCell = [visibleCells lastObject];

        /* Make sure other cells stay opaque */
        /* Avoids issues with skipped method calls during rapid scrolling */
        for (UITableViewCell *cell in visibleCells)
        {
            cell.contentView.alpha = 1.0;
        }

        /* Set necessary constants */
        NSInteger cellHeight = topCell.frame.size.height - 1;   // -1 To allow for typical separator line height
        NSInteger tableViewTopPosition = self.tableViewController.tableView.frame.origin.y;
        NSInteger tableViewBottomPosition = self.tableViewController.tableView.frame.origin.y + self.tableViewController.tableView.frame.size.height;

        /* Get content offset to set opacity */
        CGRect topCellPositionInTableView = [self.tableViewController.tableView rectForRowAtIndexPath:[self.tableViewController.tableView indexPathForCell:topCell]];
        CGRect bottomCellPositionInTableView = [self.tableViewController.tableView rectForRowAtIndexPath:[self.tableViewController.tableView indexPathForCell:bottomCell]];
        CGFloat topCellPosition = [self.tableViewController.tableView convertRect:topCellPositionInTableView toView:[self.tableViewController.tableView superview]].origin.y;
        CGFloat bottomCellPosition = ([self.tableViewController.tableView convertRect:bottomCellPositionInTableView toView:[self.tableViewController.tableView superview]].origin.y + cellHeight);

        /* Set opacity based on amount of cell that is outside of view */
        CGFloat modifier = 2.5;     /* Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
                                     2.0 for fully transparent when the cell is half off the screen, etc) */
        CGFloat topCellOpacity = (1.0f - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier);
        CGFloat bottomCellOpacity = (1.0f - ((bottomCellPosition - tableViewBottomPosition) / cellHeight) * modifier);

        /* Set cell opacity */
        if (topCell)
        {
            topCell.contentView.alpha = topCellOpacity;
        }

        if (bottomCell)
        {
            bottomCell.contentView.alpha = bottomCellOpacity;
        }
    }
}

@end
