//
//  ViewController.m
//  AvCaptureRecord
//
//  Created by D.K. Willardson on 10/5/17.
//  Copyright © 2017 Hitting Tech. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureDevice *videoDevice;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceFormat *bestFormat;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic,strong)NSMutableArray *saveImages;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])        //Check size based configs are supported before setting them
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    // Retrieve the back camera
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *captureDevice;
    for (AVCaptureDevice *device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            if (device.position == AVCaptureDevicePositionBack)
            {
                captureDevice = device;
                break;
            }
        }
    }
    
    NSError *error;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
    [self.captureSession addInput:input];
    
    if (error)
    {
        NSLog(@"%@", error);
    }
    
    // Find the max frame rate we can get from the given device
    int32_t maxWidth = 0;
    
    AVCaptureDeviceFormat *currentFormat;
    for (AVCaptureDeviceFormat *format in captureDevice.formats)
    {
        NSArray *ranges = format.videoSupportedFrameRateRanges;
        AVFrameRateRange *frameRates = ranges[0];
        CMFormatDescriptionRef desc = format.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
        int32_t width = dimensions.width;
        
     
        if (frameRates.maxFrameRate == CAPTURE_FRAMES_PER_SECOND)
        {
           currentFormat = format;
           maxWidth = width;
        }
    }
    
    // Tell the device to use the max frame rate.
    [captureDevice lockForConfiguration:nil];
    captureDevice.torchMode=AVCaptureTorchModeOn;
    captureDevice.activeFormat = currentFormat;
    captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
   // [captureDevice setVideoZoomFactor:1];
    [captureDevice unlockForConfiguration];
    
    // Set the output
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self.captureSession addOutput:self.movieFileOutput];
    
    //SET THE CONNECTION PROPERTIES (output properties)
    [self CameraSetOutputProperties];            //(We call a method as it also
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession] ];
    
    _previewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;
    
    //----- DISPLAY THE PREVIEW LAYER -----
    NSLog(@"Display the preview layer");
    CGRect layerRect = [[[self view] layer] bounds];
    [_previewLayer setBounds:layerRect];
    [_previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                           CGRectGetMidY(layerRect))];
    
    UIView *CameraView = [[UIView alloc] init] ;
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:_previewLayer];
    
    // Start the video session
    [self.captureSession startRunning];
}

//********** VIEW WILL APPEAR **********
//View about to be added to the window (called each time it appears)
//Occurs after other view's viewWillDisappear
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    WeAreRecording = NO;
}

//********** CAMERA SET OUTPUT PROPERTIES **********
- (void) CameraSetOutputProperties
{
    //SET THE CONNECTION PROPERTIES (output properties)
    AVCaptureConnection *CaptureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([CaptureConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;        //<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [CaptureConnection setVideoOrientation:orientation];
    }
    
    
}



    //********** START STOP RECORDING BUTTON **********
    - (IBAction)StartStopButtonPressed:(id)sender
    {
        
        if (!WeAreRecording)
        {
            ///*
            //----- START RECORDING -----
            NSLog(@"START RECORDING");
            WeAreRecording = YES;
            
            
                    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
                    self.fileURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    if ([fileManager fileExistsAtPath:outputPath])
                    {
                        NSError *error;
                        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
                        {
                            //Error - handle if requried
                        }
                    }
           
            //Start recording
            [_movieFileOutput startRecordingToOutputFileURL:self.fileURL recordingDelegate:self];
           
            
         }
         else
        {
        //----- STOP RECORDING -----
            NSLog(@"STOP RECORDING");
            WeAreRecording = NO;
            
            [_movieFileOutput stopRecording];
                       
            dispatch_async(dispatch_get_main_queue(), ^{

                if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
                    [self.delegate didFinishRecordingToOutputFileAtURL:self.fileURL error:nil];
                }
            });
       }
  }
////********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
    
    BOOL RecordedSuccessfully = YES;
    
    AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:self.fileURL options:nil];
    
    AVAssetTrack * videoAssetTrack = [movieAsset tracksWithMediaType: AVMediaTypeVideo].firstObject;
    NSLog(@"FPS is  : %f ", videoAssetTrack.nominalFrameRate);
    
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        //----- RECORDED SUCESSFULLY -----
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
        {
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 if (error)
                 {

                 }
             }];
        }

        // [library release];

    }

    [self processBuffer];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationLandscapeLeft);
}


-(void)getLastImage{
    UIImage *image1 = [_saveImages objectAtIndex:0];
    UIImage *image2 = [_saveImages objectAtIndex:1];
    UIImage *image3 = [_saveImages objectAtIndex:2];
    UIImage *image4 = [_saveImages objectAtIndex:3];
    UIImage *image5 = [_saveImages objectAtIndex:4];
}

-(void)processBuffer{
    
    
    // NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
   // NSURL *movieUrl=[[NSURL alloc] initFileURLWithPath:filePathString];
    AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:_fileURL options:nil];
    
    AVAssetTrack * videoAssetTrack = [movieAsset tracksWithMediaType: AVMediaTypeVideo].firstObject;
    NSLog(@"FPS is  : %f ", videoAssetTrack.nominalFrameRate);
    
    _saveImages = [[NSMutableArray alloc]init];
    
    
    AVAssetImageGenerator *generate = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    generate.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime videoDuration = movieAsset.duration;
    float videoDurationSeconds = CMTimeGetSeconds(videoDuration);
    int frames=(int)videoDurationSeconds*CAPTURE_FRAMES_PER_SECOND;
    // float lastFrameTime = CMTimeGetSeconds(movieAsset.duration)*60.0;
    
    generate.requestedTimeToleranceBefore = kCMTimeZero;
    generate.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSMutableArray *timesm=[[NSMutableArray alloc]init];
    for (int i=(frames-5); i<frames; i++) {
        CMTime time = CMTimeMakeWithSeconds(videoDurationSeconds *i/(float)frames, frames);
        // CMTime time = CMTimeMake(videoDurationSeconds *i/(float)frames, frames);
        
        [timesm addObject:[NSValue valueWithCMTime:time]];
        
    }
    
    
    
    [generate generateCGImagesAsynchronouslyForTimes:timesm
                                   completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                       
                                       UIImage* myImage = [[UIImage alloc] initWithCGImage:image];
                                       
                                       [self.saveImages addObject:myImage]; // ADDED THIS LINE
                                       
                                       if(_saveImages.count == 5)
                                       {
                                           [self getLastImage];
                                       }
                                       
                                       
                                       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                       NSString *documentsDirectory = [paths objectAtIndex:0];
                                       NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ankur-%@ %i.jpg",image,(int)[[NSDate date] timeIntervalSince1970]]];
                                       NSData *imageData = UIImageJPEGRepresentation(myImage,0.7);
                                       [imageData writeToFile:savedImagePath atomically:NO];
                                       
                                       
                                       NSString *requestedTimeString = (NSString *)
                                       
                                       CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
                                       
                                       NSString *actualTimeString = (NSString *)
                                       
                                       CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
                                       
                                       NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
                                       
                                       if (result == AVAssetImageGeneratorSucceeded) {
                                           
                                           // Do something interesting with the image.
                                       }
                                       
                                       
                                       if (result == AVAssetImageGeneratorFailed) {
                                           
                                           NSLog(@"Failed with error: %@", [error localizedDescription]);
                                       }
                                       
                                       if (result == AVAssetImageGeneratorCancelled) {
                                           
                                           NSLog(@"Canceled");
                                           
                                       }
                                       
                                   }];
    
    
    
}


@end

