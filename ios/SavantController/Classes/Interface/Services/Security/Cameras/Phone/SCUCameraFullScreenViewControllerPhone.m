//
//  SCUCameraFullScreenViewControllerPhone.m
//  SavantController
//
//  Created by Nathan Trapp on 5/20/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUCameraFullScreenViewControllerPhone.h"
#import "SCUCameraFullScreenViewControllerPrivate.h"
#import "SCUPeekabooStepper.h"
#import "SCUGradientView.h"
#import "SCUDPadStepper.h"

#import <SAVService.h>
#import <SavantExtensions/SavantExtensions.h>

@interface SCUCameraFullScreenViewControllerPhone () <SCUPeekabooStepperDelegate, SCUDPadStepperDelegate>

@property (nonatomic) SCUPeekabooStepper *brightnessControls;
@property (nonatomic) SCUPeekabooStepper *zoomControls;

@property (nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic) BOOL controlsVisible;

@property (nonatomic) NSTimer *timer;

@end

@implementation SCUCameraFullScreenViewControllerPhone

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.view addSubview:self.imageView];
	[self.view addSubview:self.zoneName];
	[self.view addSubview:self.cameraName];
	[self.view addSubview:self.dismissButton];
	
	self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];

	[self.imageView setUserInteractionEnabled:YES];
	[self.imageView addGestureRecognizer:self.tapGesture];
	
	self.cameraName.textAlignment = NSTextAlignmentCenter;
	self.zoneName.textAlignment = NSTextAlignmentCenter;
	
	self.cameraName.layer.shadowOpacity = 1.0;
	self.cameraName.layer.shadowRadius = 1.0;
	self.cameraName.layer.shadowColor = [UIColor blackColor].CGColor;
	self.cameraName.layer.shadowOffset = CGSizeMake(0.0, 0.0);
	self.cameraName.font = [UIFont fontWithName:@"Gotham" size:[SCUDimens dimens].regular.h7];
	
	self.panTiltControls = [[SCUDPadStepper alloc] initWithSize:CGSizeMake(60, 60) expandedSize:CGSizeMake(130, 130) padding:5];
	self.panTiltControls.backgroundColor = [[SCUColors shared] color03shade03];
	self.panTiltControls.layer.cornerRadius = 10.0f;
	self.panTiltControls.layer.masksToBounds = YES;
	self.panTiltControls.clipsToBounds = YES;
	self.panTiltControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
	((SCUDPadStepper *)self.panTiltControls).delegate = self;
	
	self.controlsVisible = YES;
	
	if (self.entity.hasPTZ)
	{
		BOOL hasBrightness = NO;
		if ([self.entity.service.commands containsObject:@"IrisOpen"])
		{
			hasBrightness = YES;
			self.brightnessControls = [[SCUPeekabooStepper alloc] initWithSize:CGSizeMake(60, 60) text:@"BRIGHTNESS" image:[UIImage imageNamed:@"security_brightness24"]];
			self.brightnessControls.delegate = self;
			self.brightnessControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
			
			[self.view addSubview:self.brightnessControls];
			
			[self.view sav_pinView:self.brightnessControls withOptions:SAVViewPinningOptionsToBottom | SAVViewPinningOptionsToLeft withSpace:15];
		}
		
		if ([self.entity.service.commands containsObject:@"ZoomOut"])
		{
			self.zoomControls = [[SCUPeekabooStepper alloc] initWithSize:CGSizeMake(60, 60) text:@"ZOOM" image:[UIImage imageNamed:@"security_camera_search24"]];
			self.zoomControls.delegate = self;
			self.zoomControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
			
			[self.view addSubview:self.zoomControls];
			
			if (hasBrightness)
			{
				[self.view sav_pinView:self.zoomControls withOptions:SAVViewPinningOptionsToTop ofView:self.brightnessControls withSpace:10];
				[self.view sav_pinView:self.zoomControls withOptions:SAVViewPinningOptionsToLeft withSpace:15];
			}
			else
			{
				[self.view sav_pinView:self.zoomControls withOptions:SAVViewPinningOptionsToBottom | SAVViewPinningOptionsToLeft withSpace:15];
			}
		}
		
		if ([self.entity.service.commands containsObject:@"TiltUp"])
		{
			[self.view addSubview:self.panTiltControls];
			
			[self.view sav_pinView:self.panTiltControls withOptions:SAVViewPinningOptionsToBottom | SAVViewPinningOptionsToRight withSpace:15];
		}
    }

    [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:NSLayoutFormatAlignAllCenterX
                                                                     metrics:@{@"labelPadding" : @75}
                                                                       views:@{@"dismiss": self.dismissButton,
                                                                               @"imageView": self.imageView,
                                                                               @"cameraName": self.cameraName}
                                                                     formats:@[@"|-15-[dismiss(45)]",
                                                                               @"|-(labelPadding)-[cameraName]-(labelPadding)-|",
                                                                               @"|[imageView]|",
																			   @"V:|-(20)-[dismiss(35)]",
                                                                               @"V:|-(20)-[cameraName]",
                                                                               @"imageView.top = super.top",
                                                                               @"imageView.height = super.height"]]];
}

- (void)closeAllSteppers
{
	if (self.zoomControls.isOpen || self.zoomControls.isAnimating)
	{
		[self.zoomControls close];
	}
	if (self.brightnessControls.isOpen || self.brightnessControls.isAnimating)
	{
		[self.brightnessControls close];
	}
	if (((SCUDPadStepper *)self.panTiltControls).isOpen)
	{
		[((SCUDPadStepper *)self.panTiltControls) close];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (BOOL)controlsOpen
{
	return (self.zoomControls.isOpen || self.brightnessControls.isOpen || ((SCUDPadStepper *)self.panTiltControls).isOpen);
}

- (void)imageViewTapped:(id)sender
{
	if (self.view.frame.size.width >= self.view.frame.size.height)
	{
		if (!self.controlsOpen)
		{
			[self fadeControlsToOn:!self.controlsVisible duration:0.7 delay:0.0];
		}
	}
	
	if (self.controlsOpen)
	{
		//Close controls
		[self closeAllSteppers];
	}
}

- (void)fadeControlsToOn:(BOOL)on duration:(float)duration delay:(float)delay
{
	[self fadeControlsToOn:on duration:duration delay:delay resetTimer:YES];
}

- (void)fadeControlsToOn:(BOOL)on duration:(float)duration delay:(float)delay resetTimer:(BOOL)resetTimer
{
	self.controlsVisible = on;
	
	self.brightnessControls.userInteractionEnabled = (on) ? 1 : 0;
	self.zoomControls.userInteractionEnabled = (on) ? 1 : 0;
	self.panTiltControls.userInteractionEnabled = (on) ? 1 : 0;

	[UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
		
		self.brightnessControls.alpha = (on) ? 1 : 0;
		self.zoomControls.alpha = (on) ? 1 : 0;
		self.panTiltControls.alpha = (on) ? 1 : 0;
		
	} completion:nil];
	
	if (resetTimer && on)
	{
		[self resetTimer];
	}
	
}

- (void)timerFired:(id)sender
{
	if (self.controlsOpen)
	{
		[self closeAllSteppers];
		[self fadeControlsToOn:NO duration:0.7 delay:0.2];
	}
	else
	{
		[self fadeControlsToOn:NO duration:0.7 delay:0.0];
	}
	[self.timer invalidate];
	self.timer = nil;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

	[[UIApplication sharedApplication] setStatusBarHidden:YES];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (size.width >= size.height)
        {
            self.view.backgroundColor = [SCUColors shared].color03shade03;
            self.panTiltControls.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.7];
            self.zoomControls.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.7];
            self.brightnessControls.backgroundColor = [[[SCUColors shared] color03] colorWithAlphaComponent:0.7];

            if (self.controlsOpen)
            {
                [self closeAllSteppers];
            }

            [self fadeControlsToOn:NO duration:0.7 delay:1.0];
        }
        else
        {
            [self.timer invalidate];
            self.timer = nil;
            self.view.backgroundColor = [SCUColors shared].color03;
            self.panTiltControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
            self.zoomControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
            self.brightnessControls.backgroundColor = [[[SCUColors shared] color03shade03] colorWithAlphaComponent:0.7];
            [self fadeControlsToOn:YES duration:0.4 delay:0 resetTimer:NO];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {

    }];
}

- (void)resetTimer
{
	if (self.view.frame.size.width >= self.view.frame.size.height)
	{
		[self.timer invalidate];
		self.timer = nil;
		self.timer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
	}
	else
	{
		[self.timer invalidate];
		self.timer = nil;
	}
}

- (void)willOpenStepper:(SCUPeekabooStepper *)stepper
{
	[self resetTimer];
	[self closeAllSteppers];
}

- (void)willOpenDPadStepper:(SCUDPadStepper *)stepper
{
	[self resetTimer];
	[self closeAllSteppers];
}

- (void)incrementTappedForStepper:(SCUPeekabooStepper *)stepper
{
	[self resetTimer];
	SAVServiceRequest *request = nil;
	
	if (stepper == self.zoomControls)
	{
		request = [self.entity requestForEvent:SAVEntityEvent_ZoomIn value:nil];
	}
	
	if (stepper == self.brightnessControls)
	{
		request = [self.entity requestForEvent:SAVEntityEvent_IrisOpen value:nil];
	}
	
	if (request)
	{
		[self.model sendServiceRequest:request];
	}
}

- (void)decrementTappedForStepper:(SCUPeekabooStepper *)stepper
{
	[self resetTimer];
	SAVServiceRequest *request = nil;
	
	if (stepper == self.zoomControls)
	{
		request = [self.entity requestForEvent:SAVEntityEvent_ZoomOut value:nil];
	}
	
	if (stepper == self.brightnessControls)
	{
		request = [self.entity requestForEvent:SAVEntityEvent_IrisClose value:nil];
	}
	
	if (request)
	{
		[self.model sendServiceRequest:request];
	}
}

- (void)stepper:(SCUDPadStepper *)stepper didPressDirection:(SCUDPadStepperDirection)direction
{
	[self resetTimer];
	SAVServiceRequest *request = nil;
	
	if (direction == SCUDPadStepperDirectionUp)
		request = [self.entity requestForEvent:SAVEntityEvent_TiltUp value:nil];
	if (direction == SCUDPadStepperDirectionDown)
		request = [self.entity requestForEvent:SAVEntityEvent_TiltDown value:nil];
	if (direction == SCUDPadStepperDirectionLeft)
		request = [self.entity requestForEvent:SAVEntityEvent_PanLeft value:nil];
	if (direction == SCUDPadStepperDirectionRight)
		request = [self.entity requestForEvent:SAVEntityEvent_PanRight value:nil];
	
	if (request)
		[self.model sendServiceRequest:request];
}

@end
