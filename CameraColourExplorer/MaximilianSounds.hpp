//
//  MaximilianDemo.hpp
//
//  Created by James on 06/09/2017.
//  Copyright © 2017 James Alvarez. All rights reserved.
//

#ifndef MaximilianDemo_hpp
#define MaximilianDemo_hpp

#include <stdio.h>


#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#define N_HUES 4
#define N_GREYS 3

EXTERNC struct ColourSoundHueSample {
    const char* samplePath;
    float hueAngle;
    float maxSaturation;
};

EXTERNC struct ColourSoundGreySample {
    const char* samplePath;
    float maxSaturationRatio; // above this number the grey wont play
    float lightness;
    float minSaturationRatio; // below this number the grey will be 100%
};

EXTERNC struct MMColourSoundSetup {
    struct ColourSoundHueSample hues[N_HUES];
    struct ColourSoundGreySample greys[N_GREYS];
};

EXTERNC void MaximilianSetup(struct MMColourSoundSetup setup);

EXTERNC void MaximilianDemoPlay(double *left, double *right);

EXTERNC void MaximilianSetCurrentColour(float hue, float saturation, float brightness);

EXTERNC void MaximilianHaltSound();

#endif /* MaximilianDemo_hpp */
