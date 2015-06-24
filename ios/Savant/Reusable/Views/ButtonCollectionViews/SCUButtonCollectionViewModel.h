//
//  SCUButtonCollectionViewModel.h
//  SavantController
//
//  Created by Jason Wolkovitz on 4/16/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUDataSourceModel.h"

#define SCULocalizedServiceCommand(serviceCommand) NSLocalizedStringWithDefaultValue([serviceCommand stringByAppendingString:@"-Command"], @"Command", [NSBundle mainBundle], serviceCommand, @"Localized Service Command")
// TODO: evaluate if we want this
#define SCULocalizedServiceCommandForSingleLine(serviceCommand) [SCULocalizedServiceCommand(serviceCommand) stringByReplacingOccurrencesOfString:@"\n" withString:@" "]

// TODO: should be from SAV
#define kSCUCollectionViewAdditionalActionCommand (@"SCUCollectionViewAdditionalActionCommand")

@interface SCUButtonCollectionViewModel : SCUDataSourceModel

@property (nonatomic) NSArray *dataSource;
@property (nonatomic) NSArray *commands;

- (instancetype)initWithCommands:(NSArray *)commands;

- (NSMutableDictionary *)modelObjectWithTitle:(NSString *)title imageName:(NSString *)imageName command:(NSString *)command preferredOrder:(NSNumber *)order;

- (NSString *)imageNameForCommandString:(NSString *)command;
- (NSNumber *)preferredOrderForCommand:(NSString *)command;

- (NSArray *)modelObjectsForServiceCommands:(NSArray *)commands;
- (NSDictionary *)modelObjectForServiceCommand:(NSString *)command;

#pragma mark - Methods to subclass

/**
 *  Set the correct title and image name for the given command through the out parameters.
 *
 *  @param outTitle             An out parameter of the title.
 *  @param outImageName         An our parameter of the imageName.
 *  @param serviceCommand       The service command that is sent.
 *  @param position             preferred Order for the item in the collection view.
 */

- (void)title:(out NSString *__autoreleasing*)outTitle imageName:(out NSString *__autoreleasing*)outImageName preferredOrder:(out NSNumber *__autoreleasing*)position serviceCommand:(NSString*)serviceCommand;

@end
