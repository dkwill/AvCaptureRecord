//
//  ViewController.m
//  AvCaptureRecord
//
//  Created by D.K. Willardson on 10/5/17.
//  Copyright © 2017 Hitting Tech. All rights reserved.
//


#import "ViewController.h"


@interface ViewController()<AVCaptureFileOutputRecordingDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;

@property (nonatomic,strong)NSMutableArray *saveImages;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@end


@implementation ViewController


//********** VIEW DID LOAD **********
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.saveImages = [[NSMutableArray alloc]init];
    
    //---------------------------------
    //----- SETUP CAPTURE SESSION -----
    //---------------------------------
     NSError *error;
    
    NSLog(@"Setting up capture session");
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
    
    self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
    
    if (error) {
        NSLog(@"Video input creation failed");
      //  return nil;
    }
    
    if (![self.captureSession canAddInput:videoIn]) {
        NSLog(@"Video input add-to-session failed");
       // return nil;
    }
    [self.captureSession addInput:videoIn];
    
    
    CMTime defaultVideoMinFrameDuration;
    // save the default format
    self.defaultFormat = self.videoDevice.activeFormat;
    defaultVideoMinFrameDuration = self.videoDevice.activeVideoMinFrameDuration;
    
    //set output mode?
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self.captureSession addOutput:self.movieFileOutput];
    
    //----- ADD INPUTS -----
    NSLog(@"Adding video input");
    
    
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= CAPTURE_FRAMES_PER_SECOND && CAPTURE_FRAMES_PER_SECOND <= range.maxFrameRate && width >= maxWidth) {
                
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    //ADD VIDEO INPUT
   // AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    BOOL isFPSSupported = NO;
    AVCaptureDeviceFormat *currentFormat = [self.videoDevice activeFormat];
    for ( AVFrameRateRange *range in currentFormat.videoSupportedFrameRateRanges ) {
        if ( range.maxFrameRate >= CAPTURE_FRAMES_PER_SECOND && range.minFrameRate <= CAPTURE_FRAMES_PER_SECOND )        {
            isFPSSupported = YES;
            break;
        }
    }

    if( isFPSSupported ) {
        if ( [self.videoDevice lockForConfiguration:NULL] ) {
            self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake( 1, CAPTURE_FRAMES_PER_SECOND );
            self.videoDevice.activeVideoMinFrameDuration = CMTimeMake( 1, CAPTURE_FRAMES_PER_SECOND );
            [self.videoDevice unlockForConfiguration];
        }
    }
//
//    if([VideoDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
//        [VideoDevice lockForConfiguration:nil];
//        //configure frame rate
//        [VideoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
//        [VideoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
//        [VideoDevice setTorchMode:AVCaptureTorchModeOn]; // Change to "if necessary"
//        [VideoDevice unlockForConfiguration];
//    }
    
//    if (VideoDevice)
//    {
//        NSError *error;
//        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
//        if (!error)
//        {
//            if ([CaptureSession canAddInput:VideoInputDevice])
//                [CaptureSession addInput:VideoInputDevice];
//            else
//                NSLog(@"Couldn't add video input");
//        }
//        else
//        {
//            NSLog(@"Couldn't create video input");
//        }
//    }
//    else
//    {
//        NSLog(@"Couldn't create video capture device");
//    }
 
    //CGFloat desiredFps = 240;;
    //[self.captureManager switchFormatWithDesiredFPS:desiredFps];
 
    //ADD AUDIO INPUT
//    NSLog(@"Adding audio input");
//    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//   // NSError *error = nil;
//    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
//    if (audioInput)
//    {
//        [CaptureSession addInput:audioInput];
//    }
//*/
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession] ];
    
    _PreviewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;        //SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
  //  [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    //ADD MOVIE FILE OUTPUT
    NSLog(@"Adding movie file output");
    //self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;            //Total seconds
    int32_t preferredTimeScale = CAPTURE_FRAMES_PER_SECOND;    //Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);    //SET MAX DURATION
    self.movieFileOutput.maxRecordedDuration = maxDuration;
    
    self.movieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;                        //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([self.captureSession canAddOutput:_movieFileOutput])
        [self.captureSession addOutput:_movieFileOutput];
    
    //SET THE CONNECTION PROPERTIES (output properties)
    [self CameraSetOutputProperties];            //(We call a method as it also has to be done after changing camera)
    
    
    
    //----- SET THE IMAGE QUALITY / RESOLUTION -----
    //Options:
    //    AVCaptureSessionPresetHigh - Highest recording quality (varies per device)
    //    AVCaptureSessionPresetMedium - Suitable for WiFi sharing (actual values may change)
    //    AVCaptureSessionPresetLow - Suitable for 3G sharing (actual values may change)
    //    AVCaptureSessionPreset640x480 - 640x480 VGA (check its supported before setting it)
    //    AVCaptureSessionPreset1280x720 - 1280x720 720p HD (check its supported before setting it)
    //    AVCaptureSessionPresetPhoto - Full photo resolution (not supported for video output)
    
    //NSLog(@"Setting image quality");
    
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset640x480])        //Check size based configs are supported before setting them
        [self.captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    
    
    
    //----- DISPLAY THE PREVIEW LAYER -----
    //Display it full screen under out view controller existing controls
    NSLog(@"Display the preview layer");
    CGRect layerRect = [[[self view] layer] bounds];
    [_PreviewLayer setBounds:layerRect];
    [_PreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    //[[[self view] layer] addSublayer:[[self CaptureManager] previewLayer]];
    //We use this instead so it goes on a layer behind our UI controls (avoids us having to manually bring each control to the front):
    UIView *CameraView = [[UIView alloc] init] ;
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:_PreviewLayer];
    
    
    //----- START THE CAPTURE SESSION RUNNING -----
    [self.captureSession startRunning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationLandscapeLeft);
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

//********** GET CAMERA IN SPECIFIED POSITION IF IT EXISTS **********
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
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
        
        //Create temporary URL to record to
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        NSString* dateTimePrefix = [formatter stringFromDate:[NSDate date]];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
       // if (currentOutputMode == OutputModeMovieFile) {
            
            int fileNamePostfix = 0;
            NSString *filePath = nil;
        
        filePath =[NSString stringWithFormat:@"/%@/%@-%i.mp4", documentsDirectory, dateTimePrefix, fileNamePostfix++];
        while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
        
        self.fileURL = [NSURL URLWithString:[@"file://" stringByAppendingString:filePath]];
        
       // [self.movieFileOutput startRecordingToOutputFileURL:self.fileURL recordingDelegate:self];
        
        
        
        
//        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
//        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        if ([fileManager fileExistsAtPath:outputPath])
//        {
//            NSError *error;
//            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
//            {
//                //Error - handle if requried
//            }
//        }
     //   [outputPath release];
        //Start recording
        [_movieFileOutput startRecordingToOutputFileURL:_fileURL recordingDelegate:self];
      //  [outputURL release];
   
 // */
  }
         
    else
    {
        
        //----- STOP RECORDING -----
        NSLog(@"STOP RECORDING");
        WeAreRecording = NO;
        
        [_movieFileOutput stopRecording];
        //from other file
        
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


-(void)getLastImage{
    UIImage *image1 = [_saveImages objectAtIndex:0];
    UIImage *image2 = [_saveImages objectAtIndex:1];
    UIImage *image3 = [_saveImages objectAtIndex:2];
    UIImage *image4 = [_saveImages objectAtIndex:3];
    UIImage *image5 = [_saveImages objectAtIndex:4];
}

-(void)processBuffer{
    
    
    // NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    //  NSURL *movieUrl=[[NSURL alloc] initFileURLWithPath:filePathString];
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

// =============================================================================
#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
    didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
                       fromConnections:(NSArray *)connections
{
    _isRecording = YES;
}

//- (void)                 captureOutput:(AVCaptureFileOutput *)captureOutput
//   didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
//                       fromConnections:(NSArray *)connections error:(NSError *)error
//{
//    //    [self saveRecordedFile:outputFileURL];
//    _isRecording = NO;
//
//    if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
//        [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
//
//       // [self processBuffer];
//    }
//}


// =============================================================================
@end
