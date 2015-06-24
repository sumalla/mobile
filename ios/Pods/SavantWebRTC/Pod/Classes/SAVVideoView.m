//
//  JanusVideoView.m
//  Pods
//
//  Created by Joseph Ross on 3/16/15.
//
//

#import "SAVVideoView.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"

@interface SAVVideoView () <RTCEAGLVideoViewDelegate>

@property(nonatomic,strong) RTCEAGLVideoView *videoView;
@property(nonatomic,strong) RTCVideoTrack *videoTrack;
@property(nonatomic) CGSize remoteVideoSize;

@end

@implementation SAVVideoView

- (instancetype)init {
    if (self = [super init]) {
        self.previewImageView = [[UIImageView alloc] init];
        [self addSubview:self.previewImageView];
        self.videoView = [[RTCEAGLVideoView alloc] init];
        self.videoView.delegate = self;
        [self addSubview:self.videoView];
        self.videoResizeMode = VideoResizeModeAspectFit;
    }
    return self;
    
}

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    self.remoteVideoSize = size;
    if (size.height > 0 && size.width > 0) {
        [self setNeedsLayout];
    }
}


- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.remoteVideoSize;
    if (self.videoResizeMode == VideoResizeModeAspectFill) {
        [self aspectFillVideo];
    } else if (self.videoResizeMode == VideoResizeModeStretch) {
        [self stretchVideo];
    } else {
        [self aspectFitVideo];
    }
    if (self.remoteVideoSize.height > 0 && self.remoteVideoSize.width > 0) {
        [self.delegate videoView:self didChangeVideoSize:size];
    }
}

- (void)stretchVideo {
    // stretch video in the view
    
    CGSize imageSize = self.previewImageView.image.size;
    if (imageSize.height > 0 && imageSize.width > 0) {
        self.previewImageView.frame = self.bounds;
        self.previewImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
    
    if (self.remoteVideoSize.width > 0 && self.remoteVideoSize.height > 0) {
        self.videoView.frame = self.bounds;
        self.videoView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

- (void)aspectFillVideo {
    // aspect fill the video in the view
    if (self.remoteVideoSize.width > 0 && self.remoteVideoSize.height > 0) {
        CGRect frame = self.bounds;
        CGFloat xRatio = self.remoteVideoSize.width / frame.size.width;
        CGFloat yRatio = self.remoteVideoSize.height / frame.size.height;
        if (xRatio <= yRatio) {
            frame.size.height = frame.size.width * (self.remoteVideoSize.height / self.remoteVideoSize.width);
        } else {
            frame.size.width = frame.size.height * (self.remoteVideoSize.width / self.remoteVideoSize.height);
        }
        self.videoView.frame = frame;
        self.videoView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
    
    //aspect fill the preview image in the view
    CGSize imageSize = self.previewImageView.image.size;
    if (imageSize.height > 0 && imageSize.width > 0) {
        CGRect frame = self.bounds;
        CGFloat xRatio = self.previewImageView.image.size.width / frame.size.width;
        CGFloat yRatio = self.previewImageView.image.size.height / frame.size.height;
        if (xRatio <= yRatio) {
            frame.size.height = frame.size.width * (imageSize.height / imageSize.width);
        } else {
            frame.size.width = frame.size.height * (imageSize.width / imageSize.height);
        }
        self.previewImageView.frame = frame;
        self.previewImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

- (void)aspectFitVideo {
    // aspect fit the video in the view
    if (self.remoteVideoSize.width > 0 && self.remoteVideoSize.height > 0) {
        CGRect frame = self.bounds;
        CGFloat xRatio = self.remoteVideoSize.width / frame.size.width;
        CGFloat yRatio = self.remoteVideoSize.height / frame.size.height;
        if (xRatio >= yRatio) {
            frame.size.height = frame.size.width * (self.remoteVideoSize.height / self.remoteVideoSize.width);
        } else {
            frame.size.width = frame.size.height * (self.remoteVideoSize.width / self.remoteVideoSize.height);
        }
        self.videoView.frame = frame;
        self.videoView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
    
    //aspect fill the preview image in the view
    CGSize imageSize = self.previewImageView.image.size;
    if (imageSize.height > 0 && imageSize.width > 0) {
        CGRect frame = self.bounds;
        CGFloat xRatio = self.previewImageView.image.size.width / frame.size.width;
        CGFloat yRatio = self.previewImageView.image.size.height / frame.size.height;
        if (xRatio >= yRatio) {
            frame.size.height = frame.size.width * (imageSize.height / imageSize.width);
        } else {
            frame.size.width = frame.size.height * (imageSize.width / imageSize.height);
        }
        self.previewImageView.frame = frame;
        self.previewImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

- (void)setPreviewImage:(UIImage *)previewImage {
    self.previewImageView.image = previewImage;
    [self setNeedsLayout];
}

- (void)attachVideoForTrack:(RTCVideoTrack *)videoTrack {
    self.videoTrack = videoTrack;
    [videoTrack addRenderer:self.videoView];
}

- (void)detachVideo {
    [self.videoTrack removeRenderer:self.videoView];
    self.videoTrack = nil;
    [self.videoView renderFrame:nil];
    self.remoteVideoSize = CGSizeZero;
    self.videoView.frame = CGRectZero;
}

- (UIView*)visibleVideoView {
    return self.videoView;
}

@end
