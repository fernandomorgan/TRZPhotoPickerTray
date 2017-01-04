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

- (void) photoPicker:(TRZPhotoPickerTrayViewController *)photoPickerTray image:(UIImage *)image
{
    NSLog(@"photoPicker picked image size=%f,%f", image.size.width, image.size.height);
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray selectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker selected asset = %@", asset.description);
}

- (void) photoPicker:(nonnull TRZPhotoPickerTrayViewController*)photoPickerTray deSelectedAsset:(nonnull PHAsset*)asset
{
    NSLog(@"photoPicker DESelected asset = %@", asset.description);
}

@end
