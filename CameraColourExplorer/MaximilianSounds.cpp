//
//  MaximilianDemo.cpp
//  CoreAudioPlayer
//
//  Created by James on 06/09/2017.
//  Copyright © 2017 James Alvarez. All rights reserved.
//

#include "MaximilianSounds.hpp"
#include "maximilian.h"

#define PIV2 M_PI+M_PI
#define PIV3 M_PI+M_PI+M_PI

float smallest_angle_between(float x, float y)
{
    float diff = x > y ? x - y : y - x;
    float arg = fmod(diff, PIV2);
    float dist = arg > M_PI ? PIV2 - arg : arg;

    return dist;
}

float signed_angle_between(float targetAngle, float startAngle)
{
    return fmod(targetAngle - startAngle + PIV3, PIV2) - M_PI;
}

struct LerpFloat {
    float target;
    float current;
    float rampSpeed;
};


struct SamplePlayer {
    maxiSample sample;
    LerpFloat intensity;
};


struct MaximilianObjects {
    MMColourSoundSetup setup;
    SamplePlayer hues[N_HUES];
    SamplePlayer greys[N_GREYS];
    LerpFloat filterLevel;
    maxiFilter filter;
    LerpFloat overallIntensity;
    int counter;
};

MaximilianObjects obj;

void MaximilianSetup(MMColourSoundSetup setup) {
    obj.setup = setup;
    
    for(int i = 0; i < N_HUES; i += 1) {
        obj.hues[i].sample.load(setup.hues[i].samplePath);
        obj.hues[i].intensity = {0, 0, 0.01};
    }
    
    for(int i = 0; i < N_GREYS; i += 1) {
        obj.greys[i].sample.load(setup.greys[i].samplePath);
        obj.greys[i].intensity = {0, 0, 0.01};
    }
    
    obj.overallIntensity = {1.0, 1.0, 0.01};
    obj.filterLevel = {0.5, 0.5, 0.01};
}

float Lerp(LerpFloat* lerpFloat) {
    
    float difference = lerpFloat->target - lerpFloat->current;
    
    if (difference > lerpFloat->rampSpeed) {
        lerpFloat->current += lerpFloat->rampSpeed;
    } else if (difference < (0 - lerpFloat->rampSpeed)) {
        lerpFloat->current -= lerpFloat->rampSpeed;
    } else {
        lerpFloat->current = lerpFloat->target;
    }
    
    return lerpFloat->current;
}

void MaximilianDemoPlay(double *left, double *right) {
    
    
    double overallIntensity = Lerp(&obj.overallIntensity);
    double sample = 0.0;
    
    // Add the hues (max 2 actually playing)
    for(int i = 0; i < N_HUES; i += 1) {
        float intensity = Lerp(&obj.hues[i].intensity);
        sample += intensity * obj.hues[i].sample.play();
    }
    
    // Filter the colour signals
    float filterLevel = Lerp(&obj.filterLevel);
    sample = obj.filter.lores(sample, filterLevel * 4000, 0);
    
    // greys are exempt from filtering
    for(int i = 0; i < N_GREYS; i += 1) {
        float intensity = Lerp(&obj.greys[i].intensity);
        sample += intensity * obj.greys[i].sample.play();
    }
    
    sample *= overallIntensity;
    
    *left = sample;
    *right = sample;
    
}

void MaximilianSetCurrentColour(float hueRads, float saturation, float lightness) {
    
    // Indexes for primary and secondary hue samples
    int iHue1 = 0;
    int iHue2 = 0;
    
    
    // Get angle differences and find closest hue (iHue1).
    float angleDifferences[N_HUES];
    for(int i = 0; i < N_HUES; i += 1) {
        angleDifferences[i] = smallest_angle_between(hueRads, obj.setup.hues[i].hueAngle);
        
        if (angleDifferences[i] < angleDifferences[iHue1]) {
            iHue1 = i;
        }
        
        // Reset previous intensities
        obj.hues[i].intensity.target = 0;
    }
    
    // Calculate the next closest hue
    float signedAngleDifference = signed_angle_between(hueRads, obj.setup.hues[iHue1].hueAngle);
    iHue2 = (signedAngleDifference > 0 ? iHue1 + 1 : iHue1 - 1) % N_HUES;
    if (iHue2 < 0) {
        iHue2 += N_HUES;
    }
    
    // Calculate intensity for the hues
    float totalDifference = angleDifferences[iHue1] + angleDifferences[iHue2];
    float hue1Intensity = ((totalDifference - angleDifferences[iHue1]) / totalDifference);
    float hue2Intensity = ((totalDifference - angleDifferences[iHue2]) / totalDifference);
    
    // Correct saturation using the maximum saturation for these hues.
    float maxSaturationForHue = (hue1Intensity * obj.setup.hues[iHue1].maxSaturation) + (hue2Intensity * obj.setup.hues[iHue2].maxSaturation);
    float correctedSaturation = saturation / maxSaturationForHue; //Saturation now at 0 - 1.
    
    // Indexes for primary and secondary grey samples
    int iGrey1 = 0;
    int iGrey2 = 0;

    // Get grey differences - there is always black which is silent
    float lightnessDifferences[N_GREYS];
    for(int i = 0; i < N_GREYS; i +=1 ) {
        lightnessDifferences[i] = abs(lightness - obj.setup.greys[i].lightness);
        
        if (lightnessDifferences[i] < lightnessDifferences[iGrey1]) {
            iGrey1 = i;
        }
        
        // Reset previous intensities
        obj.greys[i].intensity.target = 0;
    }
    
    
    // Calculate intensity for the greys
    float differenceToClosestGrey = lightness - obj.setup.greys[iGrey1].lightness;
    iGrey2 = (differenceToClosestGrey > 0 ? iGrey1 + 1 : iGrey1 - 1);
    
    // Relative intsities of each grey
    float grey1Intensity, grey2Intensity;
    
    // Range to consider having grey within the hue
    float maxSaturationRatio, minSaturationRatio;
    
    if (iGrey2 >= N_GREYS) {
        grey1Intensity = 1;
        grey2Intensity = 0;
        maxSaturationRatio = obj.setup.greys[iGrey1].maxSaturationRatio;
        minSaturationRatio = obj.setup.greys[iGrey1].minSaturationRatio;
    } else if (iGrey2 <= 0) {
        grey1Intensity = lightness / obj.setup.greys[iGrey1].lightness;
        grey2Intensity = 0;
        maxSaturationRatio = obj.setup.greys[iGrey1].maxSaturationRatio;
        minSaturationRatio = obj.setup.greys[iGrey1].minSaturationRatio;
    } else {
        float totalLightnessDifference = lightnessDifferences[iGrey1] + lightnessDifferences[iGrey2];
        grey1Intensity = (totalLightnessDifference - lightnessDifferences[iGrey1]) / totalLightnessDifference;
        grey2Intensity = (totalLightnessDifference - lightnessDifferences[iGrey2]) / totalLightnessDifference;
        
        maxSaturationRatio = (obj.setup.greys[iGrey1].maxSaturationRatio * grey1Intensity) + (obj.setup.greys[iGrey2].maxSaturationRatio * grey2Intensity);
        minSaturationRatio = (obj.setup.greys[iGrey1].minSaturationRatio * grey1Intensity) + (obj.setup.greys[iGrey2].minSaturationRatio * grey2Intensity);
    }
    
    // Calculate greyness and colourness from saturation level within given range.
    float satRatio = (correctedSaturation - minSaturationRatio) / (maxSaturationRatio - minSaturationRatio);
    float colouredness = MIN(1.0f, MAX(0.0f, satRatio));
    float greyness = 1.0f - colouredness;
    
    
    //now set values
    obj.hues[iHue1].intensity.target = hue1Intensity * colouredness;
    obj.hues[iHue2].intensity.target = hue2Intensity * colouredness;
    obj.greys[iGrey1].intensity.target = grey1Intensity * greyness;
    if (grey2Intensity != 0) {
        obj.greys[iGrey2].intensity.target = grey2Intensity * greyness;
    }
    
    
    // Set overallIntensity according to lightness
    obj.overallIntensity.target = 1.0;
    
    // Set filter according to saturation (filterLevel should be roughly 0 to 1)
    obj.filterLevel.target = MIN(MAX(lightness / 100.0f,0.0f),1.0f);
}

void MaximilianHaltSound() {
    for(int i = 0; i < N_HUES; i += 1) {
        obj.hues[i].intensity.target = 0;
    }
    
    for(int i = 0; i < N_GREYS; i += 1) {
        obj.greys[i].intensity.target = 0;
    }
    
    obj.overallIntensity.target = 0;

}
