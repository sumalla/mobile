//
//  SCUPagedViewControl.m
//  SavantController
//
//  Created by Stephen Silber on 4/17/15.
//  Copyright (c) 2015 Savant Systems. All rights reserved.
//

#import "SCUPagedViewControl.h"
#import <SavantExtensions/SavantExtensions.h>

@interface SCUPagedViewControl () <UIScrollViewDelegate>

@property (nonatomic) NSArray *views;
@property (nonatomic) UIView *currentView;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) BOOL pageControlBeingUsed;

@end

@implementation SCUPagedViewControl

- (instancetype)initWithViews:(NSArray *)views
{
    self = [self initWithFrame:CGRectZero];
    
    if (self)
    {
        self.views = views;
        [self setupViews];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.scrollView addGestureRecognizer:tap];
    }
    
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    for (NSUInteger i = 0; i < self.views.count; i++)
    {
        UIView *view = self.views[i];
        CGRect frame = CGRectZero;
        frame.origin.y = 0;
        frame.origin.x = size.width * i;
        frame.size.width = size.width;
        frame.size.height = size.height;
        view.frame = frame;
    }
    
    CGSize contentSize = CGSizeMake(self.views.count * size.width, size.height);
    self.scrollView.contentSize = contentSize;
}

- (void)setupViews
{
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.scrollView];
    [self sav_addFlushConstraintsForView:self.scrollView];
    
    for (NSUInteger i = 0; i < self.views.count; i++)
    {
        UIView *view = self.views[i];
        [self.scrollView addSubview:view];
    }
    
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
    self.pageControl.userInteractionEnabled = NO;
    
    [self setNumberOfPages:self.views.count];
    
    [self addSubview:self.pageControl];
    [self sav_pinView:self.pageControl withOptions:SAVViewPinningOptionsCenterX];
    [self sav_pinView:self.pageControl withOptions:SAVViewPinningOptionsToBottom withSpace:2];
    [self sav_setHeight:20 forView:self.pageControl isRelative:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (!self.pageControlBeingUsed)
    {
        // Switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = self.scrollView.frame.size.width;
        int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        [self setCurrentPage:page];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if (self.currentPage + 1 < self.views.count)
    {
        self.currentPage++;
    }
    else
    {
        self.currentPage = 0;
    }
    
    UIView *view = self.views[self.currentPage];
    self.pageControlBeingUsed = YES;
    [UIView animateWithDuration:0.15 animations:^{
        [self.scrollView scrollRectToVisible:view.frame animated:NO];
    } completion:^(BOOL finished) {
        self.pageControlBeingUsed = NO;
    }];
}

- (NSUInteger)numberOfPages
{
    return self.pageControl.numberOfPages;
}

- (void)setCurrentPage:(NSUInteger)currentPage
{
    if (_currentPage != currentPage)
    {
        self.pageControl.currentPage = currentPage;
        _currentPage = currentPage;
        
        self.currentView = self.views[currentPage];
        
        if ([self.delegate respondsToSelector:@selector(pageChanged:)])
        {
            [self.delegate pageChanged:currentPage];
        }
    }
}

- (void)setNumberOfPages:(NSUInteger)pages
{
    self.pageControl.numberOfPages = pages;
    if (self.views.count)
    {
    self.currentView = self.views[0];
    }

    if (pages < 2)
    {
        self.pageControl.alpha = 0;
        self.scrollView.userInteractionEnabled = NO;
    }
    else
    {
        self.pageControl.alpha = 1;
        self.scrollView.userInteractionEnabled = YES;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.pageControlBeingUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlBeingUsed = NO;
}

@end
