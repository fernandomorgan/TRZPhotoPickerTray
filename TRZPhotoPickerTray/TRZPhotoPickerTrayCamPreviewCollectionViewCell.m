//
//  TRZPhotoPickerTrayCamPreviewCollectionViewCell.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "TRZPhotoPickerTrayCamPreviewCollectionViewCell.h"
#import "TRZCameraPreviewView.h"
#import "TRZShutterControl.h"

static CGFloat const flipSide = 44.0;
static CGFloat const shutterSide = 29.0;

@interface TRZPhotoPickerTrayCamPreviewCollectionViewCell ()

@property (nonatomic) TRZCameraPreviewView* previewView;
@property (nonatomic) UIButton*             flipButton;
@property (nonatomic) TRZShutterControl*    takePick;

@property (nonatomic) BOOL                  flipped;

@end

@implementation TRZPhotoPickerTrayCamPreviewCollectionViewCell

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
    self.contentView.layer.cornerRadius = 10.0;
    self.contentView.layer.masksToBounds = YES;
    
    _previewView = [[TRZCameraPreviewView alloc] initWithFrame:frame];
    [self.contentView addSubview:_previewView];
    
    _flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* flipImage = [UIImage imageNamed:@"cameraFlip" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    [_flipButton setImage:flipImage forState:UIControlStateNormal];
    [_flipButton addTarget:self action:@selector(flipCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_flipButton];

    _takePick = [[TRZShutterControl alloc] initWithFrame:CGRectZero];
    [_takePick addTarget:self action:@selector(takePicture) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_takePick];
    
    _flipped = NO;
    [self.previewView initializeCamera];
}

- (void) willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
    if ( [subview isKindOfClass:[TRZCameraPreviewView class]] ) {
        TRZCameraPreviewView* vw = (TRZCameraPreviewView*)subview;
        [vw stopCapturingVideo];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.previewView.frame = self.contentView.frame;
    
    CGFloat flipX = CGRectGetMaxX(self.contentView.bounds) - flipSide;
    CGFloat flipY = CGRectGetMinY(self.contentView.bounds);
    self.flipButton.frame = CGRectMake(flipX, flipY, flipSide, flipSide);
    
    CGFloat takX = CGRectGetMidX(self.contentView.bounds) - shutterSide / 2;
    CGFloat takY = CGRectGetMaxY(self.contentView.bounds) - shutterSide - 4;
    self.takePick.frame = CGRectMake(takX, takY, shutterSide, shutterSide);
}

- (void) flipCamera
{
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithFrame:_previewView.bounds];
    blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    [self.previewView addSubview:blurView];
    [UIView transitionWithView:self.previewView
                      duration:0.6
                       options:(self.flipped?UIViewAnimationOptionTransitionFlipFromLeft:UIViewAnimationOptionTransitionFlipFromRight)
                    animations:^{
                        [self.previewView flipCamera];
                    }
                    completion:^(BOOL finished) {
                        [blurView removeFromSuperview];
                        self.flipped = !self.flipped;
    }];
}

- (void) takePicture
{
    __weak typeof(self) weakSelf = self;
    [self.previewView captureCameraStillImage:^(UIImage * _Nullable photo) {
        [weakSelf.photoDelegate cameraPreview:weakSelf image:photo];
    }];
}

@end
