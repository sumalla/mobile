//
//  SCUTextFieldListener.m
//  SavantController
//
//  Created by Cameron Pulsford on 3/27/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTextFieldListener.h"
@import Extensions;

@interface SCUTextFieldListenerValidationOptions ()

- (BOOL)isStringValid:(NSString *)string withReplacementString:(NSString *)replacementString;

@end

@interface SCUTextFieldListener () <UITextFieldDelegate>

@property (nonatomic) NSMutableDictionary *validationOptions;

@property (nonatomic) NSMutableDictionary *textFields;

@end

@implementation SCUTextFieldListener

- (void)dealloc
{
    for (UITextField *textField in [self.textFields allValues])
    {
        textField.delegate = nil;
    }
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.validationOptions = [NSMutableDictionary dictionary];
        self.textFields = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)setValidationOptions:(SCUTextFieldListenerValidationOptions *)validationOptions forTag:(NSInteger)tag
{
    if (validationOptions)
    {
        self.validationOptions[@(tag)] = validationOptions;
    }
}

- (void)listenToTextField:(UITextField *)textField withTag:(NSInteger)tag
{
    textField.delegate = self;
    textField.tag = tag;
    self.textFields[@(tag)] = textField;
}

- (void)validateTextFieldWithTag:(NSInteger)tag
{
    UITextField *textField = self.textFields[@(tag)];
    SCUTextFieldListenerValidationOptions *validationOptions = self.validationOptions[@(tag)];

    if (textField && validationOptions)
    {
        if (![validationOptions isStringValid:textField.text withReplacementString:nil])
        {
            SCUErrorTextField *errorTextField = [self errorTextFieldFromTextField:textField];

            if (errorTextField && validationOptions.errorMessage)
            {
                errorTextField.errorMessage = validationOptions.errorMessage;

                if ([self.delegate respondsToSelector:@selector(textFieldListener:errorTextFieldDidEndInInvalidState:)])
                {
                    [self.delegate textFieldListener:self errorTextFieldDidEndInInvalidState:errorTextField];
                }
            }
        }
    }
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    SCUErrorTextField *errorTextField = [self errorTextFieldFromTextField:textField];
    [errorTextField restore];

    if ([self.delegate respondsToSelector:@selector(textFieldListener:didClearTextForErrorTextField:)])
    {
        [self.delegate textFieldListener:self didClearTextForErrorTextField:errorTextField];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self saveTextFromTextField:textField];

    if ([self.delegate respondsToSelector:@selector(textFieldListener:textFieldDidEndEditingWithTag:)])
    {
        [self.delegate textFieldListener:self textFieldDidEndEditingWithTag:textField.tag];
    }

    SCUErrorTextField *errorTextField = [self errorTextFieldFromTextField:textField];

    if (errorTextField)
    {
        SCUTextFieldListenerValidationOptions *validationOptions = self.validationOptions[@(textField.tag)];

        if (![validationOptions isStringValid:textField.text withReplacementString:nil])
        {
            errorTextField.errorMessage = validationOptions.errorMessage;

            if ([self.delegate respondsToSelector:@selector(textFieldListener:errorTextFieldDidEndInInvalidState:)])
            {
                [self.delegate textFieldListener:self errorTextFieldDidEndInInvalidState:errorTextField];
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChange = YES;

    SCUTextFieldListenerValidationOptions *validationOptions = self.validationOptions[@(textField.tag)];

    if (validationOptions.continuous)
    {
        if (validationOptions)
        {
            shouldChange = [validationOptions isStringValid:textField.text withReplacementString:string];
        }
    }

    [self saveTextFromTextField:textField];

    return shouldChange;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *text = [self saveTextFromTextField:textField];

    if ([self.delegate respondsToSelector:@selector(textFieldListener:textFieldDidReturnWithTag:finalText:)])
    {
        [self.delegate textFieldListener:self textFieldDidReturnWithTag:textField.tag finalText:text];
    }
    
    return YES;
}

#pragma mark -

- (NSString *)saveTextFromTextField:(UITextField *)textField
{
    NSString *text = textField.text;

    if ([self.delegate respondsToSelector:@selector(textFieldListener:didReceiveText:fromTag:)])
    {
        [self.delegate textFieldListener:self didReceiveText:text fromTag:textField.tag];
    }

    return text;
}

- (SCUErrorTextField *)errorTextFieldFromTextField:(UITextField *)tf
{
    SCUErrorTextField *textField = (SCUErrorTextField *)tf;

    if (![textField isKindOfClass:[SCUErrorTextField class]])
    {
        textField = nil;
    }

    return textField;
}

@end

@implementation SCUTextFieldListenerValidationOptions

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        self.continuous = YES;
        self.maximumLength = NSUIntegerMax;
    }

    return self;
}

- (BOOL)isStringValid:(NSString *)string withReplacementString:(NSString *)replacementString
{
    BOOL isValid = YES;

    if (self.validCharacters)
    {
        if ([replacementString rangeOfCharacterFromSet:self.validCharacters].location == NSNotFound)
        {
            isValid = NO;
        }
    }

    if (isValid && [string length] >= self.maximumLength)
    {
        isValid = NO;
    }

    if (isValid && [string length] < self.minimumLength)
    {
        isValid = NO;
    }

    if (isValid && [self.mustContainCharacters length])
    {
        for (NSUInteger idx = 0; idx < [self.mustContainCharacters length]; idx++)
        {
            NSString *s = [NSString stringWithFormat:@"%c", [self.mustContainCharacters characterAtIndex:idx]];

            if (![string containsString:s])
            {
                isValid = NO;
                break;
            }
        }
    }

    if (isValid && self.email)
    {
        isValid = [string sav_isValidEmail];
    }

    if (!isValid && [replacementString isEqualToString:@""])
    {
        isValid = YES;
    }

    return isValid;
}

@end
