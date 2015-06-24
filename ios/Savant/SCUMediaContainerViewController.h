//
//  SCUMediaContainerViewController.h
//  SavantController
//
//  Created by Cameron Pulsford on 7/25/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUMediaDataModel.h"
#import "SCUMainNavbarManager.h"
#import "SCUNowPlayingViewController.h"
#import "SCUServiceViewProtocol.h"

typedef NS_ENUM(NSUInteger, SCUMediaContainerPresentationStyle)
{
    SCUMediaContainerPresentationStyleTableView,
    SCUMediaContainerPresentationStyleCollectionView
};

@protocol SCUMediaContainerViewDelegate;

@interface SCUMediaContainerViewController : UIViewController

@property (nonatomic, getter = isModal) BOOL modal;
@property (nonatomic, weak) id <SCUServiceViewProtocol> delegate;

- (instancetype)initWithNowPlayingViewController:(SCUNowPlayingViewController *)nowPlayingViewController;

- (void)loadModel:(SCUMediaDataModel *)model withStyle:(SCUMediaContainerPresentationStyle)presentationStyle;

@property (nonatomic, readonly, weak) UIViewController *viewController;
@property (nonatomic, readonly) SCUNowPlayingViewController *nowPlayingViewController;

@end
