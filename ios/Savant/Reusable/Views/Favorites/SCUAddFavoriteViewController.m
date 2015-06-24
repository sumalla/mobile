//
//  SCUAddFavoriteViewController.m
//  SavantController
//
//  Created by Jason Wolkovitz on 5/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAddFavoriteViewController.h"
#import "SCUNumberPadViewController.h"
#import "SCUModelCollectionViewController.h"
#import "SCUGradientView.h"
#import "SCUActionSheet.h"
#import "SCUErrorTextField.h"
#import "SCUTextFieldListener.h"
#import "SCUAddFavoriteChannelCollectionViewController.h"
#import "SCUButtonCollectionViewModel.h"
#import "SCUActionSheet.h"

@import Extensions;
@import SDK;

typedef NS_ENUM(NSUInteger, SCUAddFavoriteAttribute)
{
    SCUAddFavoriteAttributeName = 100,
    SCUAddFavoriteAttributeNumber = 101
};

typedef NS_ENUM(NSUInteger, SCUAddFavoriteStep)
{
    SCUAddFavoriteStepCancel = 0,
    SCUAddFavoriteStepEnterChannel = 1,
    SCUAddFavoriteStepPickLogo = 2,
    SCUAddFavoriteStepEnterSubtext = 3,
    SCUAddFavoriteStepDone = 4,
    SCUAddFavoriteStepEnterSubtextWithUserImage = 5,
    SCUAddFavoriteStepDoneWithUserImage = 6
};

@interface SCUAddFavoriteViewController () <SCUButtonCollectionViewControllerDelegate, SCUTextFieldListenerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) NSString *favoriteCommandString;
@property (nonatomic) NSString *existingImageRef;
@property (nonatomic) UIImage *userImage;
@property (nonatomic) UIImageView *favoriteImageView;
@property (nonatomic) SCUTextFieldListener *textFieldListener;
@property (nonatomic) SCUErrorTextField *nameField;
@property (nonatomic) SCUErrorTextField *numberField;
@property (nonatomic) NSString *channelDetails;

@property (nonatomic) SCUNumberPadViewController *numberPad;
@property (nonatomic) SCUAddFavoriteChannelCollectionViewController *logoPicker;

@property (nonatomic) UIImagePickerController *imagePicker;
@property (nonatomic) SAVFavorite *favorite;
@property (nonatomic) SCUActionSheet *actionsheet;
@property (nonatomic) UITapGestureRecognizer *imageTap;
@property (nonatomic) CGFloat keyboardOffset;
@property (nonatomic) BOOL isOffset;

@end

@implementation SCUAddFavoriteViewController

- (instancetype)initWithFavorite:(SAVFavorite *)favorite
{
    self = [super init];
    if (self)
    {
        self.favorite = [favorite copy] ?: [[SAVFavorite alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[SCUColors shared] color03shade01];

    [self setupViews];
    
    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
    [self.favoriteImageView addGestureRecognizer:imageTap];
    self.imageTap = imageTap;
    
    UITapGestureRecognizer *cancelKeyboardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelKeyboard)];
    [self.view addGestureRecognizer:cancelKeyboardTap];
    
    self.title = self.favorite.identifier ? NSLocalizedString(@"Edit Favorite", nil) : NSLocalizedString(@"Add Favorite", nil);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController)];
    [self.navigationController.view setBackgroundColor:[[SCUColors shared] color03shade04]];

    [self checkTextField:nil];
}

- (void)setupViews
{
    UIView *imageContainer = [[UIView alloc] initWithFrame:CGRectZero];
    imageContainer.backgroundColor = [[SCUColors shared] color03shade03];
    
    UIImageView *favoriteImage = [[UIImageView alloc] initWithFrame:CGRectZero];
    [favoriteImage setUserInteractionEnabled:YES];
    favoriteImage.contentMode = UIViewContentModeScaleAspectFill;
    favoriteImage.clipsToBounds = YES;
    
    UILabel *imagePlaceholder = [[UILabel alloc] initWithFrame:CGRectZero];
    imagePlaceholder.backgroundColor = [[SCUColors shared] color03shade02];
    imagePlaceholder.borderColor = [[SCUColors shared] color03shade05];
    imagePlaceholder.borderWidth = [UIScreen screenPixel] * 2;
    imagePlaceholder.text = NSLocalizedString(@"Image", nil);
    imagePlaceholder.textColor = [[SCUColors shared] color03shade07];
    imagePlaceholder.font = [UIFont systemFontOfSize:24];
    imagePlaceholder.textAlignment = NSTextAlignmentCenter;
    
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 179.0f, CGRectGetWidth(self.view.frame), 1.0f);
    bottomBorder.backgroundColor = [[[SCUColors shared] color03shade04] CGColor];
    [imageContainer.layer addSublayer:bottomBorder];
    [imageContainer addSubview:imagePlaceholder];
    [imageContainer addSubview:favoriteImage];
    
    UIColor *placeholderColor = [[SCUColors shared] color03shade07];
    
    SCUErrorTextField *nameField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    SCUErrorTextField *numberField = [[SCUErrorTextField alloc] initWithFrame:CGRectZero];
    
    CGFloat textViewHeight = 80.0f;
    
    self.textFieldListener = [[SCUTextFieldListener alloc] init];
    self.textFieldListener.delegate = self;
    
    for (SCUErrorTextField *textField in @[nameField, numberField])
    {
        textField.backgroundColor = [[SCUColors shared] color03shade03];
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        textField.textColor = [[SCUColors shared] color04];
        textField.tintColor = [[SCUColors shared] color01];
        textField.font = [UIFont systemFontOfSize:24];
        textField.contentInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        textField.delegate = self;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.frame = CGRectMake(0.0f, textViewHeight - 1.0f, CGRectGetWidth(self.view.frame), 1.0f);
        bottomBorder.backgroundColor = [[[SCUColors shared] color03shade04] CGColor];
        [textField.layer addSublayer:bottomBorder];
    }
    numberField.tag = SCUAddFavoriteAttributeNumber;
    nameField.tag = SCUAddFavoriteAttributeName;
    
    [nameField addTarget:self action:@selector(checkTextField:) forControlEvents:UIControlEventEditingChanged];
    [numberField addTarget:self action:@selector(checkTextField:) forControlEvents:UIControlEventEditingChanged];
    
    SCUTextFieldListenerValidationOptions *nameOptions = [[SCUTextFieldListenerValidationOptions alloc] init];
    nameOptions.continuous = YES;
    nameOptions.errorMessage = NSLocalizedString(@"This field cannot be empty", nil);
    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet alphanumericCharacterSet];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    nameOptions.validCharacters = characterSet;
    [self listenToTextField:nameField forFavoriteAttribute:SCUAddFavoriteAttributeName withOptions:nameOptions];
    
    SCUTextFieldListenerValidationOptions *numberOptions = [[SCUTextFieldListenerValidationOptions alloc] init];
    numberOptions.validCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789-."];
    numberOptions.continuous = YES;
    numberOptions.errorMessage = NSLocalizedString(@"This field can only contain numbers and a dash or period", nil);
    
    [self listenToTextField:numberField forFavoriteAttribute:SCUAddFavoriteAttributeNumber withOptions:numberOptions];
    
    nameField.returnKeyType = UIReturnKeyNext;
    numberField.returnKeyType = UIReturnKeyDone;
    
    
    nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Channel Name", nil) attributes:@{NSForegroundColorAttributeName: placeholderColor}];
    numberField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Channel Number", nil) attributes:@{NSForegroundColorAttributeName: placeholderColor}];
    
    numberField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    
    [self.view addSubview:imageContainer];
    [self.view addSubview:nameField];
    [self.view addSubview:numberField];
    
    [self.view sav_pinView:imageContainer withOptions:SAVViewPinningOptionsHorizontally|SAVViewPinningOptionsToTop];
    [self.view sav_pinView:nameField withOptions:SAVViewPinningOptionsToBottom ofView:imageContainer withSpace:[UIScreen screenPixel]];
    [self.view sav_pinView:nameField withOptions:SAVViewPinningOptionsHorizontally];
    [self.view sav_pinView:numberField withOptions:SAVViewPinningOptionsToBottom ofView:nameField withSpace:[UIScreen screenPixel]];
    [self.view sav_pinView:numberField withOptions:SAVViewPinningOptionsHorizontally];
    
    [imageContainer sav_addCenteredConstraintsForView:imagePlaceholder];
    [imageContainer sav_setSize:CGSizeMake(140, 140) forView:imagePlaceholder isRelative:NO];
    
    [imageContainer sav_addCenteredConstraintsForView:favoriteImage];
    [imageContainer sav_setSize:CGSizeMake(140, 140) forView:favoriteImage isRelative:NO];
    
    [self.view sav_setHeight:180 forView:imageContainer isRelative:NO];
    [self.view sav_setHeight:textViewHeight forView:nameField isRelative:NO];
    [self.view sav_setHeight:textViewHeight forView:numberField isRelative:NO];

    self.favoriteImageView = favoriteImage;
    self.nameField = nameField;
    self.numberField = numberField;
    
    self.nameField.text = self.favorite.name;
    self.numberField.text = self.favorite.number;
    
    if (self.favorite.image)
    {
        [self setFavoriteImageFromUserImage:self.favorite.image];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.isOffset)
    {
        CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        CGFloat visibleSize = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(keyboardFrame);
        self.keyboardOffset = CGRectGetMaxY(self.numberField.frame) - visibleSize;

        if (self.keyboardOffset < 0)
        {
            self.keyboardOffset = 0;
        }
    }

    [self setViewMovedUp:!self.isOffset];
}

- (void)cancelKeyboard
{
    if (self.isOffset)
    {
        if (self.numberField.isFirstResponder)
        {
            [self.numberField resignFirstResponder];
        }
        if (self.nameField.isFirstResponder)
        {
            [self.nameField resignFirstResponder];
        }
        
        CGRect rect = self.view.frame;
        // revert back to the normal state.
        rect.origin.y += self.keyboardOffset;
        rect.size.height -= self.keyboardOffset;
        self.isOffset = NO;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.view.frame = rect;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notifcation
{
    [self setViewMovedUp:!self.isOffset];
}

// method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp
{
    BOOL isStillResponder = NO;
    
    if (self.nameField.isFirstResponder || self.numberField.isFirstResponder)
    {
        isStillResponder = YES;
    }
    
    CGRect rect = self.view.frame;
    if (movedUp && !self.isOffset)
    {
        // 1. move the view's origin up so that the text field that will be hidden comes above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= self.keyboardOffset;
        rect.size.height += self.keyboardOffset;
        self.isOffset = YES;
    }
    else if (!movedUp && self.isOffset && !isStillResponder)
    {
        // revert back to the normal state.
        rect.origin.y += self.keyboardOffset;
        rect.size.height -= self.keyboardOffset;
        self.isOffset = NO;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.view.frame = rect;
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([UIDevice isPhone])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:(UIBarButtonItemStyleDone) target:self action:@selector(done:)] animated:YES];
	[self checkTextField:nil];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if ([UIDevice isPhone])
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)imageViewTapped:(UITapGestureRecognizer *)tap
{
    [self resignFirstResponder];
    NSMutableArray *buttons = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Channel Logos", nil), NSLocalizedString(@"Image from Library", nil), nil];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [buttons addObject:NSLocalizedString(@"Image from Camera", nil)];
    }
    self.actionsheet = [[SCUActionSheet alloc] initWithButtonTitles:buttons];
    if (!self.actionsheet.visible)
    {
        [self.actionsheet showFromRect:self.favoriteImageView.frame inView:self.view withMaxWidth:[UIDevice isPad] ? 320.0f : CGRectGetWidth([[UIScreen mainScreen] bounds])];
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;

        SAVWeakSelf;
        [self.actionsheet setCallback:^(NSInteger index) {
            if (index == -1)
            {
                // Cancel
            }
            else if (index == 0)
            {
                if (!wSelf.logoPicker)
                {
                    wSelf.logoPicker = [[SCUAddFavoriteChannelCollectionViewController alloc] initWithCommands:nil];
                    
                    if ([Savant control].isDemoSystem)
                    {
                        NSArray *commands = [[Savant data] favoriteIconsForService:nil withSearchString:@""];
                        commands = [commands arrayByAddingObject:kSCUCollectionViewAdditionalActionCommand];
                        wSelf.logoPicker.commands = commands;
                    }
                    else
                    {
                        wSelf.logoPicker.commands = @[kSCUCollectionViewAdditionalActionCommand];
                        
                        [wSelf.delegate fetchSystemImages:^(NSArray *systemImages) {
                            SAVStrongWeakSelf;
                            sSelf.logoPicker.systemImages = systemImages;
                            sSelf.logoPicker.commands = systemImages;
                        }];
                    }
                    
                    [wSelf.logoPicker.view setBackgroundColor:[[SCUColors shared] color03shade04]];
                    wSelf.logoPicker.collectionViewLayout.itemSize = CGSizeMake(125, 125);
                    SCUCollectionViewFlowLayout *flowLayout = wSelf.logoPicker.collectionViewLayout;
                    flowLayout.spaceBetweenItems = 8.0f;
                    flowLayout.minimumInteritemSpacing = [UIDevice isPad] ? 4 : 4;
                    flowLayout.minimumLineSpacing = [UIDevice isPad] ? 4 : 4;
                    flowLayout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8);
                    
                    wSelf.logoPicker.delegate = wSelf;
                }
                wSelf.logoPicker.title = NSLocalizedString([UIDevice isPad] ? @"Select Favorite Icon" : @"Select Icon", nil);
                [wSelf.navigationController pushViewController:wSelf.logoPicker animated:YES];
            }
            else if (index == 1)
            {
                //Library
                wSelf.imagePicker.modalPresentationStyle = UIModalPresentationFormSheet;
                [wSelf presentViewController:wSelf.imagePicker animated:YES completion:nil];

            }
            else if (index == 2)
            {
                // Camera present - show camera
                wSelf.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                wSelf.imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
                [wSelf presentViewController:wSelf.imagePicker animated:YES completion:nil];

            }
                
        }];
    }
}

- (void)setFavoriteImageFromUserImage:(UIImage *)image
{
    self.favoriteImageView.backgroundColor = [[SCUColors shared] color03shade03];
    self.favoriteImageView.image = image;
    [self validateTextFieldsWithErrorMessages:NO];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setFavoriteImage:(NSString *)imageRef
{
    self.favoriteImageView.backgroundColor = [[SCUColors shared] color03shade03];
    self.favoriteImageView.image = [UIImage imageNamed:imageRef];
    [self validateTextFieldsWithErrorMessages:NO];
}

- (void)listenToTextField:(UITextField *)textField forFavoriteAttribute:(SCUAddFavoriteAttribute)attribute withOptions:(SCUTextFieldListenerValidationOptions *)options
{
    if (options)
    {
        [self.textFieldListener setValidationOptions:options forTag:attribute];
    }
    
    [self.textFieldListener listenToTextField:textField withTag:attribute];
}

- (void)checkTextField:(SCUErrorTextField *)textField
{
    BOOL numberFieldValid = NO;
    BOOL nameFieldValid = NO;

    if ([self verifyNumberInput])
    {
        numberFieldValid = YES;
    }
    if (self.nameField.text.length)
    {
        nameFieldValid = YES;
    }

    
    if (nameFieldValid)
    {
        [self.nameField restore];
    }
    
    if (numberFieldValid)
    {
        [self.numberField restore];
    }
    
    if (nameFieldValid && numberFieldValid)
    {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    else
    {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }

}

- (BOOL)verifyNumberInput
{
    NSString *numberString = self.numberField.text;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9-.]+$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:numberString options:0 range:NSMakeRange(0, [numberString length])];
    BOOL isMatch = match != nil;
    
    if (isMatch)
    {
        [self.numberField restore];
        self.favoriteCommandString = self.numberField.text;
        return YES;
    }
    
    return NO;
}

- (void)validateTextFieldsWithErrorMessages:(BOOL)errorMessages
{
    if (!self.numberField.text.length)
    {
        if (errorMessages)
        {
            [self.numberField setErrorMessage:NSLocalizedString(@"This field cannot be empty", nil)];
        }
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    if (![self verifyNumberInput])
    {
        if (errorMessages)
        {
            [self.numberField setErrorMessage:NSLocalizedString(@"Invalid channel number", nil)];
        }
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    if (!self.nameField.text.length)
    {
        if (errorMessages)
        {
            [self.nameField setErrorMessage:NSLocalizedString(@"This field cannot be empty", nil)];
        }
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    [self checkTextField:nil];
    
}

#pragma mark - SCUTextFieldListenerDelegate methods

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidReturnWithTag:(NSInteger)tag finalText:(NSString *)text
{
    if (tag == SCUAddFavoriteAttributeName)
    {
        [self.nameField resignFirstResponder];
        [self.numberField becomeFirstResponder];
    }
    else
    {
        [self validateTextFieldsWithErrorMessages:YES];
        [self.numberField resignFirstResponder];
        
        [self cancelKeyboard];
    }
}

- (void)textFieldListener:(SCUTextFieldListener *)listener didClearTextForErrorTextField:(SCUErrorTextField *)textField
{
    [textField restore];
    [self validateTextFieldsWithErrorMessages:NO];
}

- (void)textFieldListener:(SCUTextFieldListener *)listener errorTextFieldDidEndInInvalidState:(SCUErrorTextField *)textField
{
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
}

- (void)done:(id)sender
{
    if (self.userImage)
    {
        [self addFavoritesDone:SCUAddFavoriteStepDoneWithUserImage];
    }
    else
    {
        [self addFavoritesDone:SCUAddFavoriteStepDone];
    }
}

- (void)next:(NSObject *)nextStep
{
    NSInteger addStep;
    if ([nextStep isKindOfClass:[NSNumber class]])
    {
        addStep = [(NSNumber *)nextStep integerValue];
    }
    else
    {
        addStep = [[self.navigationController viewControllers] count] + 1;
    }
    
    switch (addStep)
    {
        case SCUAddFavoriteStepEnterSubtext:
        case SCUAddFavoriteStepEnterSubtextWithUserImage:
        {
            if (addStep == SCUAddFavoriteStepEnterSubtextWithUserImage)
            {
                self.existingImageRef = nil;
                [self setFavoriteImageFromUserImage:self.userImage];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:(UIBarButtonItemStyleDone) target:self action:@selector(done:)];
            }
            else
            {
                self.userImage = nil;
                [self.navigationController popViewControllerAnimated:YES];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:(UIBarButtonItemStyleDone) target:self action:@selector(done:)];
                [self setFavoriteImage:self.existingImageRef];
            }
            
            [self validateTextFieldsWithErrorMessages:NO];
            break;
        }
        case SCUAddFavoriteStepDone:
        case SCUAddFavoriteStepDoneWithUserImage:
        {
            [self addFavoritesDone:addStep];
            [self validateTextFieldsWithErrorMessages:NO];
            break;
        }
    }
}

- (void)addFavoritesDone:(SCUAddFavoriteStep)step
{
    if (step == SCUAddFavoriteStepDoneWithUserImage)
    {
        self.favorite.hasCustomImage = YES;
        self.favorite.imageKey = [[Savant images] saveImage:self.userImage withKey:@"" type:SAVImageTypeFavoriteImage];
    }
    else if (self.existingImageRef)
    {
        self.favorite.hasCustomImage = NO;
        self.favorite.imageKey = self.existingImageRef;
    }

    self.favorite.name = self.nameField.text;
    self.favorite.number = self.numberField.text;

    [self.delegate updateFavorite:self.favorite];

    [self dismissViewController];
}

#pragma mark - SCUButtonCollectionViewControllerDelegate method

- (void)releasedButton:(SCUButtonCollectionViewCell *)button withCommand:(NSString *)command
{
    if ([command isEqualToString:kSCUCollectionViewAdditionalActionCommand])
    {
        if (!self.imagePicker)
        {
            self.imagePicker = [[UIImagePickerController alloc] init];
            self.imagePicker.delegate = self;
        }
        
        if (!(self.imagePicker == [self.navigationController topViewController]) && !self.imagePicker.isBeingPresented)
        {
            self.navigationItem.rightBarButtonItem = nil;
			[self presentViewController:self.imagePicker animated:YES completion:nil];
        }
    }
    else if ([command hasSuffix:@".png"] || [command hasSuffix:@".jpg"] || [command hasSuffix:@".gif"])
    {
        self.existingImageRef = command;
        [self next:nil];
    }
    else
    {
        SAVWeakSelf;
        self.favorite.imageChangeCallback = ^(UIImage *image){
            [wSelf setFavoriteImageFromUserImage:image];
        };

        self.favorite.hasCustomImage = YES;
        self.favorite.imageKey = command;

        [self next:nil];
    }
}

- (void)dismissViewController
{
    self.imagePicker.delegate = nil;
    self.imagePicker = nil;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	self.imagePicker.delegate = nil;
	[self.imagePicker dismissViewControllerAnimated:YES completion:nil];
	self.imagePicker = nil;
	
	if (info && info[UIImagePickerControllerOriginalImage])
		self.userImage = [UIImage imageWithImage:info[UIImagePickerControllerOriginalImage] scale:1.0f];
	
    if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary || UIImagePickerControllerSourceTypeCamera)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
	
	[self next:@(SCUAddFavoriteStepEnterSubtextWithUserImage)];
}

@end
