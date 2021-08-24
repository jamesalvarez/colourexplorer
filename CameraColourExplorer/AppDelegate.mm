//
//  AppDelegate.m
//  CameraColourExplorer
//
//  Created by James on 13/07/2017.
//  Copyright © 2017 James. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "SoundController.h"
#import "MaximilianSounds.hpp"
#import "ColourConversions.h"

@interface AppDelegate ()

@end

@implementation AppDelegate {
    CAPAudioOutput _audioOutput;
    struct MMColourSoundSetup setup;
}

-(void)setAzimith:(float) azimuth {
    NSLog(@"Azimuth: %f", azimuth);
    AudioUnitSetParameter(_audioOutput.mixerUnit,
                          k3DMixerParam_Distance,
                          kAudioUnitScope_Input,
                          0,
                          1.0,
                          0);
    AudioUnitSetParameter(_audioOutput.mixerUnit,
                          k3DMixerParam_Azimuth,
                          kAudioUnitScope_Input,
                          0,
                          azimuth,
                          0);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Set up AVAudioSession to allow audio on iOS device
    NSError *error = nil;
    if ( ![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error] ) {
        NSLog(@"Couldn't set audio session category: %@", error);
    }
    
    if ( ![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:(128.0/44100.0) error:&error] ) {
        NSLog(@"Couldn't set preferred buffer duration: %@", error);
    }
    
    if ( ![[AVAudioSession sharedInstance] setActive:YES error:&error] ) {
        NSLog(@"Couldn't set audio session active: %@", error);
    }
    
    // Get paths for audio files
    NSURL* redURL = [[NSBundle mainBundle] URLForResource:@"audio/RED_trumpet_loop" withExtension:@"wav"];
    NSURL* greyURL = [[NSBundle mainBundle] URLForResource:@"audio/GREY_noise_loop" withExtension:@"wav"];
    //NSURL* yellowURL = [[NSBundle mainBundle] URLForResource:@"audio/YELLOW_violin_loop" withExtension:@"wav"];
    NSURL* greenURL = [[NSBundle mainBundle] URLForResource:@"audio/GREEN_flute_loop" withExtension:@"wav"];
    //NSURL* blueURL = [[NSBundle mainBundle] URLForResource:@"audio/BLUE_cello_loop" withExtension:@"wav"];
    //NSURL* whiteURL = [[NSBundle mainBundle] URLForResource:@"audio/WHITE_choir_loop" withExtension:@"wav"];
    
    NSURL* blackURL = [[NSBundle mainBundle] URLForResource:@"audio/BLACK_sinewave_loop" withExtension:@"wav"];
    NSURL* blueURL = [[NSBundle mainBundle] URLForResource:@"audio/BLUE_sinewave_loop" withExtension:@"wav"];
    NSURL* whiteURL = [[NSBundle mainBundle] URLForResource:@"audio/WHITE_sinewave_loop" withExtension:@"wav"];
    NSURL* yellowURL = [[NSBundle mainBundle] URLForResource:@"audio/YELLOW_sinewave_loop" withExtension:@"wav"];
    
    // Put into struct to send to setup
    setup.hues[0].samplePath = [[redURL path] UTF8String];
    setup.hues[1].samplePath = [[yellowURL path] UTF8String];
    setup.hues[2].samplePath = [[greenURL path] UTF8String];
    setup.hues[3].samplePath = [[blueURL path] UTF8String];
    
    setup.hues[0].hueAngle = 0.73;
    setup.hues[1].hueAngle = 1.8;
    setup.hues[2].hueAngle = 2.1;
    setup.hues[3].hueAngle = 4.78;
    
    
    //Calculate max saturation
    for (int i = 0; i < N_HUES; i++) {
        
        float H = setup.hues[i].hueAngle;
        setup.hues[i].maxSaturation = 0;
        
        for (float L = 0; L < 100; L++) {
            for(float C = 0; C < 1000; C++) {
                int R,G,B;
                convertLCHtoRGB(L, C, H, &R, &G, &B);
                
                if (R < 256 && G < 256 && B < 256 && R >= 0 && G >= 0 && B >= 0) {
                    setup.hues[i].maxSaturation = MAX(setup.hues[i].maxSaturation, C);
                } else {
                    //break;
                }
            }
        }
    }
    
    
    
    setup.greys[0].samplePath = [[blackURL path] UTF8String];
    setup.greys[1].samplePath = [[greyURL path] UTF8String];
    setup.greys[2].samplePath = [[whiteURL path] UTF8String];
    
    setup.greys[0].minSaturationRatio = 0.1;
    setup.greys[0].maxSaturationRatio = 0.2;
    setup.greys[0].lightness = 0;
    
    setup.greys[1].minSaturationRatio = 0.1;
    setup.greys[1].maxSaturationRatio = 0.2;
    setup.greys[1].lightness = 75;
    
    setup.greys[2].minSaturationRatio = 0.2;
    setup.greys[2].maxSaturationRatio = 0.3;
    setup.greys[2].lightness = 100;
    
    
    // Trigger setup
    MaximilianSetup(setup);
    
    
    // Start audio
    CAPStartAudioOutput(&_audioOutput);
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
