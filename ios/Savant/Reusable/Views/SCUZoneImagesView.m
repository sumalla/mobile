//
//  SCUZoneImagesView.m
//  SavantController
//
//  Created by Stephen Silber on 11/7/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUZoneImagesView.h"
@import Extensions;

@interface SCUZoneImagesViewManager : NSObject

@property (nonatomic) NSHashTable *weakObjects;
@property (nonatomic) NSTimer *transitionTimer;

@end

@implementation SCUZoneImagesViewManager

+ (instancetype)sharedInstance
{
    static SCUZoneImagesViewManager *sharedInstance;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SCUZoneImagesViewManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        self.weakObjects = [NSHashTable weakObjectsHashTable];
    }
    
    return self;
}

- (void)addImageView:(SCUZoneImagesView *)view
{
    [self.weakObjects addObject:view];
    if (!self.transitionTimer)
    {
        SAVWeakSelf;
        self.transitionTimer = [NSTimer sav_scheduledTimerWithTimeInterval:3 repeats:YES block:^{
            [wSelf transitionImageViews];
        }];
    }
}

- (void)removeImageView:(SCUZoneImagesView *)view
{
    [self.weakObjects removeObject:view];
    
    if (!self.weakObjects.count)
    {
        [self.transitionTimer invalidate];
        self.transitionTimer = nil;
    }
}

- (void)transitionImageViews
{
    for (SCUZoneImagesView *view in self.weakObjects)
    {
        [view next];
    }
}

@end

@interface SCUZoneImagesView ()

@property UIImageView *roomImage;
@property UIImageView *selectedImage;
@property UILabel *zoneName;
@property UILabel *roomNames;

@property NSMutableArray *images;
@property (nonatomic)  BOOL swipeEnabled;
@property NSInteger currentIndex;

@end

@implementation SCUZoneImagesView

- (void)dealloc
{
    [[SCUZoneImagesViewManager sharedInstance] removeImageView:self];
    self.roomImage = nil;
    self.images = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        self.imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.imageButton.backgroundColor = [UIColor clearColor];
        self.imageButton.userInteractionEnabled = NO;
        
        self.images = [NSMutableArray array];
        self.roomImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        self.roomImage.contentMode = UIViewContentModeScaleAspectFill;
        self.roomImage.clipsToBounds = YES;
        self.roomImage.userInteractionEnabled = NO;
        
        [self addSubview:self.roomImage];
        
        self.selectedImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.selectedImage.contentMode = UIViewContentModeCenter;
        self.selectedImage.layer.borderColor = [[[SCUColors shared] color03] colorWithAlphaComponent:.25].CGColor;
        self.selectedImage.layer.borderWidth = [UIScreen screenPixel];
        self.selectedImage.backgroundColor = [[[SCUColors shared] color03shade05] colorWithAlphaComponent:.9];
        self.selectedImage.hidden = YES;
        self.selectedImage.userInteractionEnabled = NO;
        self.selectedImage.image = [UIImage sav_imageNamed:@"check" tintColor:[[SCUColors shared] color04]];
        
        [self addSubview:self.selectedImage];
        
        [self sav_addFlushConstraintsForView:self.selectedImage];
        [self sav_addFlushConstraintsForView:self.roomImage];
        
        [self addSubview:self.imageButton];
        [self sav_addFlushConstraintsForView:self.imageButton];
        
        [[SCUZoneImagesViewManager sharedInstance] addImageView:self];
    }
    
    return self;
}

- (void)setSwipeEnabled:(BOOL)swipeEnabled
{
    _swipeEnabled = swipeEnabled;
    
    if (swipeEnabled)
    {
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        [self.roomImage addGestureRecognizer:swipe];
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)geseture
{
//    switch (geseture.direction)
//    {
//        case UISwipeGestureRecognizerDirectionLeft:
//        {
//            [self.transitionTimer invalidate];
//            self.transitionTimer = nil;
//            self.currentIndex = ((self.currentIndex - 2) >= 0) ? self.currentIndex - 2 : 0;
//            [self transitionToNextImage];
//            [NSTimer sav_scheduledBlockWithDelay:5 block:^{
//                [self setupTransitionTimer];
//            }];
//            break;
//        }
//        case UISwipeGestureRecognizerDirectionRight:
//        {
//            [self.transitionTimer invalidate];
//            self.transitionTimer = nil;
//            self.currentIndex = ((self.currentIndex + 1) < (int)self.images.count - 1) ? self.currentIndex + 1 : self.images.count - 2;
//            [self transitionToNextImage];
//            [NSTimer sav_scheduledBlockWithDelay:5 block:^{
//                [self setupTransitionTimer];
//            }];
//            break;
//        }
//    }
}

- (void)transitionToImage:(UIImage *)image
{
    [UIView transitionWithView:self.roomImage
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.roomImage.image = image;
                    } completion:nil];
}

- (void)next
{
    if (!self.images.count)
    {
        return;
    }
    
    UIImage *nextImage;

    if (self.currentIndex < (int)self.images.count - 1)
    {
        nextImage = self.images[self.currentIndex + 1];
        self.currentIndex++;
    }
    else
    {
        nextImage = self.images[0];
        self.currentIndex = 0;
    }

    [self transitionToImage:nextImage];
}

- (void)setSelected:(BOOL)selected
{
    self.selectedImage.hidden = !selected;
}

- (void)setImagesFromArray:(NSArray *)images
{
    if (images.count)
    {
        if (!self.images.count)
        {
            self.roomImage.image = [images firstObject];
        }
        
        self.images = [NSMutableArray arrayWithArray:images];
    }
}

@end
