//
//  ViewController.h
//  ImageDenighter
//
//  Created by jiefeng on 1/19/13.
//  Copyright (c) 2013 jiefeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#include <opencv2/imgcodecs/ios.h>
#include "ImgEnhancer.h"
#import "ColourProcessor.h"
using namespace cv;

@interface VideoViewController : UIViewController <CvVideoCameraDelegate, UINavigationBarDelegate>
{
     ImgEnhancer denighter;
}


@property (nonatomic, retain) CvVideoCamera *videoCamera;
@property (weak, nonatomic) IBOutlet UIImageView *captureImgViewer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelector;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;

@property (weak, nonatomic) IBOutlet UIView *colourPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;

@end
