//
//  PhotoViewController.m
//  ImageDenighter
//
//  Created by jiefeng on 7/28/13.
//  Copyright (c) 2013 jiefeng. All rights reserved.
//

#import "PhotoViewController.h"
#import "AppDelegate.h"

@interface PhotoViewController ()

@property (strong, nonatomic) IBOutlet UIView *contentView;

- (IBAction)processBtnPressed:(id)sender;
- (IBAction)saveBtnPressed:(id)sender;

@end



@implementation PhotoViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Setup pan gesture recogniser
    UIPanGestureRecognizer *tgr = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(panGestureHandler:)];
    tgr.delegate = self;
    [self.photoView addGestureRecognizer:tgr];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL) shouldAutorotate {
    return NO;
}


#pragma events

- (IBAction)openBtnPressed:(id)sender {
    
    // create image picker
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.delegate = self;
    
    // check source type
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No supported photo library"
                                                        message:@"Please choose photos instead"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // check media type
    NSString *desired = (NSString*) kUTTypeImage;
    NSArray *medias = [UIImagePickerController availableMediaTypesForSourceType:imgPicker.sourceType];
    if([medias containsObject:desired]) {
        imgPicker.mediaTypes = [NSArray arrayWithObject:desired];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wrong media type"
                                                        message:@"No media type supported for image"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    imgPicker.editing = NO;
    
    // show camera preview to capture photo
    [self.navigationController presentViewController:imgPicker animated:YES completion:nil];
    
}


- (IBAction)processBtnPressed:(id)sender {
    
    if (pickedImage == nil) {
        return;
    }
    
    if ([self.modeSelector selectedSegmentIndex] != 1) {
        [self setCurrentImage:pickedImage];
        return;
    }
    
    
    
    UIImageOrientation old_orientation = pickedImage.imageOrientation;
    
    UIActivityIndicatorView* waitIndicator = [[UIActivityIndicatorView alloc] init];
    [waitIndicator performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:YES];
    
    // convert to opencv format
    cv::Mat convertImageMat;
    UIImageToMat(pickedImage, convertImageMat);
    
    // resize
    cv::resize(convertImageMat, convertImageMat, cv::Size(640, 480));
    // convert color
    cv::cvtColor(convertImageMat, convertImageMat, COLOR_BGRA2BGR);
    
    // process
    ImgEnhancer enhancer;
    if( !enhancer.Init(convertImageMat) )
        return;
    
    cv::Mat enhancedImage;
    if( !enhancer.MSRCR(convertImageMat, enhancedImage))
        return;
    
    // convert back to uiimage and show
    processedImage = MatToUIImage(enhancedImage);
    
    // rotate to correct orientation
    if (pickedImage.imageOrientation != old_orientation) {
        pickedImage = [[UIImage alloc] initWithCGImage: pickedImage.CGImage
                                                    scale: 1.0
                                              orientation: old_orientation];
    }
    
    [self setCurrentImage:processedImage];

    
    [waitIndicator performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:YES];
    
    self.saveBtn.enabled = YES;
    
}

- (IBAction)saveBtnPressed:(id)sender {
    
    if(processedImage != nil)
    {
        UIImageWriteToSavedPhotosAlbum(processedImage, self, nil, nil);
        UIAlertView* promptView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Photo has been saved." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [promptView show];
    }
    
}

#pragma pan handling

- (void)panGestureHandler:(UIPanGestureRecognizer *)tgr
{
    if ([tgr state] == UIGestureRecognizerStateEnded) {
        [colourProcessor haltSound];
        return;
    }
    
    CGPoint touchPoint = [tgr locationInView:self.view];
    CGPoint truePoint = [self convertPointToTrueImageSize:touchPoint];
    [colourProcessor setAverageColorFromImageAtX:roundf(truePoint.x)
                                                           atY:roundf(truePoint.y)
                                                      stepSize:1
                                                         steps:2];
    
    
    [self.feedbackLabel setText:[colourProcessor LCHColorString]];
    [self.colourPreviewView setBackgroundColor: [colourProcessor currentColour]];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    float xPos = truePoint.x / self.photoView.image.size.width;
    float zimuth = 180 * (xPos - 0.5);
    [appDelegate setAzimith: zimuth];
}

- (CGPoint)convertPointToTrueImageSize:(CGPoint) point {
    
    //NSLog(@"tapped at: %f,%f", point.x, point.y);
    CGRect imageRect = AVMakeRectWithAspectRatioInsideRect(self.photoView.image.size, self.photoView.frame);
    //NSLog(@"Image size: %@", NSStringFromCGSize(self.photoView.image.size));
    //NSLog(@"Image frame: %@", NSStringFromCGRect(self.photoView.frame));
    //NSLog(@"Fit rect: %@", NSStringFromCGRect(imageRect));
    //CGFloat x = MIN(imageRect.size.width, MAX(0, point.x - imageRect.origin.x));
    //CGFloat y = MIN(imageRect.size.height, MAX(0, point.y - imageRect.origin.y));
    CGFloat x = point.x - imageRect.origin.x;
    CGFloat y = point.y - imageRect.origin.y;
    
    x *= self.photoView.image.size.width / imageRect.size.width;
    y *= self.photoView.image.size.height / imageRect.size.height;

    //NSLog(@"returning: %f,%f\n\n", x, y);
    return CGPointMake(x, y);
}


#pragma delegate methods

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage* newImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    pickedImage = newImage;
    [self setCurrentImage: pickedImage];
    
    self.modeSelector.enabled = YES;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer
                         :(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

-(void) setCurrentImage:(UIImage*)image {
    self.photoView.image = image;
    colourProcessor = [[ColourProcessor alloc]initWithImage:image];
}



@end
