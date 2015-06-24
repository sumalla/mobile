//
//  Extensions.h
//  Extensions
//
//  Created by Cameron Pulsford on 3/23/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

@import UIKit;

#import <Extensions/NSArray+SAVExtensions.h>
#import <Extensions/NSBundle+SAVExtensions.h>
#import <Extensions/NSArray+SAVExtensions.h>
#import <Extensions/NSData+SAVExtensions.h>
#import <Extensions/NSDate+SAVExtensions.h>
#import <Extensions/NSDictionary+SAVExtensions.h>
#import <Extensions/NSMutableArray+SAVExtensions.h>
#import <Extensions/NSNull+SAVExtensions.h>
#import <Extensions/NSObject+SAVExtensions.h>
#import <Extensions/NSSet+SAVExtensions.h>
#import <Extensions/NSString+SAVExtensions.h>
#import <Extensions/NSTimer+SAVExtensions.h>
#import <Extensions/NSUserDefaults+SAVExtensions.h>
#import <Extensions/SAVCollectionTypes.h>
#import <Extensions/NSLayoutConstraint+SAVExtensions.h>
#import <Extensions/SAVUIKitExtensions.h>
#import <Extensions/UIApplication+SAVExtensions.h>
#import <Extensions/UIButton+SAVExtensions.h>
#import <Extensions/UICollectionView+SAVExtensions.h>
#import <Extensions/UIColor+SAVExtensions.h>
#import <Extensions/UIControl+SAVExtensions.h>
#import <Extensions/UIDatePicker+SAVExtensions.h>
#import <Extensions/UIDevice+SAVExtensions.h>
#import <Extensions/UIFont+SAVExtensions.h>
#import <Extensions/UIGestureRecognizer+SAVExtensions.h>
#import <Extensions/UIImage+SAVExtensions.h>
#import <Extensions/UINavigationController+SAVExtensions.h>
#import <Extensions/UIScreen+SAVExtensions.h>
#import <Extensions/UIScrollView+SAVExtensions.h>
#import <Extensions/UISwitch+SAVExtensions.h>
#import <Extensions/UITableView+SAVExtensions.h>
#import <Extensions/UITextField+SAVExtensions.h>
#import <Extensions/UIView+SAVExtensions.h>
#import <Extensions/UIViewController+SAVExtensions.h>
#import <Extensions/SAVAccessibilityTextSizeRegistration.h>
#import <Extensions/SAVCoalescedTimer.h>
#import <Extensions/SAVKeychainKeyValueStore.h>
#import <Extensions/SAVKVORegistration.h>
#import <Extensions/SCUStyles.h>
#import <Extensions/SAVUtils.h>
#import <Extensions/CBPDeref.h>
#import <Extensions/CBPDerefSubclass.h>
#import <Extensions/CBPPromise.h>
#import <Extensions/NSAttributedString+SAVExtensions.h>

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));
