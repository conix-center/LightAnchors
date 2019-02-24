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

#define NUM_PREAMBLE_BITS 6
#define NUM_DATA_BITS 6
#define NUM_SNR_BASELINE_BITS 4


using namespace metal;

//constant char threshold [[ function_constant(0) ]];
constant char preamble [[ function_constant(1) ]];



/* iterate over entire preamble every frame */
kernel void matchPreamble(
                          const device uchar4 *image [[ buffer(0) ]],
                          device uchar4 *preambleBuffer [[ buffer(1) ]],
                          device uchar4 *matchBuffer [[ buffer(2) ]],
                          device uchar4 *minBuffer [[ buffer(3) ]],
                          device uchar4 *maxBuffer [[ buffer(4) ]],
                          device uchar4 *dataBuffer [[ buffer(5) ]],
                          device uchar4 *baselineMinBuffer [[ buffer(6) ]],
                          device uchar4 *baselineMaxBuffer [[ buffer(7) ]],
                          const device uchar4 *prevImage1 [[ buffer(8) ]],
                          const device uchar4 *prevImage2 [[ buffer(9) ]],
                          const device uchar4 *prevImage3 [[ buffer(10) ]],
                          const device uchar4 *prevImage4 [[ buffer(11) ]],
                          const device uchar4 *prevImage5 [[ buffer(12) ]],
                          device uchar4 *dataMinBuffer [[ buffer(13) ]],
                          device uchar4 *dataMaxBuffer [[ buffer(14) ]],
                          uint id [[ thread_position_in_grid ]]
                          ) {
    /* preamble detector */
    if (matchBuffer[id][0] == 0 && matchBuffer[id][1] == 0 && matchBuffer[id][2] == 0 && matchBuffer[id][3] == 0) {
        /* update min and max for threshold calculation */
//        minBuffer[id] = min(minBuffer[id], image[id]);
//        maxBuffer[id] = max(maxBuffer[id], image[id]);
//        uchar4 thresh = (maxBuffer[id] - minBuffer[id]) / 2;
        
//                for (int i=0; i<4; i++) {
//                    if (match[i] != 0) {
//                        uchar dataMin = 0xFF;
//                        uchar dataMax = 0;
//
//                        if (image[id][i] < dataMin) dataMin = image[id][i];
//                        if (prevImage1[id][i] < dataMin) dataMin = prevImage1[id][i];
//                        if (prevImage2[id][i] < dataMin) dataMin = prevImage2[id][i];
//                        if (prevImage3[id][i] < dataMin) dataMin = prevImage3[id][i];
//                        if (prevImage4[id][i] < dataMin) dataMin = prevImage4[id][i];
//                        if (prevImage5[id][i] < dataMin) dataMin = prevImage5[id][i];
//                        if (image[id][i] > dataMax) dataMax = image[id][i];
//                        if (prevImage1[id][i] > dataMax) dataMax = prevImage1[id][i];
//                        if (prevImage2[id][i] > dataMax) dataMax = prevImage2[id][i];
//                        if (prevImage3[id][i] > dataMax) dataMax = prevImage3[id][i];
//                        if (prevImage4[id][i] > dataMax) dataMax = prevImage4[id][i];
//                        if (prevImage5[id][i] > dataMax) dataMax = prevImage5[id][i];
////                        dataMinBuffer[id][i] = dataMin;
////                        dataMaxBuffer[id][i] = dataMax;
//                    }
//                }
        
        uchar4 minValue = min(0xFF, image[id]);
        minValue = min(minValue, prevImage1[id]);
        minValue = min(minValue, prevImage2[id]);
        minValue = min(minValue, prevImage3[id]);
        minValue = min(minValue, prevImage4[id]);
        minValue = min(minValue, prevImage5[id]);
        uchar4 maxValue = max(0, image[id]);
        maxValue = max(maxValue, prevImage1[id]);
        maxValue = max(maxValue, prevImage2[id]);
        maxValue = max(maxValue, prevImage3[id]);
        maxValue = max(maxValue, prevImage4[id]);
        maxValue = max(maxValue, prevImage5[id]);
        uchar4 thresh = (uchar4)(((ushort4)maxValue+(ushort4)minValue)/2) ;//+ (maxValue-minValue)*3/4;

        
        
//        /* determine whether frame is a 0 or a 1 */
//        bool4 binaryPixel = image[id] > thresh;
//
//        /* apply current frame binary value to history buffer */
//        uchar4 possiblePreamble = preambleBuffer[id];
//        possiblePreamble = (possiblePreamble << 1) | (uchar4)binaryPixel;
//        preambleBuffer[id] = possiblePreamble;
//
//        /* if history buffer matches preamble start decoding bit 1 of the data */
//        uchar4 match = (uchar4)(((preamble ^ preamble) == 0) || (bool4)matchBuffer[id]);
//        matchBuffer[id] = match;
        
    
        uchar4 bit = (uchar4)(prevImage5[id] > thresh);
        uchar4 possiblePreamble =  bit;
        bit = (uchar4)(prevImage4[id] > thresh);
        possiblePreamble = (possiblePreamble << 1) | bit;
        bit = (uchar4)(prevImage3[id] > thresh);
        possiblePreamble = (possiblePreamble << 1) | bit;
        bit = (uchar4)(prevImage2[id] > thresh);
        possiblePreamble = (possiblePreamble << 1) | bit;
        bit = (uchar4)(prevImage1[id] > thresh);
        possiblePreamble = (possiblePreamble << 1) | bit;
        bit = (uchar4)(image[id] > thresh);
        possiblePreamble = (possiblePreamble << 1) | bit;
        
        uchar4 match = (uchar4)((possiblePreamble ^ preamble) == 0);
        matchBuffer[id] = match | matchBuffer[id];
        
        if (match[0] != 0 || match[1] != 0 || match[2] != 0 || match[3] != 0) {
            dataMinBuffer[id] = minValue;
            dataMaxBuffer[id] = maxValue;
        }
        
        //debugging
        preambleBuffer[id] = possiblePreamble;//possiblePreamble;
        
        
        
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
//                    minBuffer[id] = min(minBuffer[id], image[id]);
//                    maxBuffer[id] = max(maxBuffer[id], image[id]);
                    uchar4 thresh = (uchar4)(((ushort4)dataMaxBuffer[id] + (ushort4)dataMinBuffer[id]) / 2);

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
//                          device uchar4 *preambleBuffer [[ buffer(1) ]],
//                          device uchar4 *matchBuffer [[ buffer(2) ]],
//                          device uchar4 *minBuffer [[ buffer(3) ]],
//                          device uchar4 *maxBuffer [[ buffer(4) ]],
//                          device uchar4 *dataBuffer [[ buffer(5) ]],
//                          device uchar4 *baselineMinBuffer [[ buffer(6) ]],
//                          device uchar4 *baselineMaxBuffer [[ buffer(7) ]],
//                          const device uchar4 *prevImage1 [[ buffer(8) ]],
//                          const device uchar4 *prevImage2 [[ buffer(9) ]],
//                          const device uchar4 *prevImage3 [[ buffer(10) ]],
//                          const device uchar4 *prevImage4 [[ buffer(11) ]],
//                          const device uchar4 *prevImage5 [[ buffer(12) ]],
//                          device uchar4 *dataMinBuffer [[ buffer(13) ]],
//                          device uchar4 *dataMaxBuffer [[ buffer(14) ]],
//                          uint id [[ thread_position_in_grid ]]
//                          ) {
//        /* preamble detector */
//    if (matchBuffer[id][0] == 0 && matchBuffer[id][1] == 0 && matchBuffer[id][2] == 0 && matchBuffer[id][3] == 0) {
//        /* update min and max for threshold calculation */
//        minBuffer[id] = min(minBuffer[id], image[id]);
//        maxBuffer[id] = max(maxBuffer[id], image[id]);
//        uchar4 thresh = (maxBuffer[id] + minBuffer[id]) / 2;
//
//        /* determine whether frame is a 0 or a 1 */
//        bool4 binaryPixel = image[id] > thresh;
//
//        /* apply current frame binary value to history buffer */
//        uchar4 possiblePreamble = preambleBuffer[id];
//        possiblePreamble = (possiblePreamble << 1) | (uchar4)binaryPixel;
//        preambleBuffer[id] = possiblePreamble;
//
//        /* if history buffer matches preamble start decoding bit 1 of the data */
//        uchar4 match = (uchar4)(((preamble ^ possiblePreamble) == 0) || (bool4)matchBuffer[id]);
//        matchBuffer[id] = match;
//
////        for (int i=0; i<4; i++) {
////            if (match[i] != 0) {
////                uchar dataMin = 0xFF;
////                uchar dataMax = 0;
////
////                if (image[id][i] < dataMin) dataMin = image[id][i];
////                if (prevImage1[id][i] < dataMin) dataMin = prevImage1[id][i];
////                if (prevImage2[id][i] < dataMin) dataMin = prevImage2[id][i];
////                if (prevImage3[id][i] < dataMin) dataMin = prevImage3[id][i];
////                if (prevImage4[id][i] < dataMin) dataMin = prevImage4[id][i];
////                if (prevImage5[id][i] < dataMin) dataMin = prevImage5[id][i];
////                if (image[id][i] > dataMax) dataMax = image[id][i];
////                if (prevImage1[id][i] > dataMax) dataMax = prevImage1[id][i];
////                if (prevImage2[id][i] > dataMax) dataMax = prevImage2[id][i];
////                if (prevImage3[id][i] > dataMax) dataMax = prevImage3[id][i];
////                if (prevImage4[id][i] > dataMax) dataMax = prevImage4[id][i];
////                if (prevImage5[id][i] > dataMax) dataMax = prevImage5[id][i];
////                dataMinBuffer[id][i] = dataMin;
////                dataMaxBuffer[id][i] = dataMax;
////            }
////        }
//
//
//
//    } else {// data decoder
//        for (int i=0; i<4; i++) { /* iterate over each pixel of the vector data */
//            if (matchBuffer[id][i] != 0) { /* determine which pixels of the vector have matched the preamble */
//                if (matchBuffer[id][i] == 1) {//first bit of data
//                    dataBuffer[id][i] = 0;/* reset the data buffer to accept new data */
//                    baselineMinBuffer[id][i] = 0xFF;
//                    baselineMaxBuffer[id][i] = 0;
//                }
//                if (matchBuffer[id][i] <= NUM_DATA_BITS) {// decode data
//                    /* update min and max for threshold calculation */
//                    minBuffer[id] = min(minBuffer[id], image[id]);
//                    maxBuffer[id] = max(maxBuffer[id], image[id]);
//                    uchar4 thresh = (maxBuffer[id] - minBuffer[id]) / 2;
//
//                    /* determine whether frame is a 0 or a 1 */
//                    uchar binaryPixel = (uchar)(image[id][i] > thresh[i]);
//                    /* apply current frame binary value to data buffer */
//                    dataBuffer[id][i] = (dataBuffer[id][i] << 1) | binaryPixel;
//                    matchBuffer[id][i]++;
//                } else if (matchBuffer[id][i] <= NUM_DATA_BITS + NUM_SNR_BASELINE_BITS) {/* baseline max and min for SNR */
//                    baselineMinBuffer[id][i] = min(baselineMinBuffer[id][i], image[id][i]);
//                    baselineMaxBuffer[id][i] = max(baselineMaxBuffer[id][i], image[id][i]);
//
//                    matchBuffer[id][i]++;
//                } else {
//                    matchBuffer[id][i] = 0;
//                }
//            }
//        }
//    }
//
//
//
//}


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

