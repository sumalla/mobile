//
//  SCUSwipeCell.m
//  SavantController
//
//  Created by Cameron Pulsford on 4/15/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUSwipeCell.h"
#import "SCUSwipeCellPrivate.h"

@import Extensions;

NSString *const SCUSwipeCellAccessoryImageName = @"SCUSwipeCellAccessoryImageName";

@protocol SCUSwipeCellInternalProtocol <UITableViewDataSource, SCUSwipeCellDelegate>

@end

@interface SCUSwipeCell () <UIGestureRecognizerDelegate>

@property (nonatomic) UIView *rightButtonsView;
@property (nonatomic) UIView *buttonMaskView;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) CGRect initialFrame;
@property (nonatomic) CGFloat maximumWidth;
@property (nonatomic) CGFloat minimumX;
@property (nonatomic) CGFloat maximumX;
@property (nonatomic, getter = isOpen) BOOL open;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) UIImageView *swipeAccessoryView;
@property (nonatomic) UITableViewCellAccessoryType internalAccessoryType;
@property (nonatomic, assign) UITableViewCellStyle scuStyle;

@end

@implementation SCUSwipeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self)
    {
        self.scuStyle = style;
        self.swipeAccessoryView = [[UIImageView alloc] init];
        self.swipeAccessoryView.hidden = YES;
        self.swipeAccessoryView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.swipeAccessoryView];

        [self.contentView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                metrics:nil
                                                                                  views:@{@"view": self.swipeAccessoryView}
                                                                                formats:@[@"V:|[view]|",
                                                                                          @"view.right = super.right - 10"]]];
    }

    return self;
}

- (void)configureWithInfo:(NSDictionary *)info
{
    NSString *imageName = info[SCUSwipeCellAccessoryImageName];

    if (imageName)
    {
        self.swipeAccessoryView.hidden = NO;
        self.swipeAccessoryView.image = [UIImage sav_imageNamed:imageName tintColor:[[SCUColors shared] color01]];
    }
}

+ (UIView *)buttonViewWithTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor
{
    NSParameterAssert([title length]);

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = [NSString stringWithFormat:@"  %@  ", title];

    if (font)
    {
        label.font = font;
    }

    if (color)
    {
        label.textColor = color;
    }

    if (backgroundColor)
    {
        label.backgroundColor = backgroundColor;
    }

    return label;
}

+ (UIView *)buttonViewWithImageName:(NSString *)imageName color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor
{
    NSParameterAssert([imageName length]);

    UIView *view = nil;

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];

    UIImage *image = [UIImage imageNamed:imageName];

    if (color)
    {
        image = [image tintedImageWithColor:color];
    }

    imageView.image = image;

    if (backgroundColor)
    {
        view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = backgroundColor;
        [view addSubview:imageView];
        [view sav_addCenteredConstraintsForView:imageView];
    }
    else
    {
        view = imageView;
    }

    return view;
}

- (void)setRightButtons:(NSArray *)rightButtons
{
    _rightButtons = rightButtons;

    if (self.panGesture)
    {
        [self.contentView removeGestureRecognizer:self.panGesture];
        self.panGesture = nil;
    }

    [self removeTapGestureRecognizer];
    [self.rightButtonsView removeFromSuperview];
    self.rightButtonsView = nil;

    if ([rightButtons count])
    {
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.panGesture.delegate = self;

        // TODO: Add drawer interaction
        [self.contentView addGestureRecognizer:self.panGesture];

        SAVViewDistributionConfiguration *configuration = [[SAVViewDistributionConfiguration alloc] init];
        configuration.interSpace = 0;

        self.rightButtonsView = [UIView sav_viewWithEvenlyDistributedViews:rightButtons withConfiguration:configuration];

        self.maximumWidth = 200;

        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.backgroundView addSubview:self.rightButtonsView];
        [self.backgroundView addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                    metrics:@{@"maximumWidth": @(self.maximumWidth), @"minimumWidth": @50}
                                                                      views:@{@"view": self.rightButtonsView}
                                                                    formats:@[@"[view(>=minimumWidth,<=maximumWidth)]|",
                                                                              @"V:|[view]|"]]];

        self.buttonMaskView = [UIView sav_viewWithColor:self.backgroundColor];
        [self.contentView addSubview:self.buttonMaskView];
        [self.contentView sav_addFlushConstraintsForView:self.buttonMaskView];
        [self.contentView sendSubviewToBack:self.buttonMaskView];

        self.minimumX = -self.maximumWidth;
        self.maximumX = 0;
    }
}

- (void)openAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    if (!self.isOpen)
    {
        self.minimumX = -CGRectGetWidth(self.rightButtonsView.bounds);
        CGRect frame = self.contentView.frame;
        frame.origin.x = self.minimumX;
        [self setFrameAnimated:frame open:YES withVelocity:animated ? 300 : CGFLOAT_MAX completion:completion];
    }
}

- (void)closeAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    if (self.isOpen)
    {
        self.minimumX = -CGRectGetWidth(self.rightButtonsView.bounds);
        CGRect frame = self.contentView.frame;
        frame.origin.x = self.maximumX;
        [self setFrameAnimated:frame open:NO withVelocity:animated ? 300 : CGFLOAT_MAX completion:completion];
    }
}

#pragma mark - Subclass

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self closeAnimated:NO completion:NULL];
    self.rightButtons = nil;
    self.open = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if ([self leftContentOffset])
    {
        if (CGRectGetMinX(self.textLabel.frame) != [self leftContentOffset])
        {
            CGRect frame = self.textLabel.frame;
            frame.origin.x = [self leftContentOffset];
            self.textLabel.frame = frame;
        }
    }

    if ([self pinAccessoryViewToRight])
    {
        if (self.accessoryView)
        {
            CGFloat width = CGRectGetWidth(self.bounds);
            CGFloat accessoryMaxX = CGRectGetMaxX(self.accessoryView.frame);
            CGFloat delta = width - accessoryMaxX;

            if (delta > 0)
            {
                CGRect frame = self.accessoryView.frame;
                frame.origin.x += delta;
                self.accessoryView.frame = frame;
            }
        }
    }

    if (!self.swipeAccessoryView.hidden)
    {
        CGFloat cellWidth = CGRectGetWidth(self.contentView.frame);
        CGFloat spacer = 15;
        CGRect textLabelFrame = self.textLabel.frame;
        textLabelFrame.size.width = cellWidth - (spacer * 2);
        CGRect detailTextLabelFrame = self.detailTextLabel.frame;
        CGFloat accessoryViewWidth = CGRectGetWidth(self.swipeAccessoryView.frame);

        if (accessoryViewWidth)
        {
            switch (self.scuStyle)
            {
                case UITableViewCellStyleDefault:
                case UITableViewCellStyleValue1:
                case UITableViewCellStyleValue2:
                {
                    CGFloat detailTextLabelWidth = CGRectGetWidth(detailTextLabelFrame);
                    if (detailTextLabelWidth && self.detailTextLabel.text.length)
                    {
                        textLabelFrame.size.width -= detailTextLabelWidth + spacer;
                    }
                }
                    break;
                case UITableViewCellStyleSubtitle:
                    detailTextLabelFrame.size.width = cellWidth - (spacer * 2);
                    break;
            }

            textLabelFrame.size.width -= accessoryViewWidth + spacer;
            detailTextLabelFrame.size.width -= accessoryViewWidth + spacer;
        }

        self.detailTextLabel.frame = detailTextLabelFrame;
        self.textLabel.frame = textLabelFrame;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (!self.isOpen)
    {
        [super setSelected:selected animated:animated];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (!self.isOpen)
    {
        [super setHighlighted:highlighted animated:animated];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    UIView *superview = newSuperview.superview;

    if ([superview isKindOfClass:[UITableView class]])
    {
        self.tableView = (UITableView *)superview;
    }

    [super willMoveToSuperview:newSuperview];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    self.internalAccessoryType = accessoryType;

    NSString *imageName = nil;
    UIColor *tintColor = [[SCUColors shared] color03shade07];

    switch (accessoryType)
    {
        case UITableViewCellAccessoryNone:
            break;
        case UITableViewCellAccessoryDisclosureIndicator:
            imageName = @"TableDisclosureIndicator";
            break;
        case UITableViewCellAccessoryDetailDisclosureButton:
            [super setAccessoryType:accessoryType]; /* not supported yet */
            break;
        case UITableViewCellAccessoryCheckmark:
            imageName = @"TableCheckmark";
            break;
        case UITableViewCellAccessoryDetailButton:
            [super setAccessoryType:accessoryType]; /* not supported yet */
            break;
        case SCUTableViewCellAccessoryLock:
            imageName = @"Security";
            break;
        case SCUTableViewCellAccessoryChevronDown:
            imageName = @"chevron-down";
            break;
        case SCUTableViewCellAccessoryChevronUp:
            imageName = @"chevron-up";
            break;
    }

    UIImage *image = nil;

    if (imageName)
    {
        image = [UIImage sav_imageNamed:imageName tintColor:tintColor];
    }

    self.swipeAccessoryView.image = image;
    self.swipeAccessoryView.hidden = imageName ? NO : YES;

    [self.contentView bringSubviewToFront:self.swipeAccessoryView];
}

- (UITableViewCellAccessoryType)accessoryType
{
    return self.internalAccessoryType;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.buttonMaskView.backgroundColor = backgroundColor;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = YES;

    if (gestureRecognizer == self.panGesture)
    {
        //-------------------------------------------------------------------
        // If we are open, always allow swiping to start. Otherwise, assume
        // YES and check with the delegate.
        //-------------------------------------------------------------------
        if (!self.isOpen)
        {
            if ([self.tableView.dataSource respondsToSelector:@selector(tableView:shouldAllowSwipeForIndexPath:)])
            {
                shouldBegin = [(id <SCUSwipeCellInternalProtocol>)self.tableView.dataSource tableView:self.tableView
                                                                         shouldAllowSwipeForIndexPath:[self.tableView indexPathForCell:self]];
            }
        }

        for (UITableViewCell *c in [self.tableView visibleCells])
        {
            if ([c isKindOfClass:[SCUSwipeCell class]] && c != self)
            {
                SCUSwipeCell *cell = (SCUSwipeCell *)c;
                [cell closeAnimated:YES completion:NULL];
            }
        }
    }

    return shouldBegin;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark -

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
        {
            self.minimumX = -CGRectGetWidth(self.rightButtonsView.bounds);
            self.initialFrame = self.contentView.frame;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [recognizer translationInView:self.tableView];
            CGFloat newX = CGRectGetMinX(self.initialFrame) + translation.x;

            if (newX < self.minimumX)
            {
                newX = self.minimumX;
            }
            else if (newX > self.maximumX)
            {
                newX = self.maximumX;
            }

            CGRect frame = self.initialFrame;
            frame.origin.x = newX;
            self.contentView.frame = frame;
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            CGFloat velocity = [recognizer velocityInView:self.tableView].x;
            CGFloat absoluteVelocity = fabs(velocity);
            CGFloat currentX = CGRectGetMinX(self.contentView.frame);

            CGRect newFrame = self.initialFrame;

            BOOL open = NO;

            if (((currentX < (self.minimumX / 3)) || absoluteVelocity > 300) && velocity < 0)
            {
                open = YES;
                newFrame.origin.x = self.minimumX;
            }
            else
            {
                newFrame.origin.x = self.maximumX;
            }

            [self setFrameAnimated:newFrame open:open withVelocity:absoluteVelocity completion:NULL];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (void)setFrameAnimated:(CGRect)frame open:(BOOL)open withVelocity:(CGFloat)velocity completion:(dispatch_block_t)completion
{
    NSTimeInterval duration = fabs(CGRectGetMinX(self.contentView.frame) - CGRectGetMinX(frame)) / velocity;

    if (duration > 0.3)
    {
        duration = 0.3;
    }

    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.contentView.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         if (finished)
                         {
                             if (open)
                             {
                                 [self addTapGestureRecognizer];
                             }
                             else
                             {
                                 [self removeTapGestureRecognizer];
                             }

                             self.open = open;

                             if (completion)
                             {
                                 completion();
                             }
                         }
                     }];
}

- (void)addTapGestureRecognizer
{
    [self removeTapGestureRecognizer];

    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.tapGesture requireGestureRecognizerToFail:self.panGesture];
    [self addGestureRecognizer:self.tapGesture];
}

- (void)removeTapGestureRecognizer
{
    if (self.tapGesture)
    {
        [self removeGestureRecognizer:self.tapGesture];
    }

    self.tapGesture = nil;
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint pointInCell = [recognizer locationInView:self];
    CGRect cellPointRect = CGRectMake(pointInCell.x, pointInCell.y, 1, 1);

    if (CGRectIntersectsRect(self.rightButtonsView.frame, cellPointRect))
    {
        CGPoint pointInButtonView = [recognizer locationInView:self.rightButtonsView];
        CGRect buttonPointRect = CGRectMake(pointInButtonView.x, pointInButtonView.y, 1, 1);

        NSUInteger index = 0;

        for (UIView *view in self.rightButtons)
        {
            if (CGRectIntersectsRect(view.frame, buttonPointRect))
            {
                if ([self.tableView.dataSource respondsToSelector:@selector(tableView:buttonWasTappedAtIndex:inCellAtIndexPath:)])
                {
                    [(id <SCUSwipeCellInternalProtocol>)self.tableView.dataSource tableView:self.tableView
                                                                     buttonWasTappedAtIndex:index
                                                                          inCellAtIndexPath:[self.tableView indexPathForCell:self]];
                }

                break;
            }

            index++;
        }
    }
    else
    {
        [self closeAnimated:YES completion:NULL];
    }
}

- (BOOL)pinAccessoryViewToRight
{
    return NO;
}

- (CGFloat)leftContentOffset
{
    return self.tableView.contentInset.left;
}

@end
