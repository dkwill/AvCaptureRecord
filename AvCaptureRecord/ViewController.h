//
//  ViewController.h
//  AvCaptureRecord
//
//  Created by D.K. Willardson on 10/5/17.
//  Copyright © 2017 Hitting Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h> 

//#define CAPTURE_FRAMES_PER_SECOND  240
#define CAPTURE_FRAMES_PER_SECOND  240
    BOOL WeAreRecording;



@protocol TTMCaptureManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;

@end

@interface ViewController : UIViewController

@property (nonatomic, assign) id<TTMCaptureManagerDelegate> delegate;

@end


/*
#import <AssetsLibrary/AssetsLibrary.h>        //<<Can delete if not storing videos to the photo library.  Delete the assetslibrary framework too requires this)

#define CAPTURE_FRAMES_PER_SECOND  240



typedef NS_ENUM(NSUInteger, CameraType) {
    CameraTypeBack,
    CameraTypeFront,
};

typedef NS_ENUM(NSUInteger, OutputMode) {
    OutputModeVideoData,
    OutputModeMovieFile,
};

@protocol TTMCaptureManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;
@end

@interface ViewController : UIViewController
{
    BOOL WeAreRecording;
    
    //AVCaptureSession *CaptureSession;
   // AVCaptureMovieFileOutput *MovieFileOutput;
   // AVCaptureDeviceInput *VideoInputDevice;
    
}

@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, assign) id<TTMCaptureManagerDelegate> delegate;

- (void) CameraSetOutputProperties;
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position;
- (IBAction)StartStopButtonPressed:(id)sender;
- (IBAction)CameraToggleButtonPressed:(id)sender;

@end
*/
