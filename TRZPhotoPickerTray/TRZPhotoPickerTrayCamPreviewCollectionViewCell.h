//
//  TRZPhotoPickerTrayCamPreviewCollectionViewCell.h
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

@import UIKit;

@class TRZPhotoPickerTrayCamPreviewCollectionViewCell;
@protocol TRZPhotoPickerTrayCamPreviewCollectionViewCellDelegate <NSObject>
- (void) cameraPreview:(nonnull TRZPhotoPickerTrayCamPreviewCollectionViewCell*)cameraPreview image:(nonnull UIImage*)image;
@end

@interface TRZPhotoPickerTrayCamPreviewCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) id<TRZPhotoPickerTrayCamPreviewCollectionViewCellDelegate> _Nullable photoDelegate;
@end



