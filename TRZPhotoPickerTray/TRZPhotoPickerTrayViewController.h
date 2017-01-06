//
//  TRZPhotoPickerTrayViewController.h
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Fernando Pereira. All rights reserved.
//

@import UIKit;
@import Photos;

/**
 * Note:
 *   if photoPicker:cameraImage: is defined, it will be called if the user uses the camera UI
 *   if it's not defined, or the user uses the photo picker (builtin), or the window snapshot,
 *    photoPicker:image is used instead
 *   - the goal is to allow apps that create a custom UI to present the image to users, will be able to customize it, by implementing the optional method 
 *
 */

@class TRZPhotoPickerTrayViewController;
@protocol TRZPhotoPickerTrayViewControllerDelegate <NSObject>
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray image:(nonnull UIImage*)image;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray selectedAsset:(nonnull PHAsset*)asset;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray deSelectedAsset:(nonnull PHAsset*)asset;
@optional
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray cameraImage:(nonnull UIImage*)cameraImage;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray willSelectedAsset:(nonnull PHAsset*)asset;
- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray willDeSelectedAsset:(nonnull PHAsset*)asset;
- (void) photoPickerTrayShowSettingsIfNonAuthorized:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray;
@end

@interface TRZPhotoPickerTrayViewController : UIViewController

@property (weak, nonatomic) id<TRZPhotoPickerTrayViewControllerDelegate> _Nullable delegate;
@property (nonatomic) BOOL  allowsMultiSelection; // default - YES
@property (nonatomic) BOOL  blurBackground;  // default - YES

+ (void) createPhotoPickerTrayWithUIViewController:(nonnull UIViewController*)parentVC completion:(void ( ^ _Nullable )(TRZPhotoPickerTrayViewController  * _Nonnull  photoPicker))completion;

- (void) close;

@end
