//
//  JanusVideoView.h
//  Pods
//
//  Created by Joseph Ross on 3/16/15.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VideoResizeMode) {
    VideoResizeModeStretch,
    VideoResizeModeAspectFill,
    VideoResizeModeAspectFit,
};

@class SAVVideoView;

@protocol SAVVideoViewDelegate <NSObject>

- (void)videoView:(SAVVideoView*)videoView didChangeVideoSize:(CGSize)videoSize;

@end

@interface SAVVideoView : UIView

- (instancetype)init;
- (void)detachVideo;
- (void)setPreviewImage:(UIImage *)previewImage;
- (UIView*)visibleVideoView;

@property(nonatomic,strong) UIImageView *previewImageView;
@property(nonatomic,readonly) CGSize remoteVideoSize;
@property(nonatomic) VideoResizeMode videoResizeMode;
@property(nonatomic,weak) NSObject<SAVVideoViewDelegate> *delegate;

@end
