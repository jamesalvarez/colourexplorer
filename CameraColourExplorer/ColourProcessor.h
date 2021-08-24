//
//  ColourProcessor.h
//  CameraColourExplorer
//
//  Created by James on 05/08/2017.
//  Copyright © 2017 James. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColourProcessor : NSObject {
    unsigned char *rawData;
    CGRect imageRect;
    NSUInteger bytesPerRow;
    UIImageOrientation orientation;
    UIColor* colour;
    float L;
    float C;
    float H;
    int R;
    int G;
    int B;
}

- (id)initWithImage:(UIImage*)image;
- (void)dealloc;
- (UIColor*)currentColour;
- (void)setColorFromImageAtX:(int)x atY:(int)y;
- (void)setAverageColorFromImageAtX:(int)x atY:(int)y stepSize:(int)stepSize steps:(int)steps;
- (NSString*)LCHColorString;
- (NSString*)RGBColorString;
- (void)haltSound;

@end
