//
//  ColourProcessor.m
//  CameraColourExplorer
//
//  Created by James on 05/08/2017.
//  Copyright © 2017 James. All rights reserved.
//

#import "ColourProcessor.h"
#import "ColourConversions.h"
#import "MaximilianSounds.hpp"

@implementation ColourProcessor

- (id)initWithImage:(UIImage*)image; {
    self = [super init];
    if (self)
    {
        CGImageRef imageRef = [image CGImage];
        orientation = [image imageOrientation];
        
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        //NSLog(@"w: %lu, h: %lu", (unsigned long)width, (unsigned long)height);
        imageRect = CGRectMake(0, 0, width, height);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        bytesPerRow = 4 * width;
        NSUInteger bitsPerComponent = 8;
        CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                     bitsPerComponent, bytesPerRow, colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, imageRect, imageRef);
        CGContextRelease(context);
    }
    return self;
}

-(void)dealloc {
    free(rawData);
}

-(UIColor*)currentColour {
    return colour;
}

-(CGPoint)getTrueCoordinatesFromOrientation:(int)x y:(int)y {
    if (orientation == UIImageOrientationLeft) {
        return CGPointMake(imageRect.size.height - y, imageRect.size.width - x);
        
    } else if (orientation == UIImageOrientationRight) {
        return CGPointMake(y, x);
        
    } else if (orientation == UIImageOrientationDown) {
        return CGPointMake(imageRect.size.width - x,imageRect.size.height - y);
    } else {
        return CGPointMake(x, y);
    }
}

- (void)setColorFromImageAtX:(int)x atY:(int)y{

    
    // RawData contains the image data in the RGBA8888 pixel format.
    NSUInteger byteIndex = (bytesPerRow * y) + x * 4;
    CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
    CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / (255.0f * alpha);
    CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / (255.0f * alpha);
    CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / (255.0f * alpha);

    colour = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    [self updateSound];
}

- (void)setAverageColorFromImageAtX:(int)x atY:(int)y stepSize:(int)stepSize steps:(int)steps {
    
    CGPoint point = [self getTrueCoordinatesFromOrientation:x y:y];

    int halfWidth = steps * stepSize ;
    int startX = MAX(point.x - halfWidth,0);
    int startY = MAX(point.y - halfWidth,0);
    int endX = MIN(point.x + halfWidth, imageRect.size.width);
    int endY = MIN(point.y + halfWidth, imageRect.size.height);
    
    CGFloat totals[3] = {0,0,0};
    CGFloat count = 0;

    //NSLog(@"%f,%f", point.x, point.y);
    
    for(int xIndex = startX; xIndex < endX; xIndex += stepSize) {
        for(int yIndex = startY; yIndex < endY; yIndex += stepSize) {
            
            NSUInteger byteIndex = (bytesPerRow * yIndex) + xIndex * 4;
            CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
            CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / alpha;
            CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / alpha;
            CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / alpha;
            
            totals[0] += red;
            totals[1] += green;
            totals[2] += blue;
            count += 1;
            
        }
    }
    
    
    
    if (count == 0) {
        colour = [UIColor blackColor];

    } else {
        colour = [UIColor colorWithRed:totals[0] / (255 * count)
                                green:totals[1] / (255 * count)
                                 blue:totals[2] / (255 * count)
                                 alpha:1.0f];
    }

    [self updateSound];
}

- (void)haltSound {
    MaximilianHaltSound();
}

- (NSString*)LCHColorString {
    
    NSString* Lab = [NSString stringWithFormat:@"LCH: %.2f, %.2f, %.2f", L, C, H];
    return Lab;
}

- (NSString*)RGBColorString {
    
    NSString* RGB = [NSString stringWithFormat:@"RGB: %i, %i, %i", R, G, B];
    return RGB;
}

- (void)updateSound {
    const CGFloat* components = CGColorGetComponents(colour.CGColor);
    
    
    R = (int)roundf(components[0] * 255);
    G = (int)roundf(components[1] * 255);
    B = (int)roundf(components[2] * 255);
    

    convertRGBtoLCH(R, G, B, &L, &C, &H);
    
    MaximilianSetCurrentColour(H, C, L);
}


@end
