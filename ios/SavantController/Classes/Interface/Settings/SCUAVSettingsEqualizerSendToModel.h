//
//  SCUAVSettingsEqualizerSendToModel.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/6/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUAVSettingsRoomGroupTableModel.h"
#import <SavantControl/SavantControl.h>
@class SCUAVSettingsEqualizerModel;

@interface SCUAVSettingsEqualizerSendToModel : SCUAVSettingsRoomGroupTableModel

- (instancetype)initWithDISRequestGenerator:(SAVDISRequestGenerator *)disRequestGenerator equalizerModel:(SCUAVSettingsEqualizerModel *)equalizerModel;

@end
