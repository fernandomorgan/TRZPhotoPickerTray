//
//  TRZPhotoAssetCollectionViewCell.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "TRZPhotoAssetCollectionViewCell.h"

static CGFloat const cloudInset = 10;

@interface TRZPhotoAssetCollectionViewCell ()
@property (nonatomic) UIImageView*  imageView;
@property (nonatomic) UIImageView*  selectedCheckMark;
@property (nonatomic) UIImageView*  icloudView;
@end

@implementation TRZPhotoAssetCollectionViewCell

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super initWithCoder:aDecoder]) {
        [self commonInitializer:CGRectZero];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame]) {
        [self commonInitializer:frame];
    }
    return self;
}

- (void) commonInitializer:(CGRect)frame
{
    _representedAssetIdentifier = @"";
    _iCloud = NO;
    
    _imageView = [[UIImageView alloc] initWithFrame:frame];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.layer.cornerRadius = 10.0;
    _imageView.layer.masksToBounds = YES;
    [self.contentView addSubview:_imageView];
    
    _icloudView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil]];
    _icloudView.clipsToBounds = YES;
    _icloudView.hidden = YES;
    _icloudView.alpha = 0.7;
    [self.contentView addSubview:_icloudView];

    UIImage* image = [UIImage imageNamed:@"deSelected" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    _selectedCheckMark = [[UIImageView alloc] initWithImage:image];
    _selectedCheckMark.contentMode = UIViewContentModeCenter;
    [self.contentView addSubview:_selectedCheckMark];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.contentView.frame;
    
    CGFloat x = CGRectGetMaxX(self.contentView.bounds) - self.selectedCheckMark.frame.size.width / 2 - 4;
    CGFloat y = CGRectGetMaxY(self.contentView.bounds) - self.selectedCheckMark.frame.size.height / 2 - 4;
    self.selectedCheckMark.center = CGPointMake(x, y);

    CGRect frame = self.icloudView.frame;
    frame.origin.x = cloudInset;
    frame.origin.y = CGRectGetMaxY(self.contentView.bounds) - cloudInset  - CGRectGetHeight(frame);
    self.icloudView.frame = frame;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
    self.icloudView.hidden = YES;
    self.representedAssetIdentifier = @"";
}

- (void) setICloud:(BOOL)iCloud
{
    _iCloud = iCloud;
    if ( iCloud ) {
        self.icloudView.hidden = NO;;
    }
}

- (void) setImage:(UIImage *)image
{
    self.imageView.image = image;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    UIImage* image;
    if ( selected ) {
        image = [UIImage imageNamed:@"selected" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    } else {
        image = [UIImage imageNamed:@"deSelected" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
    self.selectedCheckMark.image = image;
}

@end
