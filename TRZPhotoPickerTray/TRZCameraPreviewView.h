//
//  TRZCameraPreviewView.h
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

@import UIKit;

@interface TRZCameraPreviewView : UIView
- (nonnull instancetype) initWithFrame:(CGRect)frame;
- (void) initializeCamera;
- (void) flipCamera;
- (void) captureCameraStillImage:(void ( ^ _Nullable )(UIImage  * _Nullable photo))callback;
- (void) startCapturingVideo;
- (void) stopCapturingVideo;
@end
