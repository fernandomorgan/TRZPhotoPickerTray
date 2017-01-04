//
//  TRZPhotoPickerTrayActionCollectionViewCell.h
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, TRZPhotoPickerTrayActionCollectionViewCellType) {
    TRZPhotoPickerTrayActionCollectionViewCellTypeNone,
    TRZPhotoPickerTrayActionCollectionViewCellTypeCamera,
    TRZPhotoPickerTrayActionCollectionViewCellTypePhotoLibrary,
};

@interface TRZPhotoPickerTrayActionCollectionViewCell : UICollectionViewCell

@property (nonatomic) TRZPhotoPickerTrayActionCollectionViewCellType    type;

@end
