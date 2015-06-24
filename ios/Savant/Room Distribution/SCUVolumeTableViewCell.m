//
//  SCUVolumeTableViewCell.m
//  SavantController
//
//  Created by Nathan Trapp on 5/9/14.
//  Copyright (c) 2014 Savant Systems. All rights reserved.
//

#import "SCUVolumeTableViewCell.h"
#import "SCUVolumeViewController.h"
#import "SCUSlingshot.h"

@import SDK;

NSString *const SCUVolumeCellKeyService = @"SCUVolumeCellKeyService";
NSString *const SCUVolumeCellKeyServiceGroup = @"SCUVolumeCellKeyServiceGroup";
NSString *const SCUVolumeCellKeyDisallowGlobalRoomVolume = @"SCUVolumeCellKeyDisallowGlobalRoomVolume";

@interface SCUVolumeTableViewCell ()

@property (nonatomic) SCUVolumeViewController *volumeVC;

@end

@implementation SCUVolumeTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.volumeVC.volumeSlingshot.interactionCallback = nil;
    self.volumeVC.ignoreFirstAnimation = self.ignoreFirstAnimation;
}

- (void)setIgnoreFirstAnimation:(BOOL)ignoreFirstAnimation
{
    self.volumeVC.ignoreFirstAnimation = ignoreFirstAnimation;
    _ignoreFirstAnimation = ignoreFirstAnimation;
}

- (void)configureWithInfo:(id)info
{
    SAVService *service = info[SCUVolumeCellKeyService];
    SAVServiceGroup *serviceGroup = info[SCUVolumeCellKeyServiceGroup];

    if (self.volumeVC)
    {
        if (service)
        {
            self.volumeVC.service = service;
        }
        else
        {
            self.volumeVC.serviceGroup = serviceGroup;
        }
    }
    else
    {
        if (service)
        {
            self.volumeVC = [[SCUVolumeViewController alloc] initWithService:service];
        }
        else if (serviceGroup)
        {
            self.volumeVC = [[SCUVolumeViewController alloc] initWithServiceGroup:serviceGroup];
        }

        self.volumeVC.fullWidth = YES;
        [self.contentView addSubview:self.volumeVC.view];
        [self.contentView sav_addFlushConstraintsForView:self.volumeVC.view];
    }

    self.volumeVC.disallowGlobalRoomVolume = [info[SCUVolumeCellKeyDisallowGlobalRoomVolume] boolValue];
    self.volumeVC.enabled = service || [serviceGroup.activeServices count];

    [self.volumeVC viewWillAppear:NO];
}

- (void)dealloc
{
    [self.volumeVC viewWillDisappear:NO];
}

- (void)setSliderInteractionHandler:(dispatch_block_t)sliderInteractionHandler
{
    _sliderInteractionHandler = sliderInteractionHandler;
    self.volumeVC.sliderInteractionHandler = sliderInteractionHandler;
}

@end
