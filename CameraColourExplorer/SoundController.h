//
//  SoundController.h
//  CoreAudioPlayer
//
//  Created by James on 02/09/2016.
//  Copyright © 2016 James Alvarez. All rights reserved.
//

#ifndef SoundController_h
#define SoundController_h

#include <stdio.h>
#include <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif


// A struct to hold information about output status

typedef struct CAPAudioOutput
{
    AUGraph graph;
    AUNode outputNode;
    AUNode mixerNode;
    AudioUnit mixerUnit;
    AudioUnit outputUnit;
    double startingFrameCount;
} CAPAudioOutput;


EXTERNC void CAPStartAudioOutput (CAPAudioOutput *player);
EXTERNC void CAPDisposeAudioOutput(CAPAudioOutput *output);

#endif /* SoundController_h */
