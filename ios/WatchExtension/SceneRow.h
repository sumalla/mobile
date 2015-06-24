//
//  SceneRow.h
//  SavantController
//
//  Created by Cameron Pulsford on 3/15/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import WatchKit;

@interface SceneRow : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *sceneNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *roomLabel;

@end
