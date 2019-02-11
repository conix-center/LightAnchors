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
using namespace metal;



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

