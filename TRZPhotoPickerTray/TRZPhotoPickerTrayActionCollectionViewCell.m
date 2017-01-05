//
//  TRZPhotoPickerTrayActionCollectionViewCell.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "TRZPhotoPickerTrayActionCollectionViewCell.h"

static CGFloat const labelFontSize = 14.0;
static CGFloat const intervalBetweenLabelAndImage = 2.0;
static CGFloat const marginHorizForView = 8.0;
static CGFloat const marginVertForView = 12.0;

@interface TRZPhotoPickerTrayActionCollectionViewCell ()

@property (nonatomic) UIView*       view;
@property (nonatomic) UIImageView*  imageView;
@property (nonatomic) UILabel*      label;

@end

@implementation TRZPhotoPickerTrayActionCollectionViewCell

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
        [self calculateViewsFrame];
    }
    return self;
}

- (void) commonInitializer:(CGRect)frame
{
    self.contentView.backgroundColor = [UIColor clearColor];
    
    _view = [[UIView alloc] initWithFrame:CGRectZero];
    _view.backgroundColor = [UIColor whiteColor];
    _view.layer.cornerRadius = 10.0;
    _view.layer.masksToBounds = YES;
    [self.contentView addSubview:_view];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imageView.contentMode = UIViewContentModeCenter;
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
    
    _label = [[UILabel alloc] initWithFrame:CGRectZero];
    _label.numberOfLines = 0;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.backgroundColor = [UIColor clearColor];
    _label.font = [UIFont systemFontOfSize:labelFontSize];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.label];
    
    self.type = TRZPhotoPickerTrayActionCollectionViewCellTypeNone;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self calculateViewsFrame];
}

- (void) calculateViewsFrame
{
    CGFloat labelHeight = labelFontSize + 2;
    
    CGRect frame = self.contentView.frame;
    frame.size.height -= marginVertForView * 2;
    frame.size.width -= marginHorizForView * 2;
    frame.origin.y += marginVertForView;
    frame.origin.x += marginHorizForView;
    self.view.frame = frame;
    
    frame.size.height -= intervalBetweenLabelAndImage + labelHeight;
    self.imageView.frame = frame;
    
    frame.origin.y = frame.size.height;
    frame.size.height = labelHeight;
    self.label.frame = frame;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    self.type = TRZPhotoPickerTrayActionCollectionViewCellTypeNone;
    self.imageView.image = nil;
}

- (void) setType:(TRZPhotoPickerTrayActionCollectionViewCellType)type
{
    _type = type;    
    if ( type == TRZPhotoPickerTrayActionCollectionViewCellTypePhotoLibrary ) {
        self.label.text = [self labelForPhotoLibrary];
        self.imageView.image = [UIImage imageNamed:@"photoLibrary" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    } else if ( type == TRZPhotoPickerTrayActionCollectionViewCellTypeCamera ) {
        self.label.text = [self labelForCamera];
        self.imageView.image = [UIImage imageNamed:@"camera" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    }
}

- (NSString*) labelForPhotoLibrary
{
    static NSString *text = nil;
    if ( !text.length ) {
        text = NSLocalizedStringWithDefaultValue(@"actionCell.photoLib", nil, [NSBundle mainBundle],
                                                 @"Photo Library",
                                                 @"Title for Photo Library");
    }
    return text;
}

- (NSString*) labelForCamera
{
    static NSString *text = nil;
    if ( !text.length ) {
        text = NSLocalizedStringWithDefaultValue(@"actionCell.camera", nil, [NSBundle mainBundle],
                                                 @"Camera",
                                                 @"Title for Camera");
    }
    return text;
}

@end
