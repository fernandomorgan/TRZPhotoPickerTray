# TRZPhotoPickerTray
Photo/Camera picker inspired in iMessages 10 for iOS

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Sample Usage:

        [TRZPhotoPickerTrayViewController createPhotoPickerTrayWithUIViewController:self completion:^(TRZPhotoPickerTrayViewController * _Nonnull photoPicker) {
            self.photoPicker = photoPicker;
            self.photoPicker.delegate = self;
            self.photoPicker.allowsMultiSelection = YES;
        }];
