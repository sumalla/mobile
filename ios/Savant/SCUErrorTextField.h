//
//  SCUErrorTextField.h
//  SavantController
//
//  Created by Cameron Pulsford on 8/18/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUTextField.h"

@interface SCUErrorTextField : SCUTextField

@property (nonatomic) NSString *errorMessage;

- (void)restore;

@end
