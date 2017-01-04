//
//  TRZCameraPreviewView.m
//  TRZPhotoPickerTray
//
//  Created by Fernando Pereira on 1/3/17.
//  Copyright © 2017 Troezen. All rights reserved.
//

@import AVFoundation;

#import "TRZCameraPreviewView.h"

@interface TRZCameraPreviewView ()

@property (nonatomic) dispatch_queue_t                  captureSessionQueue;

@property (nonatomic) AVCaptureDeviceDiscoverySession*  videoDeviceDiscoverySession;
@property (nonatomic) AVCaptureDeviceInput*             videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput*        photoOutput;

@end

@implementation TRZCameraPreviewView

- (nonnull instancetype) initWithFrame:(CGRect)frame
{
    if ( self = [super initWithFrame:frame] ) {
        _captureSessionQueue = dispatch_queue_create( "photoPickerTray.captureImage", DISPATCH_QUEUE_SERIAL );
        self.session = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (void) dealloc
{
}

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
}

#pragma mark --- AV capture

- (void) initializeCamera
{
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend( self.captureSessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                dispatch_resume( self.captureSessionQueue );
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:
        default:
            break;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( self.captureSessionQueue, ^{
        AVAuthorizationStatus auth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if ( auth != AVAuthorizationStatusAuthorized ) return;
        
        BOOL result = [weakSelf initalizeCameraCapture];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( !result ) {
                //weakSelf.cameraFlipButton.hidden = YES;
            }
        });
        if ( result ) {
            [weakSelf startCapturingVideo];
        } else {
            //[weakSelf configureButtonsForCameraCaptureMode:NO];
        }
    } );
}

- (BOOL) initalizeCameraCapture
{
#if (TARGET_OS_SIMULATOR)
    return NO;
#else
    AVCaptureDevice *videoDevice;
    if ( [self iOS10Minimum] ) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                         mediaType:AVMediaTypeVideo
                                                          position:AVCaptureDevicePositionFront];
        
        if ( !videoDevice ) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDuoCamera
                                                             mediaType:AVMediaTypeVideo
                                                              position:AVCaptureDevicePositionBack];
        }
        if ( !videoDevice ) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                             mediaType:AVMediaTypeVideo
                                                              position:AVCaptureDevicePositionBack];
        }
    } else {
        videoDevice = [self legacyDevice:AVCaptureDevicePositionFront];
        if ( !videoDevice ) {
            videoDevice = [self legacyDevice:AVCaptureDevicePositionBack];
        }
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if ( error ) {
        NSLog(@"initalizeCameraCapture error:%@", error);
    }
    if ( ! videoDeviceInput ) {
        return NO;
    }
    
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    if ( [self.session canAddInput:videoDeviceInput] ) {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
        dispatch_async( dispatch_get_main_queue(), ^{
            self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            self.videoPreviewLayer.frame = self.frame;
        } );
    } else {
        [self.session commitConfiguration];
        return NO;
    }
    // Add photo output.
    AVCaptureStillImageOutput *photoOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [photoOutput setOutputSettings:outputSettings];
    if ( [self.session canAddOutput:photoOutput] ) {
        [self.session addOutput:photoOutput];
        self.photoOutput = photoOutput;
    }
    else {
        [self.session commitConfiguration];
        return NO;
    }
    
    [self.session commitConfiguration];
    return YES;
#endif
}

- (void) startCapturingVideo
{
#if !(TARGET_OS_SIMULATOR)
    __weak typeof(self) weakSelf = self;
    dispatch_async( self.captureSessionQueue, ^{
        if ( ![weakSelf.session isRunning] ) {
            [weakSelf.session startRunning];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[weakSelf configureButtonsForCameraCaptureMode:YES];
            });
        }
    });
#endif
}

- (void) stopCapturingVideo
{
#if !(TARGET_OS_SIMULATOR)
    __weak typeof(self) weakSelf = self;
    dispatch_async( self.captureSessionQueue, ^{
        if ( [weakSelf.session isRunning] ) {
            [weakSelf.session stopRunning];
            dispatch_async(dispatch_get_main_queue(), ^{
                //[weakSelf configureButtonsForCameraCaptureMode:NO];
            });
        }
    });
#endif
}

- (void) flipCamera
{
    __weak typeof(self) weakSelf = self;
    dispatch_async( self.captureSessionQueue, ^{
        if ( !weakSelf ) return;
        AVCaptureDevice *currentVideoDevice = weakSelf.videoDeviceInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        AVCaptureDevicePosition preferredPosition;
        AVCaptureDeviceType preferredDeviceType;
        AVCaptureDevice *newVideoDevice = nil;
        switch ( currentPosition )
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                if ( [self iOS10Minimum] ) {
                    preferredDeviceType = AVCaptureDeviceTypeBuiltInDuoCamera;
                }
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                if ( [self iOS10Minimum] ) {
                    preferredDeviceType = AVCaptureDeviceTypeBuiltInWideAngleCamera;
                }
                break;
        }
        
        if ( [self iOS10Minimum] && preferredDeviceType ) {
            NSArray<AVCaptureDevice *> *devices = weakSelf.videoDeviceDiscoverySession.devices;
            for ( AVCaptureDevice *device in devices ) {
                if ( device.position == preferredPosition && [device.deviceType isEqualToString:preferredDeviceType] ) {
                    newVideoDevice = device;
                    break;
                }
            }
            if ( ! newVideoDevice ) {
                for ( AVCaptureDevice *device in devices ) {
                    if ( device.position == preferredPosition ) {
                        newVideoDevice = device;
                        break;
                    }
                }
            }
        } else {
            newVideoDevice = [weakSelf legacyDevice:preferredPosition];
        }
                
        [weakSelf changeCameraDevice:newVideoDevice];
    } );
}

- (void) changeCameraDevice:(AVCaptureDevice*)newVideoDevice
{
    if ( !newVideoDevice ) return;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:NULL];
    [self.session beginConfiguration];
    if ( self.videoDeviceInput ) {
        [self.session removeInput:self.videoDeviceInput];
    }
    if ( [self.session canAddInput:videoDeviceInput] ) {
        [self.session addInput:videoDeviceInput];
        self.videoDeviceInput = videoDeviceInput;
    } else if ( self.videoDeviceInput ) {
        [self.session addInput:self.videoDeviceInput];
    }
    [self.session commitConfiguration];
}

- (AVCaptureDeviceDiscoverySession*) videoDeviceDiscoverySession
{
    if ( !_videoDeviceDiscoverySession ) {
#if !(TARGET_OS_SIMULATOR)
        if ( [self iOS10Minimum] ) {
            NSArray<AVCaptureDeviceType> *deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDuoCamera];
            _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                                                  mediaType:AVMediaTypeVideo
                                                                                                   position:AVCaptureDevicePositionUnspecified];
        } else {
            NSMutableArray* arr = [NSMutableArray new];
            for ( AVCaptureDevice* device in [AVCaptureDevice devices] ) {
                if ( [device hasMediaType:AVMediaTypeVideo] ) {
                    [arr addObject:device];
                }
            }
            _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:arr
                                                                                                  mediaType:AVMediaTypeVideo
                                                                                                   position:AVCaptureDevicePositionUnspecified];
        }
#else
        NSArray<AVCaptureDeviceType> *deviceTypes = @[];
        _videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes
                                                                                              mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
#endif
    }
    return _videoDeviceDiscoverySession;
}


- (AVCaptureDevice*) legacyDevice:(AVCaptureDevicePosition)position
{
    AVCaptureDevice* found;
    for ( AVCaptureDevice* device in [AVCaptureDevice devices] ) {
        if ( [device hasMediaType:AVMediaTypeVideo] && device.position == position ) {
            found = device;
            break;
        }
    }
    return found;
}

- (BOOL) iOS10Minimum
{
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]) {
        NSOperatingSystemVersion osToTest;
        osToTest.majorVersion = 10;
        osToTest.minorVersion = 0;
        osToTest.patchVersion = 1;
        if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: osToTest] ) {
            return YES;
        }
    }
    return NO;
}

- (AVCaptureConnection*) getCurrentConnection
{
    for (AVCaptureConnection* connection in self.photoOutput.connections) {
        for (AVCaptureInputPort* port in connection.inputPorts) {
            if ( [port.mediaType isEqualToString:AVMediaTypeVideo] ) {
                return connection;
            }
        }
    }
    return nil;
}

- (void) captureCameraStillImage:(void ( ^ _Nullable )(UIImage  * _Nullable photo))callback
{
    AVCaptureConnection* connection = [self getCurrentConnection];
    if ( !connection ) {
        NSLog(@"captureCameraStillImage: there is no current video capture");
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.photoOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if ( error ) {
            NSLog(@"captureCameraStillImage error in captureStillImageAsynchronouslyFromConnection:%@", error);
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        if (!imageData.length) {
            NSLog(@"captureCameraStillImage error in captureStillImageAsynchronouslyFromConnection - no data");
            return;
        }
        if ( !weakSelf ) return;
        UIImage* image = [UIImage imageWithData:imageData];
        dispatch_async(self.captureSessionQueue, ^{
            AVCaptureInput *currentCameraInput = [weakSelf.session.inputs objectAtIndex:0];
            if ( !callback ) return;
            if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
                UIImage* flippedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationRight];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(flippedImage);
                });
            } else {
                UIImage* flippedImage = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(flippedImage);
                });
            }
        });
    }];
}


@end
