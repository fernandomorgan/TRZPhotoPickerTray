# TRZPhotoPickerTray
Photo/Camera picker inspired in iMessages 10 for iOS


Sample Usage:

        [TRZPhotoPickerTrayViewController createPhotoPickerTrayWithUIViewController:self completion:^(TRZPhotoPickerTrayViewController * _Nonnull photoPicker) {
            self.photoPicker = photoPicker;
            self.photoPicker.delegate = self;
            self.photoPicker.allowsMultiSelection = YES;
        }];
