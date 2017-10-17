//
//  ViewController.m
//  AvCaptureRecord
//
//  Created by D.K. Willardson on 10/5/17.
//  Copyright © 2017 Hitting Tech. All rights reserved.
//


#import "ViewController.h"

@interface ViewController()
@property (nonatomic,strong)NSMutableArray *saveImages;

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
    NSLog(@"Setting up capture session");
    CaptureSession = [[AVCaptureSession alloc] init];
    
    //----- ADD INPUTS -----
    NSLog(@"Adding video input");

    //ADD VIDEO INPUT
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    
    
    BOOL isFPSSupported = NO;
    AVCaptureDeviceFormat *currentFormat = [VideoDevice activeFormat];
    for ( AVFrameRateRange *range in currentFormat.videoSupportedFrameRateRanges ) {
        if ( range.maxFrameRate >= CAPTURE_FRAMES_PER_SECOND && range.minFrameRate <= CAPTURE_FRAMES_PER_SECOND )        {
            isFPSSupported = YES;
            break;
        }
    }
    
    if( isFPSSupported ) {
        if ( [VideoDevice lockForConfiguration:NULL] ) {
            VideoDevice.activeVideoMaxFrameDuration = CMTimeMake( 1, CAPTURE_FRAMES_PER_SECOND );
            VideoDevice.activeVideoMinFrameDuration = CMTimeMake( 1, CAPTURE_FRAMES_PER_SECOND );
            [VideoDevice unlockForConfiguration];
        }
    }
   
//    if([VideoDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
//        [VideoDevice lockForConfiguration:nil];
//        //configure frame rate
//        [VideoDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
//        [VideoDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
//        [VideoDevice setTorchMode:AVCaptureTorchModeOn]; // Change to "if necessary"
//        [VideoDevice unlockForConfiguration];
//    }
    
    if (VideoDevice)
    {
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([CaptureSession canAddInput:VideoInputDevice])
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
 
 
    //ADD AUDIO INPUT
    NSLog(@"Adding audio input");
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        [CaptureSession addInput:audioInput];
    }
//*/
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession] ];
    
    _PreviewLayer.orientation = AVCaptureVideoOrientationLandscapeLeft;        //SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
  //  [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    
    //ADD MOVIE FILE OUTPUT
    NSLog(@"Adding movie file output");
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;            //Total seconds
    int32_t preferredTimeScale = CAPTURE_FRAMES_PER_SECOND;    //Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);    //SET MAX DURATION
    MovieFileOutput.maxRecordedDuration = maxDuration;
    
    MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;                        //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];
    
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
    NSLog(@"Setting image quality");
    [CaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])        //Check size based configs are supported before setting them
        [CaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    
    
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
    [CaptureSession startRunning];
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
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([CaptureConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;        //<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [CaptureConnection setVideoOrientation:orientation];
    }
    
    //Set frame rate (if requried)
    
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
//
//    if (CaptureConnection.supportsVideoMinFrameDuration)
//        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//    if (CaptureConnection.supportsVideoMaxFrameDuration)
//        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
//
//    CMTimeShow(CaptureConnection.videoMinFrameDuration);
//    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
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
        //----- START RECORDING -----
        NSLog(@"START RECORDING");
        WeAreRecording = YES;
        
        //Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                //Error - handle if requried
            }
        }
     //   [outputPath release];
        //Start recording
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
      //  [outputURL release];
    }
    else
    {
        //----- STOP RECORDING -----
        NSLog(@"STOP RECORDING");
        WeAreRecording = NO;
        
        [MovieFileOutput stopRecording];
    }
}


//********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
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
        
      //  [library release];
        
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
    
    
    NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    NSURL *movieUrl=[[NSURL alloc] initFileURLWithPath:filePathString];
    AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:movieUrl options:nil];

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
    
 
    
    //    NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
    //    NSURL *movieUrl=[[NSURL alloc] initFileURLWithPath:filePathString];
    //    AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:movieUrl options:nil];
    //    CMTime actualTime;
    //    CMTime videoDuration = movieAsset.duration;
    //    AVAssetImageGenerator *generate = [AVAssetImageGenerator assetImageGeneratorWithAsset:movieAsset];
    //    generate.appliesPreferredTrackTransform = YES;
    //    NSError *error1;
    //    // int64_t lastFrameTime = CMTimeGetSeconds(movieAsset.duration)*60.0;
    //   // float lastFrameTime = CMTimeGetSeconds(movieAsset.duration)*60.0;
    //    float videoDurationSeconds = CMTimeGetSeconds(videoDuration);
    //    int frames=(int)videoDurationSeconds*CAPTURE_FRAMES_PER_SECOND;
    //
    //    generate.requestedTimeToleranceBefore = kCMTimeZero;
    //    generate.requestedTimeToleranceAfter = kCMTimeZero;
    //
    // //   CMTime time = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND);
    //    CMTime time = CMTimeMakeWithSeconds(videoDurationSeconds *1/(float)frames, frames);
    //    CGImageRef imgRef1 = [generate copyCGImageAtTime:time actualTime:&actualTime error:&error1];
    //    UIImage *image1 = [UIImage imageWithCGImage:imgRef1];
    //
    //
    //    time = CMTimeMakeWithSeconds(videoDurationSeconds *2/(float)frames, frames);
    //    CGImageRef imgRef2 = [generate copyCGImageAtTime:time actualTime:&actualTime error:&error1];
    //    UIImage *image2 = [UIImage imageWithCGImage:imgRef2];
    //
    //    time = CMTimeMakeWithSeconds(videoDurationSeconds *3/(float)frames, frames);
    //    CGImageRef imgRef3 = [generate copyCGImageAtTime:time actualTime:&actualTime error:&error1];
    //    UIImage *image3 = [UIImage imageWithCGImage:imgRef3];
    //
    //    time = CMTimeMakeWithSeconds(videoDurationSeconds *4/(float)frames, frames);
    //    CGImageRef imgRef4 = [generate copyCGImageAtTime:time actualTime:&actualTime error:&error1];
    //    UIImage *image4 = [UIImage imageWithCGImage:imgRef4];
    //
    //    time = CMTimeMakeWithSeconds(videoDurationSeconds *5/(float)frames, frames);
    //    CGImageRef imgRef5 = [generate copyCGImageAtTime:time actualTime:&actualTime error:&error1];
    //    UIImage *image5 = [UIImage imageWithCGImage:imgRef5];
    
    
    
    
    
//    NSMutableArray *timeList = [[NSMutableArray alloc]init];
////
//    NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
//    AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:videoUrl options:nil];
//
//        AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
//        generate1.appliesPreferredTrackTransform = YES;
//        NSError *err = NULL;
//        CMTime videoDuration = movieAsset.duration;
//        float videoDurationSeconds = CMTimeGetSeconds(videoDuration);
//        int frames=(int)videoDurationSeconds*30;
//
//        generate1.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(1/30.0, videoDuration.timescale);
//        generate1.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(1/30.0, videoDuration.timescale);
//
//        NSMutableArray *timesm=[[NSMutableArray alloc]init];
//        for (int i=frames-5; i<frames; i++) {
//            CMTime firstThird = CMTimeMake( i * (videoDuration.timescale / 30.0f), videoDuration.timescale);
//            [timesm addObject:[NSValue valueWithCMTime:firstThird]];
//
//            UIImage* myImage = [[UIImage alloc] initWithCGImage:image];
//        }
    
    
//    AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
//    AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
//
//    NSMutableArray *pictList = [NSMutableArray array];
//    for (int i = 0; i < timeList.count; i++) {
//        NSError *error = NULL;
//        CMTime time = CMTimeMake([[timeList objectAtIndex:i] intValue], 1000);
//        CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
//        NSLog(@"error==%@, Refimage==%@", error, refImg);
//
//        [pictList addObject:[[UIImage alloc] initWithCGImage:refImg]];
//    }
    
    
    
    
  //  AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    //AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    
//    AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
//    generateImg.requestedTimeToleranceBefore = kCMTimeZero;
//    generateImg.requestedTimeToleranceAfter = kCMTimeZero;
//
//    NSMutableArray *pictList = [NSMutableArray array];
//    for (int i = 0; i < timeList.count; i++) {
//        NSError *error = NULL;
//        CMTime time = CMTimeMake([[timeList objectAtIndex:i] intValue], 1000);
//        CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
//        //NSLog(@"error==%@, Refimage==%@", error, refImg);
//
//        [pictList addObject:[[UIImage alloc] initWithCGImage:refImg]];
//    }
    
    
    
    
    
    
    
    
    

//
//
//
//
//    [generate1 generateCGImagesAsynchronouslyForTimes:timesm
//                                    completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
//
//                                        UIImage* myImage = [[UIImage alloc] initWithCGImage:image];
//                                        [imagesArray addObject:myImage];
//                                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                                      //  NSString *documentsDirectory = [paths objectAtIndex:0];
//                                     //   NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"ankur-%@ %i.jpg",image,(int)[[NSDate date] timeIntervalSince1970]]];
//                                     //   NSData *imageData = UIImageJPEGRepresentation(myImage,0.7);
//                                      //  [imageData writeToFile:savedImagePath atomically:NO];
//
//
//                                        NSString *requestedTimeString = (NSString *)
//
//                                        CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
//
//                                        NSString *actualTimeString = (NSString *)
//
//                                        CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
//
//                                        NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
//
//                                        if (result == AVAssetImageGeneratorSucceeded) {
//
//                                            // Do something interesting with the image.
//                                        }
//
//
//                                        if (result == AVAssetImageGeneratorFailed) {
//
//                                            NSLog(@"Failed with error: %@", [error localizedDescription]);
//                                        }
//
//                                        if (result == AVAssetImageGeneratorCancelled) {
//
//                                            NSLog(@"Canceled");
//
//                                        }
//
//                                    }];
//
    
    
   // }

    
    
    
    
    
//        NSString *filePathString = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
//        NSURL *movieUrl=[[NSURL alloc] initFileURLWithPath:filePathString];
//        AVURLAsset *movieAsset=[[AVURLAsset alloc] initWithURL:movieUrl options:nil];
//        CMTime actualTime;
//        AVAssetImageGenerator *generate = [AVAssetImageGenerator assetImageGeneratorWithAsset:movieAsset];
//        generate.appliesPreferredTrackTransform = YES;
//        NSError *error1;
//        int64_t lastFrameTime = CMTimeGetSeconds(movieAsset.duration)*60.0;
//
//        CMTime time1 = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND);
//        CGImageRef imgRef1 = [generate copyCGImageAtTime:time1 actualTime:&actualTime error:&error1];
//        UIImage *image1 = [UIImage imageWithCGImage:imgRef1];
//
//        CMTime time2  = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND * 2);
//        CGImageRef imgRef2  = [generate copyCGImageAtTime:time2 actualTime:&actualTime error:&error1];
//        UIImage *image2 = [UIImage imageWithCGImage:imgRef2];
//
//        CMTime time3 = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND * 3);
//        CGImageRef imgRef3 = [generate copyCGImageAtTime:time3 actualTime:&actualTime error:&error1];
//        UIImage *image3 = [UIImage imageWithCGImage:imgRef3];
//
//        CMTime time4 = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND * 4);
//        CGImageRef  imgRef4 = [generate copyCGImageAtTime:time4 actualTime:&actualTime error:&error1];
//        UIImage *image4 = [UIImage imageWithCGImage:imgRef4];
//
//        CMTime time5 = CMTimeMake(lastFrameTime, CAPTURE_FRAMES_PER_SECOND * 5);
//        CGImageRef imgRef5 = [generate copyCGImageAtTime:time5 actualTime:&actualTime error:&error1];
//        UIImage *image5 = [UIImage imageWithCGImage:imgRef5];
//
    
    
}
@end
