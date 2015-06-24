//
//  SDKInterfaceControllerPrivate.h
//  SavantController
//
//  Created by Nathan Trapp on 4/7/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SDKInterfaceController.h"

@interface SDKInterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *statusLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *reconnectIcon;
@property (nonatomic) BOOL hasConnected;
@property (nonatomic) NSString *lastConnectedUID;

- (void)connectionIsReady;
- (void)showStatusLabelWithText:(NSString *)text;
- (BOOL)cachedDataAvailable;

@end