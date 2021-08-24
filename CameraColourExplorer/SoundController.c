//
//  SoundController.c
//  CoreAudioPlayer
//
//  Created by James on 02/09/2016.
//  Copyright © 2016 James Alvarez. All rights reserved.
//


#include "SoundController.h"
#include "MaximilianSounds.hpp"



#define CAP_SAMPLE UInt16
#define CAP_SAMPLE_RATE 44100
#define CAP_CHANNELS 1
#define CAP_SAMPLE_SIZE sizeof(CAP_SAMPLE)


AudioStreamBasicDescription const CAPAudioDescription = {
    .mSampleRate        = CAP_SAMPLE_RATE,
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsSignedInteger,
    .mBytesPerPacket    = CAP_SAMPLE_SIZE * CAP_CHANNELS,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = CAP_CHANNELS * CAP_SAMPLE_SIZE,
    .mChannelsPerFrame  = CAP_CHANNELS,
    .mBitsPerChannel    = 8 * CAP_SAMPLE_SIZE, //8 bits per byte
    .mReserved          = 0
};



#pragma mark - callback function -

static OSStatus CAPRenderProc(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList * ioData) {
    
    
    double left;
    double right;
    
    CAP_SAMPLE *outputData = (CAP_SAMPLE*)ioData->mBuffers[0].mData;
    
    for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {

        MaximilianDemoPlay(&left, &right);
        (outputData)[frame] = (CAP_SAMPLE)(left * 32767.0);
        //(outputData)[outSample + 1] = (Float32)right;
        

    }
    
    
    return noErr;
}

#pragma mark - error handler -

// generic error handler - if err is nonzero, prints error message and exits program.
static void CheckError(OSStatus error, const char *operation) {
    if (error == noErr) return;
    
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    exit(1);
}




#pragma mark - audio output functions -

void CAPStartAudioOutput (CAPAudioOutput *player) {
    OSStatus status = noErr;
    
    // Create Audio Graph
    NewAUGraph(&player->graph);
    
    
    // Description for the output AudioComponent
    AudioComponentDescription outputcd = {
        .componentType = kAudioUnitType_Output,
        .componentSubType = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags = 0,
        .componentFlagsMask = 0
    };
    
    // Description for the mixer AudioComponent
    AudioComponentDescription mixercd = {
        .componentFlags = 0,
        .componentFlagsMask = 0,
        .componentType = kAudioUnitType_Mixer,
        .componentSubType = kAudioUnitSubType_SpatialMixer,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
    };
    
    
    // Create and add nodes to graph
    AUGraphAddNode(player->graph, &outputcd, &player->outputNode);
    AUGraphAddNode(player->graph, &mixercd, &player->mixerNode);
    
    // Connect nodes
    status = AUGraphConnectNodeInput(player->graph, player->mixerNode, 0, player->outputNode, 0);
    CheckError (status, "Could not connect nodes");
    
    //Open the Graph
    AUGraphOpen (player->graph);
    
    //Get Audio Units from graph
    AUGraphNodeInfo (player->graph, player->outputNode, NULL, &player->outputUnit);
    AUGraphNodeInfo (player->graph, player->mixerNode, NULL, &player->mixerUnit);
    
    //Set number of inputs
    UInt32 numbuses = 1;
    status = AudioUnitSetProperty(player->mixerUnit, kAudioUnitProperty_ElementCount,
                                  kAudioUnitScope_Input, 0, &numbuses, sizeof(numbuses));
    CheckError (status, "Could not set number of buses");
    
    // Set the render callback
    AURenderCallbackStruct inputStruct = {
        .inputProc = CAPRenderProc,
        .inputProcRefCon = player
    };
    
    status = AUGraphSetNodeInputCallback(player->graph, player->mixerNode, 0, &inputStruct);
    CheckError (status, "Could not set render callback");
    
    
    status = AudioUnitSetProperty(player->mixerUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &CAPAudioDescription, sizeof(CAPAudioDescription));
    CheckError (status, "Could not stream format");
    
    status = AUGraphInitialize (player->graph);
    CheckError (status, "AudioUnitSetProperty(kAudioUnitProperty_MaximumFramesPerSlice");
    
    AUGraphStart (player->graph);
    fprintf(stderr, "AUDIO GRAPH UP AND RUNNING\n");
    
    AudioUnitSetParameter(player->mixerUnit,
                          k3DMixerParam_Distance,
                          kAudioUnitScope_Input,
                          0,
                          10.0,
                          0);
    
    AudioUnitSetParameter(player->mixerUnit,
                          k3DMixerParam_Azimuth,
                          kAudioUnitScope_Input,
                          0,
                          90,
                          0);
    
}


void CAPDisposeAudioOutput(CAPAudioOutput *output) {
    AUGraphStop (output->graph);

}




