//
//  ViewController.m
//  ImageDenighter
//
//  Created by jiefeng on 1/19/13.
//  Copyright (c) 2013 jiefeng. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController () {
    int frame_count;
    bool isProcessing;
    cv::Mat cur_frame;
    NSTimer* heartbeat;
}

@property (strong, nonatomic) IBOutlet UIView *contentView;

- (IBAction)cameraBtnPressed:(id)sender;
- (IBAction)saveBtnPressed:(id)sender;

@end

@implementation VideoViewController


@synthesize videoCamera = _videoCamera;
@synthesize modeSelector = _modeSelector;
@synthesize captureImgViewer = _captureImgViewer;


#pragma vc functions

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
        
    [self initVideoCpature];
    
    isProcessing = false;
}

- (void) viewDidAppear:(BOOL)animated
{
    [self startCamera];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self stopCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void)restartHeartbeat {
    if (heartbeat != nil) {
        [heartbeat invalidate];
        heartbeat = nil;
    }
    
    heartbeat = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                  target:self
                                                selector:@selector(onHeartbeat:)
                                                userInfo:nil
                                                 repeats:YES];
}

-(void)onHeartbeat:(NSTimer *)timer {
    
    cv::Mat rgbimg;
    cvtColor(cur_frame, rgbimg, COLOR_BGR2RGB);
    ColourProcessor* colourProcessor = [[ColourProcessor alloc] initWithImage: MatToUIImage(rgbimg)];
    
    [colourProcessor setColorFromImageAtX:roundf(rgbimg.cols / 2)
                                                    atY:roundf(rgbimg.rows / 2)];
    

    [self.feedbackLabel setText:[colourProcessor LCHColorString]];
    [self.colourPreviewView setBackgroundColor: [colourProcessor currentColour]];
    [self.feedbackLabel setNeedsDisplay];
}

#pragma mark Camera Control


- (void) initVideoCpature {
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.captureImgViewer];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    self.videoCamera.defaultFPS = 20;
    self.videoCamera.grayscaleMode = NO;
    
}

- (void) startCamera
{
    
    if(self.videoCamera == nil)
        [self initVideoCpature];
    
    if( ![self.videoCamera running] )
    {
        [self.videoCamera start];
        [self restartHeartbeat];
    }
    
}

- (void) stopCamera {
    
    if(self.videoCamera != nil && [self.videoCamera running]) {
        [self.videoCamera stop];    // can't stop multiple times! BAD_ACCESS
    }
}


#pragma processing

// delegate processing method
- (void) processImage:(cv::Mat &)image {
    
    cv::Mat resize_img;
    
    //cvtColor(resize_img, resize_img, CV_BGRA2RGB);
    
    if (isProcessing) {
        resize(image, resize_img, cv::Size(image.cols/2, image.rows/2));
        if( !denighter.ifInit )
            denighter.Init(resize_img);
        else
        {
            Mat convertimg;
            cvtColor(resize_img, convertimg, COLOR_BGRA2BGR);
            Mat output;
            denighter.MSRCR(convertimg, output);
            cvtColor(output, resize_img, COLOR_BGR2BGRA);
        }
        resize(resize_img, image, cv::Size(image.cols, image.rows));
    }
    
    

    image.copyTo(cur_frame);
    

}

- (IBAction)setModeSelector:(UISegmentedControl *)modeSelector {

    isProcessing = [modeSelector selectedSegmentIndex] == 1;

}

- (IBAction)cameraBtnPressed:(id)sender {
    
    if([self.videoCamera running])
    {
        // stop camera
        [self.videoCamera stop];
        
        cv::Mat rgbimg;
        cvtColor(cur_frame, rgbimg, COLOR_BGR2RGB);    // if not convert, will have blur image, don't know why
        self.captureImgViewer.image = MatToUIImage(rgbimg);
        
        self.saveBtn.enabled = true;
    }
    else
    {
        self.saveBtn.enabled = false;
        
        [self.videoCamera start];
    }
    
}

- (IBAction)saveBtnPressed:(id)sender {
    
    if(self.captureImgViewer.image != nil)
    {
        UIImageWriteToSavedPhotosAlbum(self.captureImgViewer.image, self, nil, nil);
        UIAlertView* promptView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Photo has been saved." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [promptView show];
    }
}




@end
