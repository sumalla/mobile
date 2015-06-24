//
//  SCUArtworkImageView.h
//  SavantController
//
//  Created by Cameron Pulsford on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

@import UIKit;

//-------------------------------------------------------------------
// CBP TODO: MOVE THIS TO THE CORRECT FOLDER
//-------------------------------------------------------------------

@protocol SCUArtworkImageViewDelegate;

@interface SCUArtworkImageView : UIImageView

@property (nonatomic, weak) id<SCUArtworkImageViewDelegate> delegate;

@end

@protocol SCUArtworkImageViewDelegate <NSObject>

- (void)artworkViewWasTapped:(SCUArtworkImageView *)artworkView;

@end
