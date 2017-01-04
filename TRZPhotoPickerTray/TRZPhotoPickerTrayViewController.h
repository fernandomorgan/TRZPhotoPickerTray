//
//  TRZPhotoPickerTrayViewController.h
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Fernando Pereira. All rights reserved.
//

@import UIKit;
@import Photos;

@class TRZPhotoPickerTrayViewController;
@protocol TRZPhotoPickerTrayViewControllerDelegate <NSObject>
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray image:(nonnull UIImage*)image;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray selectedAsset:(nonnull PHAsset*)asset;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray deSelectedAsset:(nonnull PHAsset*)asset;
@optional
- (void) photoPickerTrayShowSettingsIfNonAuthorized:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray;
@end

@interface TRZPhotoPickerTrayViewController : UIViewController

@property (weak, nonatomic) id<TRZPhotoPickerTrayViewControllerDelegate> _Nullable delegate;
@property (nonatomic) BOOL  allowsMultiSelection;

+ (void) createPhotoPickerTrayWithUIViewController:(nonnull UIViewController*)parentVC completion:(void ( ^ _Nullable )(TRZPhotoPickerTrayViewController  * _Nonnull  photoPicker))completion;

- (void) close;

@end
