//
//  TRZPhotoPickerTrayViewController.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Fernando Pereira. All rights reserved.
//

@import PhotosUI;
@import AVFoundation;

#import "TRZPhotoPickerTrayViewController.h"
#import "TRZPhotoAssetCollectionViewCell.h"
#import "TRZPhotoPickerTrayActionCollectionViewCell.h"
#import "TRZPhotoPickerTrayCamPreviewCollectionViewCell.h"

#import "NSIndexSet+TRZPhotoPickerTray.h"

static CGFloat const defaultMinHeight       = 224.0;
static CGFloat const defaultImageHeight     = 100.0;
static CGFloat const defaultItemSpacing     = 4.0;
static CGFloat const defaultSectionSpacing  = 8.0;

static NSString* const cellPhotos = @"cellPhotos";
static NSString* const cellActions = @"cellActions";
static NSString* const cellOverlay = @"cellOverlay";

static NSUInteger const sectionForActions = 0;
static NSUInteger const sectionForOverlay = 1;
static NSUInteger const sectionForCameraRoll = 2;
static NSUInteger const numberOfSections = 3;


@interface TRZPhotoPickerTrayViewController () <UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDataSourcePrefetching,PHPhotoLibraryChangeObserver, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TRZPhotoPickerTrayCamPreviewCollectionViewCellDelegate>

@property (nonatomic) UIActivityIndicatorView*          activityView;
@property (nonatomic) UICollectionView*                 collectionView;
@property (nonatomic) UIVisualEffectView*               blurBackgroundView;

@property (nonatomic) CGSize                            imageSize;

@property (nonatomic) PHFetchResult*                    fetchResult;
@property (nonatomic) PHImageRequestOptions*            imageRequestOptions;
@property (nonatomic) PHCachingImageManager*            imageManager;

@end

@implementation TRZPhotoPickerTrayViewController

+ (void) createPhotoPickerTrayWithUIViewController:(nonnull UIViewController*)parentVC completion:(void ( ^ _Nullable )(TRZPhotoPickerTrayViewController  * _Nonnull  photoPicker))completion
{
    NSAssert([NSThread isMainThread], @"createPhotoPickerTray needs to be called in the main thread");
    
    CGFloat defaultHeight = MAX(CGRectGetHeight(parentVC.view.frame)/3, defaultMinHeight);
    CGRect frame = parentVC.view.frame;
    frame.origin.y = frame.size.height - defaultHeight;
    frame.size.height = defaultHeight;
    UIView* waitVW = [[UIView alloc] initWithFrame:frame];
    waitVW.backgroundColor = [UIColor clearColor];
    
    UIActivityIndicatorView* actVw = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    actVw.hidesWhenStopped = YES;
    actVw.center = waitVW.center;

    [parentVC.view addSubview:waitVW];
    [waitVW addSubview:actVw];
    waitVW.alpha = 0;

    TRZPhotoPickerTrayViewController* controller = [[TRZPhotoPickerTrayViewController alloc] initWithNibName:nil bundle:nil];
    NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^{
        [parentVC addChildViewController:controller];
        [parentVC.view addSubview:controller.view];
        [controller didMoveToParentViewController:parentVC];
        
        controller.view.translatesAutoresizingMaskIntoConstraints = NO;
        [controller.view.leadingAnchor constraintEqualToAnchor:parentVC.view.leadingAnchor].active = YES;
        [controller.view.trailingAnchor constraintEqualToAnchor:parentVC.view.trailingAnchor].active = YES;
        [controller.view.bottomAnchor constraintEqualToAnchor:parentVC.view.bottomAnchor].active = YES;
        [controller.view.heightAnchor constraintEqualToConstant:defaultHeight].active = YES;
        [controller.view setNeedsUpdateConstraints];
    }];
    operation.completionBlock =  ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [actVw stopAnimating];
            [actVw removeFromSuperview];
            [waitVW removeFromSuperview];
            if ( completion ) {
                completion(controller);
            }
        });
    };    
    [[NSOperationQueue mainQueue] addOperation:operation];
    
    [UIView animateWithDuration:0.5 animations:^{
        waitVW.alpha = 1;
    } completion:^(BOOL finished) {
        [actVw startAnimating];
    }];
}

- (void) close
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _imageSize = CGSizeMake(defaultImageHeight, defaultImageHeight);
    self.view.backgroundColor = [UIColor clearColor];
    
    UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = defaultItemSpacing;
    layout.minimumLineSpacing = defaultItemSpacing;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _blurBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurBackgroundView.frame = self.view.bounds;
    _blurBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_blurBackgroundView];
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerClass:[TRZPhotoAssetCollectionViewCell class] forCellWithReuseIdentifier:cellPhotos];
    [self.collectionView registerClass:[TRZPhotoPickerTrayActionCollectionViewCell class] forCellWithReuseIdentifier:cellActions];
    [self.collectionView registerClass:[TRZPhotoPickerTrayCamPreviewCollectionViewCell class] forCellWithReuseIdentifier:cellOverlay];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    if ( [self.collectionView respondsToSelector:@selector(prefetchDataSource)] ) {
        self.collectionView.prefetchDataSource = self;
    }
    [self.view addSubview:self.collectionView];
    
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.collectionView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    
    self.collectionView.contentInset = UIEdgeInsetsMake(4, defaultSectionSpacing, 4, defaultSectionSpacing);
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.alwaysBounceHorizontal = YES;
    
    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityView.hidesWhenStopped = YES;
    [self.view addSubview:self.activityView];
    
    self.activityView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activityView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [self.activityView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
    
    self.blurBackground = YES;
    [self.activityView startAnimating];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initalizePhotoCollection];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    if ( self.imageManager ) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

- (BOOL) allowsMultiSelection
{
    return self.collectionView.allowsMultipleSelection;
}

- (void) setAllowsMultiSelection:(BOOL)allowsMultiSelection
{
    self.collectionView.allowsMultipleSelection = allowsMultiSelection;
}

- (void) setBlurBackground:(BOOL)blurBackground
{
    if ( blurBackground && !UIAccessibilityIsReduceTransparencyEnabled() ) {
        self.blurBackgroundView.hidden = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
    } else {
        self.blurBackgroundView.hidden = YES;
        self.collectionView.backgroundColor = [UIColor lightGrayColor];
    }
}

- (BOOL) blurBackground
{
    return !self.blurBackgroundView.hidden;
}

#pragma mark -- UICollectionView Data source ---

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return numberOfSections;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ( section == sectionForCameraRoll ) {
        return self.fetchResult.count;
    } else if ( section == sectionForActions ) {
        NSInteger count = 0;
        if ( [self hasCameraAvailable] ) count++;
        if ( [self canUsePhotoLibrary] ) count++;
        return count;
    } else if ( section == sectionForOverlay ) {
        if ( [self hasCameraAvailable] ) {
            return 1;
        }
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForCameraRoll ) {
        TRZPhotoAssetCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellPhotos forIndexPath:indexPath];
        PHAsset* asset = [self.fetchResult objectAtIndex:indexPath.row];
        cell.representedAssetIdentifier = asset.localIdentifier;
        [self.imageManager requestImageForAsset:asset targetSize:self.imageSize contentMode:PHImageContentModeAspectFill options:self.imageRequestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if ( [cell.representedAssetIdentifier isEqualToString:asset.localIdentifier] ) {
                cell.image = result;
            }
        }];
        if ( [self assetNeedsToBeDownloadedFromCloud:asset] ) {
            cell.iCloud = YES;
        }
        return cell;
    } else if ( indexPath.section == sectionForOverlay ) {
        TRZPhotoPickerTrayCamPreviewCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellOverlay forIndexPath:indexPath];
        cell.photoDelegate = self;
        return cell;
    } else if ( indexPath.section == sectionForActions ) {
        TRZPhotoPickerTrayActionCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellActions forIndexPath:indexPath];
        if ( indexPath.row == 0 && [self hasCameraAvailable] ) {
            cell.type = TRZPhotoPickerTrayActionCollectionViewCellTypeCamera;
        } else if ( [self canUsePhotoLibrary] ) {
            cell.type = TRZPhotoPickerTrayActionCollectionViewCellTypePhotoLibrary;
        } else {
            NSLog(@"collectionView cell for action with invalid type");
        }
        return cell;
    }
    NSAssert(NO, @"Non handled section case in cellForItemAtIndexPath");
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    NSMutableArray* arr = [NSMutableArray new];
    for ( NSIndexPath* path in indexPaths ) {
        if ( path.section == sectionForCameraRoll ) {
            PHAsset* asset = [self.fetchResult objectAtIndex:path.row];
            [arr addObject:asset];
        }
    }
    if ( arr.count ) {
        [self.imageManager startCachingImagesForAssets:arr targetSize:self.imageSize contentMode:PHImageContentModeAspectFill options:self.imageRequestOptions];
    }
}

- (void) collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    NSMutableArray* arr = [NSMutableArray new];
    for ( NSIndexPath* path in indexPaths ) {
        if ( path.section == sectionForCameraRoll ) {
            [arr addObject:[self.fetchResult objectAtIndex:path.row]];
        }
    }
    if ( arr.count ) {
        [self.imageManager stopCachingImagesForAssets:arr targetSize:self.imageSize contentMode:PHImageContentModeAspectFill options:self.imageRequestOptions];
    }
}

#pragma mark -- UICollectionView Data delegate ---

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForActions ) {
        TRZPhotoPickerTrayActionCollectionViewCell* cell = (TRZPhotoPickerTrayActionCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        UIImagePickerController* controller = [[UIImagePickerController alloc] init];
        controller.delegate = self;
        if ( cell.type == TRZPhotoPickerTrayActionCollectionViewCellTypePhotoLibrary ) {
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else if ( cell.type == TRZPhotoPickerTrayActionCollectionViewCellTypeCamera ) {
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            NSLog(@"collectionView: didSelectItemAtIndexPath found wrong cell type for actions");
            return;
        }
        [self presentViewController:controller animated:YES completion:nil];
    } else if ( indexPath.section == sectionForCameraRoll ) {
        PHAsset* asset = [self.fetchResult objectAtIndex:indexPath.row];
        [self.delegate photoPicker:self selectedAsset:asset];
    }
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForCameraRoll ) {
        PHAsset* asset = [self.fetchResult objectAtIndex:indexPath.row];
        [self.delegate photoPicker:self willSelectedAsset:asset];
    }    
    return YES;
}

- (BOOL) collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForCameraRoll ) {
        PHAsset* asset = [self.fetchResult objectAtIndex:indexPath.row];
        [self.delegate photoPicker:self willDeSelectedAsset:asset];
    }
    return YES;
}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForCameraRoll ) {
        PHAsset* asset = [self.fetchResult objectAtIndex:indexPath.row];
        [self.delegate photoPicker:self deSelectedAsset:asset];
    }
}

#pragma mark -- Collection View Layout Delegate ----

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.section == sectionForCameraRoll ) {
        return self.imageSize;
    }
    
    CGFloat defaultHeight = CGRectGetHeight(self.view.bounds);
    if ( indexPath.section == sectionForActions ) {
        CGFloat width = MIN(CGRectGetWidth(self.view.bounds) / 3, 150);
        CGFloat height = defaultHeight / 2 - collectionView.contentInset.bottom - collectionView.contentInset.top - defaultItemSpacing;
        return CGSizeMake(width, height);
    }
    
    CGFloat width = MIN(CGRectGetWidth(self.view.bounds) / 2, 180);
    CGFloat height = defaultHeight - collectionView.contentInset.bottom - collectionView.contentInset.top - defaultItemSpacing;
    return CGSizeMake(width, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, defaultSectionSpacing);
}

#pragma mark --- Photo Assets ---

- (void) initalizePhotoCollection
{
    PHAuthorizationStatus photoAuth = [PHPhotoLibrary authorizationStatus];
    if ( photoAuth == PHAuthorizationStatusAuthorized ) {
        self.imageManager = [[PHCachingImageManager alloc] init];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    } else if ( photoAuth == PHAuthorizationStatusNotDetermined ) {
        __weak typeof(self) weakSelf = self;
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if ( status == PHAuthorizationStatusAuthorized ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.imageManager = [[PHCachingImageManager alloc] init];
                    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:weakSelf];
                });
            }
        }];
    } else {
        if ( [self.delegate respondsToSelector:@selector(photoPickerTrayShowSettingsIfNonAuthorized:)] ) {
            [self.delegate photoPickerTrayShowSettingsIfNonAuthorized:self];
        }
    }
}

- (PHImageRequestOptions*) imageRequestOptions
{
    if ( !_imageRequestOptions ) {
        _imageRequestOptions = [[PHImageRequestOptions alloc] init];
        _imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        _imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        _imageRequestOptions.synchronous = NO;
    }
    return _imageRequestOptions;
}

- (void) setImageManager:(PHCachingImageManager *)imageManager
{
    _imageManager = imageManager;
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionForCameraRoll]];
    if ( [self.activityView isAnimating] ) {
        [self.activityView stopAnimating];
    }
}

- (PHFetchResult*) fetchResult
{
    if ( !self.imageManager ) return nil;
    if ( !_fetchResult ) {
        PHFetchOptions* options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
        _fetchResult = [PHAsset fetchAssetsWithOptions:options];
    }
    return _fetchResult;
}

- (BOOL) assetNeedsToBeDownloadedFromCloud:(PHAsset*)asset
{
    __block BOOL isICloud = NO;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = YES;
    options.networkAccessAllowed = NO;
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        NSNumber* icloud = [info valueForKey:PHImageResultIsInCloudKey];
        if ( icloud.boolValue && !imageData.length ) {
            isICloud = YES;
        }
    }];
    return isICloud;
}

#pragma mark --- Photo Library ----

- (void) photoLibraryDidChange:(PHChange *)changeInstance
{
    PHFetchResultChangeDetails* changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if ( !changes ) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ( changes.hasIncrementalChanges ) {
            self.fetchResult = changes.fetchResultAfterChanges;
            [self.collectionView performBatchUpdates:^{
                NSIndexSet* removed = [changes removedIndexes];
                if ( removed.count ) {
                    [self.collectionView deleteItemsAtIndexPaths:[removed arrayOfNSIndexPathInSection:sectionForCameraRoll]];
                }
                
                NSIndexSet* inserted = [changes insertedIndexes];
                if ( inserted.count ) {
                    [self.collectionView insertItemsAtIndexPaths:[inserted arrayOfNSIndexPathInSection:sectionForCameraRoll]];
                }
                
                NSIndexSet* changed = [changes changedIndexes];
                if ( changed.count ) {
                    [self.collectionView reloadItemsAtIndexPaths:[changed arrayOfNSIndexPathInSection:sectionForCameraRoll]];
                }
                
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    NSIndexPath* from = [NSIndexPath indexPathForItem:fromIndex inSection:sectionForCameraRoll];
                    NSIndexPath* to = [NSIndexPath indexPathForItem:toIndex inSection:sectionForCameraRoll];
                    [self.collectionView moveItemAtIndexPath:from toIndexPath:to];
                }];
                
            } completion:^(BOOL finished) {
            }];
        } else {
            [self.collectionView reloadData];
        }
    });
}

#pragma mark -- UIImagePickerControllerDelegate ---

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL* assetURL = info[UIImagePickerControllerReferenceURL];
    BOOL isCameraImage = assetURL == nil;
    UIImage* image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        if ( image ) {
            if ( isCameraImage && [self.delegate respondsToSelector:@selector(photoPicker:cameraImage:)] ) {
                [self.delegate photoPicker:self cameraImage:image];
            } else {
                [self.delegate photoPicker:self image:image];
            }
        }
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark --- TRZPhotoPickerTrayCamPreviewCollectionViewCell ----

- (void) cameraPreview:(TRZPhotoPickerTrayCamPreviewCollectionViewCell *)cameraPreview image:(UIImage *)image
{
    [self.delegate photoPicker:self image:image];
}

#pragma mark --- Utilities

- (BOOL) hasCameraAvailable
{
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if ( videoStatus == AVAuthorizationStatusDenied || videoStatus == AVAuthorizationStatusRestricted || audioStatus == AVAuthorizationStatusRestricted || audioStatus == AVAuthorizationStatusDenied ) {
        return NO;
    }
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ) {
        return YES;
    }
    return NO;
}

- (BOOL) canUsePhotoLibrary
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if ( status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted ) {
        return NO;
    }
    return YES;
}

@end
