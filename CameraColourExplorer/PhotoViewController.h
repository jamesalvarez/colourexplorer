//
//  PhotoViewController.h
//  ImageDenighter
//
//  Created by jiefeng on 7/28/13.
//  Copyright (c) 2013 jiefeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#include <opencv2/imgcodecs/ios.h>
#include "ImgEnhancer.h"
#import "ColourProcessor.h"



@interface PhotoViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate,UIGestureRecognizerDelegate> {
    
    ColourProcessor* colourProcessor;
    UIImage* pickedImage;
    UIImage* processedImage;
}



@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeSelector;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;

@property (weak, nonatomic) IBOutlet UIView *colourPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;



@end
