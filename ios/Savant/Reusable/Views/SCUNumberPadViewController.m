//
//  SCUNumberPadViewController.m
//  SavantController
//
//  Created by Nathan Trapp on 5/5/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUNumberPadViewController.h"
#import "SCUNumberPadCollectionViewController.h"
#import "SCUNumberPadCollectionViewModel.h"
#import "SCUButtonCollectionViewCell.h"
@import Extensions;
#import "SCUGradientView.h"

@interface SCUNumberPadViewController () <SCUButtonCollectionViewControllerDelegate>

@property (nonatomic) UIView *numberPadInfoBox;
@property (nonatomic) UILabel *numberPadInfoBoxLabel;
@property (nonatomic) UIButton *deleteButton;
@property (nonatomic) NSTimer *numberTimeOutTimer;
@property (nonatomic) SCUNumberPadCollectionViewController *collectionViewController;
@property (nonatomic, weak) id<SCUButtonCollectionViewControllerDelegate> vcDelegate;

@end

@implementation SCUNumberPadViewController

- (instancetype)initWithCommands:(NSArray *)commands
{
    self = [super initWithCollectionViewController:[[SCUNumberPadCollectionViewController alloc] initWithCommands:commands]];
    if (self)
    {
        self.collectionViewController.delegate = self;
        self.inputBoxTimeout = 2;
        self.isPresetOnly = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.hideInfoBox)
    {
        self.numberPadInfoBox = [[UIView alloc] initWithFrame:CGRectZero];
        self.numberPadInfoBox.backgroundColor = [[SCUColors shared] color03shade01];
        
        
        self.numberPadInfoBoxLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.numberPadInfoBoxLabel.textColor = self.tintColor;
        self.numberPadInfoBoxLabel.text = @"";
        self.numberPadInfoBox.layer.borderColor = [[SCUColors shared] color03shade03].CGColor;
        self.numberPadInfoBox.layer.borderWidth = 1.0f;
        self.numberPadInfoBoxLabel.textAlignment = NSTextAlignmentCenter;
        self.numberPadInfoBoxLabel.lineBreakMode = NSLineBreakByTruncatingHead;
        self.numberPadInfoBoxLabel.font = [UIFont fontWithName:@"Gotham-Light" size:[UIDevice isPad] ? 26 : 20];
        
        [self.view addSubview:self.numberPadInfoBox];
        [self.numberPadInfoBox addSubview:self.numberPadInfoBoxLabel];
        
        //-------------------------------------------------------------------
        // Layout the number pad container.
        //-------------------------------------------------------------------
        NSDictionary *metrics = @{@"infoBoxHeight": [UIDevice isPad] ? @40 : @25,
                                  @"interSpacing": [UIDevice isPad] ? @7 : @8};
        
        NSDictionary *views = @{@"infoBox": self.numberPadInfoBox,
                                @"numberPad": self.collectionViewController.view};
        
        [self.view addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                         metrics:metrics
                                                                           views:views
                                                                         formats:@[@"|-interSpacing-[infoBox]-interSpacing-|",
                                                                                   @"|-interSpacing-[numberPad]-interSpacing-|",
                                                                                   @"V:|-interSpacing-[infoBox(infoBoxHeight)]-interSpacing-[numberPad]-interSpacing-|"]]];
        if (self.inputBoxTimeout == 0 || self.alwaysShowClearButton)
        {
            SCUButton *deleteButton = [[SCUButton alloc] initWithImage:[UIImage imageNamed:@"ClearButton"]];
            deleteButton.backgroundColor = [UIColor clearColor];
            deleteButton.selectedBackgroundColor = [UIColor clearColor];
            deleteButton.color = [[SCUColors shared] color04];
            deleteButton.selectedColor = [UIColor lightGrayColor];
            
            self.deleteButton = deleteButton;
            self.deleteButton.hidden = !self.alwaysShowClearButton;
            
            [self.deleteButton addTarget:self
                                  action:@selector(deleteButtonClearNumbersInBox)
                        forControlEvents:UIControlEventTouchUpInside];
            [self.numberPadInfoBox addSubview:self.deleteButton];
            
            
            metrics = @{@"deleteButtonSize": @20};
            
            views = @{
                      @"deleteButton": self.deleteButton,
                      @"numberPadInfoBoxLabel" : self.numberPadInfoBoxLabel
                      };
            
            [self.numberPadInfoBox addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                         metrics:metrics
                                                                                           views:views
                                                                                         formats:@[@"[deleteButton(deleteButtonSize)]-|",
                                                                                                   @"|[numberPadInfoBoxLabel]|",
                                                                                                   @"V:|[numberPadInfoBoxLabel]|",
                                                                                                   @"deleteButton.centerY = numberPadInfoBoxLabel.centerY",
                                                                                                   @"V:[deleteButton(deleteButtonSize)]"
                                                                                                   ]]];
        }
        else
        {
            
            views = @{
                      @"numberPadInfoBoxLabel" : self.numberPadInfoBoxLabel
                      };
            
            [self.numberPadInfoBox addConstraints:[NSLayoutConstraint sav_constraintsWithOptions:0
                                                                                         metrics:nil
                                                                                           views:views
                                                                                         formats:@[
                                                                                                   @"|[numberPadInfoBoxLabel]|",
                                                                                                   @"V:|[numberPadInfoBoxLabel]|"                                                                                               
                                                                                                   ]]];
            
        }
    }
}

- (BOOL)needsFlushConstraints
{
    return self.flushConstraints;
}

#pragma mark - SCUButtonCollectionViewControllerDelegate methods

- (void)tappedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([self.delegate respondsToSelector:@selector(tappedButton:withCommand:)])
    {
        [self.delegate tappedButton:button withCommand:command];
    }
}

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{   
    [self.delegate releasedButton:button withCommand:command];
    
    [self updateInfoBox:command];
}

#pragma mark - Internal

- (void)updateInfoBox:(NSString *)cmd
{
    NSString *newChar;
    if ([cmd containsString:@"FADE_CLEAR_BOX"])
    {
        [self.numberTimeOutTimer invalidate];
        [UIView animateWithDuration:0.5 animations:^{
            [self.numberPadInfoBoxLabel setAlpha:0];
        }
                         completion:^(BOOL finished) {
                             [self clearNumbersInBox];
                             [self.numberPadInfoBoxLabel setAlpha:1];
                         }];
    }
    else if ([cmd containsString:@"Enter"])
    {
        [self.numberTimeOutTimer invalidate];
        [self clearNumbersInBox];
    }
    else if ([cmd containsString:@"Dash"])
    {
        if ([self.numberPadInfoBoxLabel.text length] > 0)
        {
            newChar = @"-";
        }
    }
    else if ([cmd containsString:@"Dot"] || [cmd containsString:@"Point"])
    {
        if ([self.numberPadInfoBoxLabel.text length] > 0)
        {
            newChar = @".";
        }
    }
    else if ([cmd containsString:@"Asterix"])
    {
        newChar = @"*";
    }
    else if ([cmd containsString:@"Pound"])
    {
        newChar = @"#";
    }
    else if ([cmd containsString:@"Number"])
    {
        if ([cmd containsString:@"One"])
        {
            newChar = @"1";
        }
        else if ([cmd containsString:@"Two"])
        {
            newChar = @"2";
        }
        else if ([cmd containsString:@"Three"])
        {
            newChar = @"3";
        }
        else if ([cmd containsString:@"Four"])
        {
            newChar = @"4";
        }
        else if ([cmd containsString:@"Five"])
        {
            newChar = @"5";
        }
        else if ([cmd containsString:@"Six"])
        {
            newChar = @"6";
        }
        else if ([cmd containsString:@"Seven"])
        {
            newChar = @"7";
        }
        else if ([cmd containsString:@"Eight"])
        {
            newChar = @"8";
        }
        else if ([cmd containsString:@"Nine"])
        {
            newChar = @"9";
        }
        else if ([cmd containsString:@"Zero"])
        {
            newChar = @"0";
        }
    }

    if (newChar && self.isPresetOnly)
    {
        [self clearNumbersInBox];
    }
    if (newChar)
    {
        self.numberPadInfoBoxLabel.text = [NSString stringWithFormat:@"%@%@", self.numberPadInfoBoxLabel.text, newChar];
        [self.numberTimeOutTimer invalidate];

        SAVWeakSelf;
        if (self.inputBoxTimeout > 0)
        {
            self.numberTimeOutTimer = [NSTimer sav_scheduledTimerWithTimeInterval:self.inputBoxTimeout repeats:NO block:^{
                [wSelf updateInfoBox:@"FADE_CLEAR_BOX"];
            }];
        }
        else
        {
            self.deleteButton.hidden = NO;
        }
    }
}

- (void)clearNumbersInBox
{
    self.numberPadInfoBoxLabel.text = @"";
    if (self.deleteButton && !self.alwaysShowClearButton)
    {
        self.deleteButton.hidden = YES;
    }
}

- (void)deleteButtonClearNumbersInBox
{
    [self clearNumbersInBox];
    [self.delegate releasedButton:nil withCommand:kClearNumbersInternalAppCommand];
}

#pragma mark - Properties

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];

    self.numberPadInfoBoxLabel.textColor = tintColor;
}

- (void)setDelegate:(id<SCUButtonCollectionViewControllerDelegate>)delegate
{
    self.vcDelegate = delegate;
}

- (id<SCUButtonCollectionViewControllerDelegate>)delegate
{
    return self.vcDelegate;
}

- (NSString *)labelText
{
    return [self.numberPadInfoBoxLabel.text copy];
}

- (void)setLetterMapping:(BOOL)letterMapping
{
    self.collectionViewController.letterMapping = letterMapping;
}

- (BOOL)letterMapping
{
    return self.collectionViewController.letterMapping;
}

@end
