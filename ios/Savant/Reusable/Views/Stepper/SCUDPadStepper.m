//
//  SCUDPadStepper.m
//  SavantController
//
//  Created by Alicia Tams on 2/24/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUDPadStepper.h"
#import "SCUButton.h"
@import Extensions;

@interface SCUDPadStepper ()

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGSize expandedSize;

@property (nonatomic) NSDictionary *viewsForContraints;
@property (nonatomic) UIView *container;
@property (nonatomic) NSArray *constraints;
@property (nonatomic) UIButton *overlay;

@property (nonatomic, assign) BOOL held;

@end

@implementation SCUDPadStepper

- (instancetype)initWithSize:(CGSize)size expandedSize:(CGSize)expandedSize padding:(CGFloat)padding
{
	self = [super init];
	if (self)
	{
		if (CGSizeEqualToSize(CGSizeZero, size))
			size = CGSizeMake(60, 60);
		if (CGSizeEqualToSize(CGSizeZero, expandedSize))
			expandedSize = CGSizeMake(size.width * 3, size.width * 3);
	
		size.width = size.width - padding * 2;
		size.height = size.height - padding * 2;
		expandedSize.width = expandedSize.width - padding * 2;
		expandedSize.height = expandedSize.height - padding * 2;
		
		self.size = size;
		self.expandedSize = expandedSize;
		
		self.container = [[UIView alloc] initWithFrame:CGRectZero];
		[self addSubview:self.container];
		
		self.overlay = [[UIButton alloc] initWithFrame:CGRectZero];
		self.overlay.backgroundColor = [UIColor clearColor];
		
		[self.overlay addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:self.overlay];
		
		[self sav_addFlushConstraintsForView:self.overlay];

		SCUButton *up = [[SCUButton alloc] initWithStyle:SCUButtonStyleCustom image:[UIImage sav_imageNamed:@"white_arrow_up" tintColor:[SCUColors shared].color04]];
		up.tag = SCUDPadStepperDirectionUp;
		
		SCUButton *down = [[SCUButton alloc] initWithStyle:SCUButtonStyleCustom image:[UIImage sav_imageNamed:@"white_arrow_down" tintColor:[SCUColors shared].color04]];
		down.tag = SCUDPadStepperDirectionDown;
		
		SCUButton *left = [[SCUButton alloc] initWithStyle:SCUButtonStyleCustom image:[UIImage sav_imageNamed:@"white_arrow_left" tintColor:[SCUColors shared].color04]];
		left.tag = SCUDPadStepperDirectionLeft;
		
		SCUButton *right = [[SCUButton alloc] initWithStyle:SCUButtonStyleCustom image:[UIImage sav_imageNamed:@"white_arrow_right" tintColor:[SCUColors shared].color04]];
		right.tag = SCUDPadStepperDirectionRight;
		
		UIView *topleft = [[UIView alloc] initWithFrame:CGRectZero];
		UIView *topright = [[UIView alloc] initWithFrame:CGRectZero];
		UIView *center = [[UIView alloc] initWithFrame:CGRectZero];
		UIView *bottomleft = [[UIView alloc] initWithFrame:CGRectZero];
		UIView *bottomright = [[UIView alloc] initWithFrame:CGRectZero];
		
		NSArray *buttons = @[up, down, left, right];
		NSArray *emptyviews = @[topleft, topright, bottomleft, bottomright, center];
		
		for (SCUButton *button in buttons)
		{
			button.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
			button.color = [SCUColors shared].color04;
			button.selectedColor = [SCUColors shared].color01;
			button.target = self;
			button.holdAction = @selector(holdButton:);
			button.holdDelay = 0.5;
			button.holdTime = 0.5;
			button.pressAction = @selector(pressedButton:);
			button.releaseAction = @selector(releasedButton:);
			[self.container addSubview:button];
		}
		
		for (UIView *view in emptyviews)
		{
			[self.container addSubview:view];
		}
		
		/*
		 * Constraints
		 */
		
		self.viewsForContraints = @{
									@"up": up,
									@"down": down,
									@"left": left,
									@"right": right,
									@"topleft": topleft,
									@"topright": topright,
									@"center": center,
									@"bottomleft": bottomleft,
									@"bottomright": bottomright
									};
		
		[self sav_addFlushConstraintsForView:self.container withPadding:padding];
		
		[self applyConstraintsWithSize:self.size];
		
	}
	return self;
}

- (void)close
{
	if ([self.delegate respondsToSelector:@selector(willCloseDPadStepper:)])
	{
		[self.delegate willCloseDPadStepper:self];
	}
	self.overlay.hidden = NO;
	[UIView animateWithDuration:0.3 animations:^{
		[self applyConstraintsWithSize:self.size];
		[self.superview layoutIfNeeded];
	} completion:^(BOOL finished) {
		
		self.isOpen = NO;
		
		if ([self.delegate respondsToSelector:@selector(didCloseDPadStepper:)])
		{
			[self.delegate didCloseDPadStepper:self];
		}
	}];
}

- (void)open
{
	if ([self.delegate respondsToSelector:@selector(willOpenDPadStepper:)])
	{
		[self.delegate willOpenDPadStepper:self];
	}
	self.isOpen = YES;
	self.overlay.hidden = YES;
	[UIView animateWithDuration:0.4 animations:^{
		[self applyConstraintsWithSize:self.expandedSize];
		[self.superview layoutIfNeeded];
	} completion:^(BOOL finished) {
		if ([self.delegate respondsToSelector:@selector(didOpenDPadStepper:)])
		{
			[self.delegate didOpenDPadStepper:self];
		}
	}];
}

- (void)holdButton:(id)sender
{
	[self pressedButton:sender];
}

- (void)releasedButton:(SCUButton *)sender
{
	
}

- (void)pressedButton:(SCUButton *)sender
{
	if ([self.delegate respondsToSelector:@selector(stepper:didPressDirection:)])
	{
		[self.delegate stepper:self didPressDirection:(SCUDPadStepperDirection)sender.tag];
	}
}

- (void)applyConstraintsWithSize:(CGSize)size
{
	NSDictionary *metrics = @{
							  @"xDivisor": @(size.width / 3),
							  @"yDivisor": @(size.height / 3)
							  };
	
	[NSLayoutConstraint deactivateConstraints:self.constraints];
	
	self.constraints = [NSLayoutConstraint sav_constraintsWithMetrics:metrics views:self.viewsForContraints formats:@[
																													  @"H:|[topleft(xDivisor)]-(0)-[up(xDivisor)]-0-[topright(xDivisor)]|",
																													  @"H:|[left(xDivisor)]-0-[center(xDivisor)]-0-[right(xDivisor)]|",
																													  @"H:|[bottomleft(xDivisor)]-0-[down(xDivisor)]-0-[bottomright(xDivisor)]|",
																													  @"V:|[topleft(yDivisor)]-0-[left(yDivisor)]-0-[bottomleft(yDivisor)]|",
																													  @"V:|[up(yDivisor)]-0-[center(yDivisor)]-0-[down(yDivisor)]|",
																													  @"V:|[topright(yDivisor)]-0-[right(yDivisor)]-0-[bottomright(yDivisor)]|"
																													  ]];
	
	[NSLayoutConstraint activateConstraints:self.constraints];
}

@end
