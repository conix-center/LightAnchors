//
//  kernels.metal
//  LightAnchors
//
//  Created by Nick Wilkerson on 2/7/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
//#include <metal_integer>

#define NUM_DATA_BITS 6
#define NUM_SNR_BASELINE_BITS 4


using namespace metal;

constant char threshold [[ function_constant(0) ]];
constant char preamble [[ function_constant(1) ]];



kernel void matchPreamble(
                          const device uchar4 *image [[ buffer(0) ]],
                          device uchar4 *historyBuffer [[ buffer(1) ]],
                          device uchar4 *matchBuffer [[ buffer(2) ]],
                          device uchar4 *minBuffer [[ buffer(3) ]],
                          device uchar4 *maxBuffer [[ buffer(4) ]],
                          device uchar4 *dataBuffer [[ buffer(5) ]],
                          device uchar4 *baselineMinBuffer [[ buffer(6) ]],
                          device uchar4 *baselineMaxBuffer [[ buffer(7) ]],
                        //  device uchar4 *snrBuffer [[ buffer(8) ]],
                          uint id [[ thread_position_in_grid ]]
                          ) {
    

    
    /* preamble detector */
    if (matchBuffer[id][0] == 0 && matchBuffer[id][1] == 0 && matchBuffer[id][2] == 0 && matchBuffer[id][3] == 0) {
        /* update min and max for threshold calculation */
        minBuffer[id] = min(minBuffer[id], image[id]);
        maxBuffer[id] = max(maxBuffer[id], image[id]);
        uchar4 thresh = (maxBuffer[id] - minBuffer[id]) / 2;
        
        /* determine whether frame is a 0 or a 1 */
        bool4 binaryPixel = image[id] > thresh;
        
        /* apply current frame binary value to history buffer */
        uchar4 history = historyBuffer[id];
        history = (history << 1) | (uchar4)binaryPixel;
        historyBuffer[id] = history;
        
        /* if history buffer matches preamble start decoding bit 1 of the data */
        uchar4 match = (uchar4)(((history ^ preamble) == 0) || (bool4)matchBuffer[id]);
        matchBuffer[id] = match;
        
    } else {// data decoder
        for (int i=0; i<4; i++) { /* iterate over each pixel of the vector data */
            if (matchBuffer[id][i] != 0) { /* determine which pixels of the vector have matched the preamble */
                if (matchBuffer[id][i] == 1) {//first bit of data
                    dataBuffer[id][i] = 0;/* reset the data buffer to accept new data */
                    baselineMinBuffer[id][i] = 0xFF;
                    baselineMaxBuffer[id][i] = 0;
                }
                if (matchBuffer[id][i] <= NUM_DATA_BITS) {// decode data
                    /* update min and max for threshold calculation */
                    minBuffer[id] = min(minBuffer[id], image[id]);
                    maxBuffer[id] = max(maxBuffer[id], image[id]);
                    uchar4 thresh = (maxBuffer[id] - minBuffer[id]) / 2;
                    
                    /* determine whether frame is a 0 or a 1 */
                    uchar binaryPixel = (uchar)(image[id][i] > thresh[i]);
                    /* apply current frame binary value to data buffer */
                    dataBuffer[id][i] = (dataBuffer[id][i] << 1) | binaryPixel;
                    matchBuffer[id][i]++;
                } else if (matchBuffer[id][i] <= NUM_DATA_BITS + NUM_SNR_BASELINE_BITS) {/* baseline max and min for SNR */
                    baselineMinBuffer[id][i] = min(baselineMinBuffer[id][i], image[id][i]);
                    baselineMaxBuffer[id][i] = max(baselineMaxBuffer[id][i], image[id][i]);
                    
                    matchBuffer[id][i]++;
                } else {
                    matchBuffer[id][i] = 0;
                }
            }
        }
    }
    

    
}


//kernel void matchPreamble(
//                          const device uchar4 *image [[ buffer(0) ]],
//                          device uchar4 *historyBuffer [[ buffer(1) ]],
//                          device uchar4 *matchBuffer [[ buffer(2) ]],
//                          device uchar4 *minBuffer [[ buffer(3) ]],
//                          device uchar4 *maxBuffer [[ buffer(4) ]],
//                          uint id [[ thread_position_in_grid ]]
//                          ) {
//    minBuffer[id] = min(minBuffer[id], image[id]);
//    maxBuffer[id] = max(maxBuffer[id], image[id]);
//    uchar4 thresh = (maxBuffer[id] - minBuffer[id]) / 2;
//
//    bool4 binaryPixel = image[id] > thresh;
//    uchar4 history = historyBuffer[id];
//    history = (history << 1) | (uchar4)binaryPixel;
//    historyBuffer[id] = history;
//
//    uchar4 match = (uchar4)(((history ^ preamble) == 0) || (bool4)matchBuffer[id]);
//    matchBuffer[id] = match;
//
//}


kernel void difference(const device char4 *imageA [[ buffer(0) ]],
                       const device char4 *imageB [[ buffer(1) ]],
                       device char4 *diff [[ buffer(2) ]],
                       uint id [[ thread_position_in_grid ]] ) {
//    uint firstIndex = id * NUM_PIXELS_PER_THREAD;
//    uint endIndex = firstIndex+NUM_PIXELS_PER_THREAD;
//    for (uint i = firstIndex; i<endIndex; i++) {
//        char d = (char)abs(imageA[i]-imageB[i]);
//        diff[i] = d;
//    }
    
    diff[id] = abs(imageA[id]-imageB[id]);
    
}


#define NUM_PIXELS_PER_THREAD 21600 //for 128 threads

kernel void max(const device char *diff [[ buffer(0) ]],
                device char *maxValueArray [[ buffer(1) ]],
                device uint *maxIndexArray [[ buffer(2) ]],
                uint id [[ thread_position_in_grid ]] ) {
    
    uint firstIndex = id * NUM_PIXELS_PER_THREAD;
    uint endIndex = firstIndex+NUM_PIXELS_PER_THREAD;
    uint maxIndex = 0;
    char maxValue = 0;
    for (uint i = firstIndex; i<endIndex; i++) {
        if (diff[i] > maxValue) {
            maxValue = diff[i];
            maxIndex = i;
        }
    }
    maxValueArray[id] = maxValue;
    maxIndexArray[id] = maxIndex;
}

