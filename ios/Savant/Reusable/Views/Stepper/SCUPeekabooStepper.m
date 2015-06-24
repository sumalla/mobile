//
//  SCUPeekabooStepper.m
//  SavantController
//
//  Created by Alicia Tams on 2/18/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUPeekabooStepper.h"
@import Extensions;

@interface SCUPeekabooStepper ()

@property (nonatomic) UIImageView *initialView;
@property (nonatomic) UIImageView *decrementView;
@property (nonatomic) UIImageView *incrementView;

@property (nonatomic, assign) CGSize size;

@property (nonatomic) NSLayoutConstraint *widthConstraint;

@end

@implementation SCUPeekabooStepper

- (instancetype)initWithSize:(CGSize)size text:(NSString *)text image:(UIImage *)image
{
	return [self initWithSize:size text:text image:image decrementImage:nil incrementImage:nil];
}

- (instancetype)initWithSize:(CGSize)size text:(NSString *)text image:(UIImage *)image decrementImage:(UIImage *)decrementImage incrementImage:(UIImage *)incrementImage
{
	self = [super init];
	if (self)
	{
		self.size = size;
		if (!decrementImage)
			decrementImage = [UIImage imageNamed:@"security_brightness_minus24"];
		
		if (!incrementImage)
			incrementImage = [UIImage imageNamed:@"security_brightness_plus24"];
		
		UIImageView *initialView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		[initialView setTintAdjustmentMode:UIViewTintAdjustmentModeAutomatic];
		[initialView setTintColor:[SCUColors shared].color04];
		[initialView setContentScaleFactor:3.5];
		[initialView setContentMode:UIViewContentModeCenter];
		self.initialView = initialView;
		
		UIImageView *decrementView = [[UIImageView alloc] initWithImage:[decrementImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		[decrementView setTintAdjustmentMode:UIViewTintAdjustmentModeAutomatic];
		[decrementView setTintColor:[SCUColors shared].color04];
		[decrementView setContentScaleFactor:3.0];
		[decrementView setContentMode:UIViewContentModeCenter];
		self.decrementView = decrementView;
		
		UIImageView *incrementView = [[UIImageView alloc] initWithImage:[incrementImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
		[incrementView setTintAdjustmentMode:UIViewTintAdjustmentModeAutomatic];
		[incrementView setTintColor:[SCUColors shared].color04];
		[incrementView setContentScaleFactor:3.0];
		[incrementView setContentMode:UIViewContentModeCenter];
		self.incrementView = incrementView;
		
		self.decrementView.userInteractionEnabled = YES;
		self.incrementView.userInteractionEnabled = YES;
		self.textLabel.userInteractionEnabled = YES;
		
		self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		self.textLabel.text = text;
		self.textLabel.font = [UIFont fontWithName:@"Gotham" size:[[SCUDimens dimens] regular].h9];
		self.textLabel.textColor = [[SCUColors shared] color04];

		self.textLabel.alpha = 0;
		self.incrementView.alpha = 0;
		self.decrementView.alpha = 0;
		
		[self addSubview:self.initialView];
		[self addSubview:self.incrementView];
		[self addSubview:self.textLabel];
		[self addSubview:self.decrementView];
		
		self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
		
		self.layer.cornerRadius = 7;
		self.layer.masksToBounds = YES;
		self.clipsToBounds = YES;
		
		
		/*
		 *	Constraints...
		 */
		NSDictionary *metrics = @{@"spacing":@15,
								  @"width":@(self.size.width),
								  @"height":@(self.size.height)};
		
		
		
		[NSLayoutConstraint activateConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
																		  metrics:metrics
																			views:@{@"init": self.initialView,
																					@"inc": self.incrementView,
																					@"dec": self.decrementView,
																					@"label": self.textLabel}
																		  formats:@[@"|[init(width)]",
																					@"H:|[dec(width)]-(spacing)-[label]-(spacing)-[inc(width)]|",
																					@"V:|[init]|",
																					@"V:|[dec]|",
																					@"V:|[label]|",
																					@"V:|[inc]|"]]];
		
		NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:size.height];
		self.widthConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:size.width];
		
		[NSLayoutConstraint activateConstraints:@[hConstraint, self.widthConstraint]];
	}
	return self;
}

- (CGSize)intrinsicContentSize
{
	return self.size;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touches.count == 1)
	{
		UITouch *touch = [touches anyObject];

		if ([touch.view isKindOfClass:[UIImageView class] ])
		{
			[self highlightButton:(UIImageView *)touch.view highlight:YES];
		}
	}
	else
	{
		for (UITouch *touch in touches)
		{
			if ([touch.view isKindOfClass:[UIImageView class]])
			{
				[self highlightButton:(UIImageView *)touch.view highlight:YES];
			}
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (touches.count == 1)
	{
		UITouch *touch = [touches anyObject];
		
		if ([touch.view isKindOfClass:[UIImageView class]])
		{
			[self highlightButton:(UIImageView *)touch.view highlight:NO];
		}
		
		if (touch.view == self)
		{
				if (!self.isOpen)
				{
					[self open];
				}
				else
				{
					[self close];
				}
		}
		
		if (self.textLabelClosesStepper && touch.view == self.textLabel)
		{
			[self close];
		}
		if (touch.view == self.incrementView)
		{
			[self.delegate incrementTappedForStepper:self];
		}
		if (touch.view == self.decrementView)
		{
			[self.delegate decrementTappedForStepper:self];
		}
	}
	else
	{
		for (UITouch *touch in touches)
		{
			if ([touch.view isKindOfClass:[UIImageView class]])
			{
				[self highlightButton:(UIImageView *)touch.view highlight:NO];
			}
		}
	}
}

- (void)highlightButton:(UIImageView *)sender highlight:(BOOL)highlight
{
	sender.tintColor = (highlight) ? [SCUColors shared].color01 : [SCUColors shared].color04;
}

- (void)open
{
		if ([self.delegate respondsToSelector:@selector(willOpenStepper:)])
			[self.delegate willOpenStepper:self];
		
		[NSLayoutConstraint deactivateConstraints:@[self.widthConstraint]];
		
		self.isAnimating = YES;
		[UIView animateWithDuration:0.3
							  delay:0.0
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 
							 [self.superview layoutIfNeeded];

							 [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
								 
								 self.textLabel.alpha = 1;
								 self.incrementView.alpha = 1;
								 self.decrementView.alpha = 1;
								 self.initialView.alpha = 0;
							 
							 } completion:^(BOOL finished) {
								 
								 if ([self.delegate respondsToSelector:@selector(didOpenStepper:)])
								 {
									 [self.delegate didOpenStepper:self];
								 }
								 
								 self.isOpen = YES;
								 self.isAnimating = NO;
								 
							 }];
							 
						 } completion:^(BOOL finished) {
							 
						 }];
}

- (void)close
{
		if ([self.delegate respondsToSelector:@selector(willCloseStepper:)])
			[self.delegate willCloseStepper:self];
		
		[NSLayoutConstraint activateConstraints:@[self.widthConstraint]];
		
		self.isAnimating = YES;
		[UIView animateWithDuration:0.3
							  delay:0.0
							options:UIViewAnimationOptionBeginFromCurrentState
						 animations:^{
							 
							 self.textLabel.alpha = 0;
							 self.incrementView.alpha = 0;
							 self.decrementView.alpha = 0;
							 
							 [UIView animateWithDuration:0.3 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
								 
								 self.initialView.alpha = 1;
								 [self.superview layoutIfNeeded];
								 
							 } completion:^(BOOL finished) {
								 
								 if ([self.delegate respondsToSelector:@selector(didCloseStepper:)])
								 {
									 [self.delegate didCloseStepper:self];
								 }
								 
								 self.isOpen = NO;
								 self.isAnimating = NO;
								 
							 }];
							 
						 } completion:^(BOOL finished) {
							 
						 }];
}

@end
