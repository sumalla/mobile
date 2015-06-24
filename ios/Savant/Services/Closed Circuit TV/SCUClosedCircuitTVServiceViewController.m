//
//  SCUClosedCircuitTVServiceViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 4/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUClosedCircuitTVServiceViewController.h"
#import "SCUClosedCircuitTVServiceViewModel.h"
#import "SCUPagedViewControl.h"
#import "SCUSwipeView.h"
#import "SCUButton.h"

@interface SCUClosedCircuitTVServiceViewController () <SCUSwipeViewDelegate, SCUPagedViewControlDelegate>

@property (nonatomic) SCUSwipeView *swipeView;
@property (nonatomic) SCUClosedCircuitTVServiceViewModel *pickerModel;
@property (nonatomic) SCUPagedViewControl *pickerView;
@property (nonatomic) UILabel *zoomLabel;
@property (nonatomic) UILabel *irisLabel;

@end

@implementation SCUClosedCircuitTVServiceViewController

- (instancetype)initWithService:(SAVService *)service
{
    self = [super initWithService:service];
    
    if (self)
    {
        self.pickerModel = [[SCUClosedCircuitTVServiceViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.contentView.backgroundColor = [[SCUColors shared] color03];
    
    self.swipeView = [[SCUSwipeView alloc] initWithFrame:CGRectZero configuration:SCUSwipeViewConfigurationVertical | SCUSwipeViewConfigurationHorizontal];
    self.swipeView.initialText = nil;
    self.swipeView.mainText = nil;
    self.swipeView.delegate = self;
    self.swipeView.allowsHolding = NO;
    [self.swipeView setArrowColor:[UIColor clearColor]];
    
    [self.contentView addSubview:self.swipeView];
    [self.contentView sav_addFlushConstraintsForView:self.swipeView];
    
    UIView *directionalContainer = [[UIView alloc] initWithFrame:CGRectZero];
    
    UIImageView *up     = [[UIImageView alloc] initWithImage:[[UIImage sav_imageNamed:@"white_arrow_up" tintColor:[[SCUColors shared] color03shade03]] scaleToSize:CGSizeMake(16, 16)] ];
    UIImageView *down   = [[UIImageView alloc] initWithImage:[[UIImage sav_imageNamed:@"white_arrow_down" tintColor:[[SCUColors shared] color03shade03]] scaleToSize:CGSizeMake(16, 16)] ];
    UIImageView *left   = [[UIImageView alloc] initWithImage:[[UIImage sav_imageNamed:@"white_arrow_left" tintColor:[[SCUColors shared] color03shade03]] scaleToSize:CGSizeMake(16, 16)] ];
    UIImageView *right  = [[UIImageView alloc] initWithImage:[[UIImage sav_imageNamed:@"white_arrow_right" tintColor:[[SCUColors shared] color03shade03]] scaleToSize:CGSizeMake(16, 16)] ];
    
    [directionalContainer addSubview:up];
    [directionalContainer addSubview:down];
    [directionalContainer addSubview:left];
    [directionalContainer addSubview:right];
    
    directionalContainer.userInteractionEnabled = NO;
    
    [directionalContainer sav_pinView:up withOptions:SAVViewPinningOptionsCenterX];
    [directionalContainer sav_pinView:down withOptions:SAVViewPinningOptionsCenterX];
    [directionalContainer sav_pinView:up withOptions:SAVViewPinningOptionsCenterY withSpace:-70];
    [directionalContainer sav_pinView:down withOptions:SAVViewPinningOptionsCenterY withSpace:70];
    
    [directionalContainer sav_pinView:left withOptions:SAVViewPinningOptionsCenterY];
    [directionalContainer sav_pinView:right withOptions:SAVViewPinningOptionsCenterY];
    [directionalContainer sav_pinView:left withOptions:SAVViewPinningOptionsCenterX withSpace:-70];
    [directionalContainer sav_pinView:right withOptions:SAVViewPinningOptionsCenterX withSpace:70];
    
    UIView *bottomContainer = [[UIView alloc] initWithFrame:CGRectZero];
    bottomContainer.backgroundColor = [[SCUColors shared] color03];
    
    SCUButton *minusButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"VolumeMinus"]];
    SCUButton *plusButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"VolumePlus"]];
    
    minusButton.pressAction = @selector(handleMinusPress);
    minusButton.releaseAction = @selector(handleMinusRelease);
    minusButton.target = self;
    
    plusButton.pressAction = @selector(handlePlusPress);
    plusButton.releaseAction = @selector(handlePlusRelease);
    plusButton.target = self;
    
    minusButton.color = [[SCUColors shared] color04];
    plusButton.color = [[SCUColors shared] color04];
    minusButton.selectedBackgroundColor = [[SCUColors shared] color01];
    plusButton.selectedBackgroundColor = [[SCUColors shared] color01];
    
    minusButton.borderColor = [[SCUColors shared] color03shade02];
    plusButton.borderColor = [[SCUColors shared] color03shade02];
    minusButton.borderWidth = [UIScreen screenPixel];
    plusButton.borderWidth = [UIScreen screenPixel];
    
    bottomContainer.borderColor = [[SCUColors shared] color03shade02];
    bottomContainer.borderWidth = [UIScreen screenPixel];
    

    
    SCUPagedViewControl *pickerView = [[SCUPagedViewControl alloc] initWithViews:[self pagedViews]];
    pickerView.delegate = self;
    
    [bottomContainer addSubview:minusButton];
    [bottomContainer addSubview:plusButton];
    [bottomContainer addSubview:pickerView];
    
    [bottomContainer sav_pinView:minusButton withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsVertically];
    [bottomContainer sav_pinView:plusButton withOptions:SAVViewPinningOptionsToRight|SAVViewPinningOptionsVertically];
    
    [bottomContainer sav_setWidth:0.4 forView:minusButton isRelative:YES];
    [bottomContainer sav_setWidth:0.4 forView:plusButton isRelative:YES];
    
    [bottomContainer sav_pinView:pickerView withOptions:SAVViewPinningOptionsVertically];
    [bottomContainer sav_pinView:pickerView withOptions:SAVViewPinningOptionsToLeft ofView:plusButton withSpace:0];
    [bottomContainer sav_pinView:pickerView withOptions:SAVViewPinningOptionsToRight ofView:minusButton withSpace:0];
    
    [self.contentView addSubview:bottomContainer];
    [self.contentView sav_pinView:bottomContainer withOptions:SAVViewPinningOptionsToLeft|SAVViewPinningOptionsToRight|SAVViewPinningOptionsToBottom withSpace:5.0];
    [self.contentView sav_setHeight:60 forView:bottomContainer isRelative:NO];
    
    [self.contentView addSubview:directionalContainer];
    [self.contentView sav_pinView:directionalContainer withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToTop];
    [self.contentView sav_pinView:directionalContainer withOptions:SAVViewPinningOptionsToTop ofView:bottomContainer withSpace:5.0];
    
    self.pickerView = pickerView;
}

- (NSArray *)pagedViews
{
    self.zoomLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.irisLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    for (UILabel *label in @[self.zoomLabel, self.irisLabel])
    {
        label.textColor = [[SCUColors shared] color04];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h12];
    }
    
    self.zoomLabel.text = NSLocalizedString(@"Zoom", nil).uppercaseString;
    self.irisLabel.text = NSLocalizedString(@"Iris", nil).uppercaseString;

    NSMutableArray *views = [NSMutableArray array];
    if ([self.model.serviceCommands containsObject:@"IrisClose_Press"])
    {
        [views addObject:self.irisLabel];
    }
    if ([self.model.serviceCommands containsObject:@"CameraZoomIn_Press"])
    {
        [views addObject:self.zoomLabel];
    }
    
    return views;
}

#pragma mark - SCUSwipeViewDelegate methods

- (void)swipeView:(SCUSwipeView *)swipeView didReceiveInteraction:(SCUSwipeViewDirection)interaction isHold:(BOOL)isHold
{
    switch (interaction)
    {
        case SCUSwipeViewDirectionUp:
            [self tiltUp];
            [self tiltUpRelease];
            break;
        case SCUSwipeViewDirectionDown:
            [self tiltDown];
            [self tiltDownRelease];
            break;
        case SCUSwipeViewDirectionLeft:
            [self panLeft];
            [self panLeftRelease];
            break;
        case SCUSwipeViewDirectionRight:
            [self panRight];
            [self panRightRelease];
            break;
    }
}

#pragma mark - MinusPlus commands

- (void)handleMinusPress
{
    if (self.pickerView.currentView == self.irisLabel)
    {
        [self sendCommand:@"IrisClose_Press"];
    }
    else if (self.pickerView.currentView == self.zoomLabel)
    {
        [self sendCommand:@"CameraZoomOut_Press"];
    }
}

- (void)handleMinusRelease
{
    if (self.pickerView.currentView == self.irisLabel)
    {
        [self sendCommand:@"IrisOpen_Release"];
    }
    else if (self.pickerView.currentView == self.zoomLabel)
    {
        [self sendCommand:@"CameraZoomOut_Release"];
    }
}

- (void)handlePlusPress
{
    if (self.pickerView.currentView == self.irisLabel)
    {
        [self sendCommand:@"IrisOpen_Press"];
    }
    else if (self.pickerView.currentView == self.zoomLabel)
    {
        [self sendCommand:@"CameraZoomIn_Press"];
    }
}

- (void)handlePlusRelease
{
    if (self.pickerView.currentView == self.irisLabel)
    {
        [self sendCommand:@"IrisClose_Release"];
    }
    else if (self.pickerView.currentView == self.zoomLabel)
    {
        [self sendCommand:@"CameraZoomIn_Release"];
    }
}

#pragma mark - UIPickerView Delegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    titleLabel.text = [self.pickerModel titleForRow:row];
    titleLabel.font = [UIDevice isPad] ? [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h9] : [UIFont fontWithName:@"Gotham-Book" size:[[SCUDimens dimens] regular].h11];
    titleLabel.textColor = [pickerView selectedRowInComponent:component] == row ? [[SCUColors shared] color01] : [[SCUColors shared] color03shade07 ];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    return titleLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [pickerView reloadComponent:component];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 20;
}

- (void)pageChanged:(NSUInteger)page
{
    
}

#pragma mark - PTZ

- (void)tiltDown
{
    [self sendCommand:@"TiltDown_Press"];
}

- (void)tiltDownRelease
{
    [self sendCommand:@"TiltDown_Release"];
}

- (void)tiltUp
{
    [self sendCommand:@"TiltUp_Press"];
}

- (void)tiltUpRelease
{
    [self sendCommand:@"TiltUp_Release"];
}

- (void)panLeft
{
    [self sendCommand:@"PanLeft_Press"];
}

- (void)panLeftRelease
{
    [self sendCommand:@"PanLeft_Release"];
}

- (void)panRight
{
    [self sendCommand:@"PanRight_Press"];
}

- (void)panRightRelease
{
    [self sendCommand:@"PanRight_Release"];
}

#pragma mark -

- (void)sendCommand:(NSString *)command
{
    [self.model sendCommand:command];
}

@end
