//
//  SCUAddFavoriteViewController.h
//  SavantController
//
//  Created by Jason Wolkovitz on 5/29/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

@protocol SCUAddFavoriteViewControllerDelegate;
@class SAVFavorite;

typedef void (^SCUFavoriteSystemImageResults)(NSArray *systemImages);

@interface SCUAddFavoriteViewController : UIViewController <UITextFieldDelegate>

- (instancetype)initWithFavorite:(SAVFavorite *)favorite;

@property (nonatomic, weak) id<SCUAddFavoriteViewControllerDelegate> delegate;

@end

@protocol SCUAddFavoriteViewControllerDelegate <NSObject>

- (void)updateFavorite:(SAVFavorite *)favorite;
- (void)fetchSystemImages:(SCUFavoriteSystemImageResults)results;

@end
