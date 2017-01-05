//
//  ViewController.m
//  TRZPhotoPickerTrayExample
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

#import "ViewController.h"

@import TRZPhotoPickerTray;

@interface ViewController () <TRZPhotoPickerTrayViewControllerDelegate>

@property (weak,nonatomic) TRZPhotoPickerTrayViewController* photoPicker;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) NSNumber* currentlyLoadingAssetID;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)imagesTray:(id)sender
{
    static BOOL hidden = YES;
    if ( hidden ) {
        hidden = NO;
        [TRZPhotoPickerTrayViewController createPhotoPickerTrayWithUIViewController:self completion:^(TRZPhotoPickerTrayViewController * _Nonnull photoPicker) {
            self.photoPicker = photoPicker;
            self.photoPicker.delegate = self;
            self.photoPicker.allowsMultiSelection = YES;
        }];
    } else {
        [self.photoPicker close];
        hidden = YES;
    }
}

- (void) loadAsset:(PHAsset*)asset
{
    if ( self.currentlyLoadingAssetID ) {
        [[PHImageManager defaultManager] cancelImageRequest:self.currentlyLoadingAssetID.intValue];
    }
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    [options setSynchronous:NO];
    [options setResizeMode:PHImageRequestOptionsResizeModeExact];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    [options setVersion:PHImageRequestOptionsVersionCurrent];
    
    __weak typeof(self) weakSelf = self;
    PHImageRequestID thumbReqID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        weakSelf.currentlyLoadingAssetID = nil;
        weakSelf.imageView.image = image;
    }];
    self.currentlyLoadingAssetID = [NSNumber numberWithInt:thumbReqID];
}

- (void) photoPicker:(TRZPhotoPickerTrayViewController *)photoPickerTray image:(UIImage *)image
{
    NSLog(@"photoPicker picked image size=%f,%f", image.size.width, image.size.height);
    
    self.imageView.image = image;
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray selectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker selected asset = %@", asset.description);
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray deSelectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker DESelected asset = %@", asset.description);
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray cameraImage:(nonnull UIImage*)cameraImage
{
    NSLog(@"photoPicker Camera image size=%f,%f", cameraImage.size.width, cameraImage.size.height);
    self.imageView.image = cameraImage;
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray willSelectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker WILL Selected asset = %@", asset.description);
    [self loadAsset:asset];
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray willDeSelectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker WILL DESelected asset = %@", asset.description);
}


@end
