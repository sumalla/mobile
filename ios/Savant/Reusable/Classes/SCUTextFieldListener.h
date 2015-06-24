//
//  SCUTextFieldListener.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUErrorTextField.h"

@class SCUTextFieldListenerValidationOptions;

#pragma mark -

@protocol SCUTextFieldListenerDelegate;

@interface SCUTextFieldListener : NSObject

@property (nonatomic, weak) id<SCUTextFieldListenerDelegate> delegate;

- (void)setValidationOptions:(SCUTextFieldListenerValidationOptions *)validationOptions forTag:(NSInteger)tag;

- (void)listenToTextField:(UITextField *)textField withTag:(NSInteger)tag;

- (void)validateTextFieldWithTag:(NSInteger)tag;

@end

@protocol SCUTextFieldListenerDelegate <NSObject>

@optional

- (void)textFieldListener:(SCUTextFieldListener *)listener didReceiveText:(NSString *)text fromTag:(NSInteger)tag;

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidReturnWithTag:(NSInteger)tag finalText:(NSString *)text;

- (void)textFieldListener:(SCUTextFieldListener *)listener textFieldDidEndEditingWithTag:(NSInteger)tag;

- (void)textFieldListener:(SCUTextFieldListener *)listener errorTextFieldDidEndInInvalidState:(SCUErrorTextField *)textField;

- (void)textFieldListener:(SCUTextFieldListener *)listener didClearTextForErrorTextField:(SCUErrorTextField *)textField;

@end

#pragma mark -

@interface SCUTextFieldListenerValidationOptions : NSObject

@property NSUInteger maximumLength;

@property NSUInteger minimumLength;

@property NSCharacterSet *validCharacters;

@property NSString *mustContainCharacters;

@property NSString *errorMessage;

@property BOOL email;

@property BOOL continuous;

@end
