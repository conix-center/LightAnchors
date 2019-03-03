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

#define NUM_PREAMBLE_BITS 12
#define NUM_DATA_BITS 6
#define NUM_SNR_BASELINE_BITS 4

#define MATCH_BIT_THRESHOLD 10




using namespace metal;

constant int convolutionThreshold [[ function_constant(0) ]];
//constant short preamble [[ function_constant(1) ]];



/* iterate over entire preamble every frame */
kernel void matchPreamble(
                          const device uchar4 *image [[ buffer(0) ]],
                          device int *preambleZeroCenterBuffer [[ buffer(1) ]],
//                          device uchar4 *preambleBuffer [[ buffer(2) ]],
                          device uchar4 *matchBuffer [[ buffer(2) ]],
//                          device uchar4 *minBuffer [[ buffer(4) ]],
//                          device uchar4 *maxBuffer [[ buffer(5) ]],
                          device uchar4 *dataBuffer [[ buffer(3) ]],
//                          device uchar4 *baselineMinBuffer [[ buffer(7) ]],
//                          device uchar4 *baselineMaxBuffer [[ buffer(8) ]],
                          const device uchar4 *prevImage1 [[ buffer(4) ]],
                          const device uchar4 *prevImage2 [[ buffer(5) ]],
                          const device uchar4 *prevImage3 [[ buffer(6) ]],
                          const device uchar4 *prevImage4 [[ buffer(7) ]],
                          const device uchar4 *prevImage5 [[ buffer(8) ]],
                          const device uchar4 *prevImage6 [[ buffer(9) ]],
                          const device uchar4 *prevImage7 [[ buffer(10) ]],
                          const device uchar4 *prevImage8 [[ buffer(11) ]],
                          const device uchar4 *prevImage9 [[ buffer(12) ]],
                          const device uchar4 *prevImage10 [[ buffer(13) ]],
                          const device uchar4 *prevImage11 [[ buffer(14) ]],
                          const device uchar4 *preambleBinaryBuffer [[ buffer(15) ]],
//                          device uchar4 *dataMinBuffer [[ buffer(20) ]],
//                          device uchar4 *dataMaxBuffer [[ buffer(21) ]],
                          uint id [[ thread_position_in_grid ]]
                          ) {
    
    if (all(matchBuffer[id] == 0)) {
    
        int4 pixelArray[12];
        
        pixelArray[11] = (int4)prevImage11[id];
        pixelArray[10] = (int4)prevImage10[id];
        pixelArray[9] = (int4)prevImage9[id];
        pixelArray[8] = (int4)prevImage8[id];
        pixelArray[7] = (int4)prevImage7[id];
        pixelArray[6] = (int4)prevImage6[id];
        pixelArray[5] = (int4)prevImage5[id];
        pixelArray[4] = (int4)prevImage4[id];
        pixelArray[3] = (int4)prevImage3[id];
        pixelArray[2] = (int4)prevImage2[id];
        pixelArray[1] = (int4)prevImage1[id];
        pixelArray[0] = (int4)image[id];
    
        /* check convolution */
        int4 sum = 0;
        for (int i=0; i<NUM_PREAMBLE_BITS; i++) {
            sum = sum + pixelArray[i];
        }
        int4 avg = sum/NUM_PREAMBLE_BITS;

        int4 convolution = 0;
        for (int i=0; i<NUM_PREAMBLE_BITS; i++) {
            convolution = convolution + preambleZeroCenterBuffer[i]*(pixelArray[NUM_PREAMBLE_BITS-1-i] - avg);
        }

        uchar4 match = (uchar4)(convolution>convolutionThreshold);
        
        
        /* check decoding */
        uchar4 maxValue = 0;
        uchar4 minValue = 0xFF;
        uchar4 threshold = 0;
        if (any(match != 0)) {
            for (int i=0; i< NUM_PREAMBLE_BITS; i++) {
                maxValue = max(maxValue, (uchar4)pixelArray[i]);
                minValue = min(minValue, (uchar4)pixelArray[i]);
            }
            threshold = maxValue/2 + minValue/2;
            
//            for (int i=0; i<NUM_PREAMBLE_BITS; i++) {
//                bool4 bit = (uchar4)pixelArray[NUM_PREAMBLE_BITS-1-i] > threshold;
//                uchar4 bitMatch = (uchar4)((bit ^ (bool4)preambleBinaryBuffer[i]) == 0);
//                match = match & bitMatch;
//
//            }
            
            ushort4 decodedValue = 0;
            for (int i=0; i< NUM_PREAMBLE_BITS; i++) {
                bool4 bit = (uchar4)pixelArray[NUM_PREAMBLE_BITS-1-i] > threshold;
                decodedValue = (decodedValue << 1) | (ushort4)bit;
            }
            
            ushort4 matchingBits = ~(decodedValue ^ 0xE32);
            uchar4 passesDecoding = (uchar4)(popcount(matchingBits) > MATCH_BIT_THRESHOLD);
            match = match & passesDecoding;
            
            
        }
        
        matchBuffer[id] = (uchar4)(match != 0 || matchBuffer[id] != 0) ;
    
    } else {
        // ideally start decoding here
        
        if (matchBuffer[id][0] != 0) {
            matchBuffer[id][0] += 1;
            if (matchBuffer[id][0] > 19) {
                    matchBuffer[id][0] = 0;
            }
        }
        if (matchBuffer[id][1] != 0) {
            matchBuffer[id][1] += 1;
            if (matchBuffer[id][1] > 19) {
                matchBuffer[id][1] = 0;
            }
        }
        if (matchBuffer[id][2] != 0) {
            matchBuffer[id][2] += 1;
            if (matchBuffer[id][2] > 19) {
                matchBuffer[id][2] = 0;
            }
        }
        if (matchBuffer[id][3] != 0) {
            matchBuffer[id][3] += 1;
            if (matchBuffer[id][3] > 19) {
                matchBuffer[id][3] = 0;
            }
        }
    }
    
    
//    /* preamble detector */
//    if (matchBuffer[id][0] == 0 && matchBuffer[id][1] == 0 && matchBuffer[id][2] == 0 && matchBuffer[id][3] == 0) {
//
//
//        uchar4 minValue = min(0xFF, image[id]);
//        minValue = min(minValue, prevImage1[id]);
//        minValue = min(minValue, prevImage2[id]);
//        minValue = min(minValue, prevImage3[id]);
//        minValue = min(minValue, prevImage4[id]);
//        minValue = min(minValue, prevImage5[id]);
//        uchar4 maxValue = max(0, image[id]);
//        maxValue = max(maxValue, prevImage1[id]);
//        maxValue = max(maxValue, prevImage2[id]);
//        maxValue = max(maxValue, prevImage3[id]);
//        maxValue = max(maxValue, prevImage4[id]);
//        maxValue = max(maxValue, prevImage5[id]);
//        uchar4 thresh = (uchar4)(((ushort4)maxValue+(ushort4)minValue)/2) ;//+ (maxValue-minValue)*3/4;
//
//
//        uchar4 bit = (uchar4)(prevImage5[id] > thresh);
//        uchar4 possiblePreamble =  bit;
//        bit = (uchar4)(prevImage4[id] > thresh);
//        possiblePreamble = (possiblePreamble << 1) | bit;
//        bit = (uchar4)(prevImage3[id] > thresh);
//        possiblePreamble = (possiblePreamble << 1) | bit;
//        bit = (uchar4)(prevImage2[id] > thresh);
//        possiblePreamble = (possiblePreamble << 1) | bit;
//        bit = (uchar4)(prevImage1[id] > thresh);
//        possiblePreamble = (possiblePreamble << 1) | bit;
//        bit = (uchar4)(image[id] > thresh);
//        possiblePreamble = (possiblePreamble << 1) | bit;
//
//        uchar4 match = (uchar4)((possiblePreamble ^ preamble) == 0);
//        matchBuffer[id] = match | matchBuffer[id];
//
//        if (match[0] != 0 || match[1] != 0 || match[2] != 0 || match[3] != 0) {
//            dataMinBuffer[id] = minValue;
//            dataMaxBuffer[id] = maxValue;
//        }
//
//        //debugging
//        preambleBuffer[id] = possiblePreamble;//possiblePreamble;
//
//
//
//    } else { /* data decoder */
//        for (int i=0; i<4; i++) { /* iterate over each pixel of the vector data */
//            if (matchBuffer[id][i] != 0) { /* determine which pixels of the vector have matched the preamble */
//                if (matchBuffer[id][i] == 1) {//first bit of data
//                    dataBuffer[id][i] = 0;/* reset the data buffer to accept new data */
//                    baselineMinBuffer[id][i] = 0xFF;
//                    baselineMaxBuffer[id][i] = 0;
//                }
//                if (matchBuffer[id][i] <= NUM_DATA_BITS) {// decode data
//                    /* update min and max for threshold calculation */
////                    minBuffer[id] = min(minBuffer[id], image[id]);
////                    maxBuffer[id] = max(maxBuffer[id], image[id]);
//                    uchar4 thresh = (uchar4)(((ushort4)dataMaxBuffer[id] + (ushort4)dataMinBuffer[id]) / 2);
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


//kernel void difference(const device char4 *imageA [[ buffer(0) ]],
//                       const device char4 *imageB [[ buffer(1) ]],
//                       device char4 *diff [[ buffer(2) ]],
//                       uint id [[ thread_position_in_grid ]] ) {
////    uint firstIndex = id * NUM_PIXELS_PER_THREAD;
////    uint endIndex = firstIndex+NUM_PIXELS_PER_THREAD;
////    for (uint i = firstIndex; i<endIndex; i++) {
////        char d = (char)abs(imageA[i]-imageB[i]);
////        diff[i] = d;
////    }
//
//    diff[id] = abs(imageA[id]-imageB[id]);
//
//}
//
//
//#define NUM_PIXELS_PER_THREAD 21600 //for 128 threads
//
//kernel void max(const device char *diff [[ buffer(0) ]],
//                device char *maxValueArray [[ buffer(1) ]],
//                device uint *maxIndexArray [[ buffer(2) ]],
//                uint id [[ thread_position_in_grid ]] ) {
//
//    uint firstIndex = id * NUM_PIXELS_PER_THREAD;
//    uint endIndex = firstIndex+NUM_PIXELS_PER_THREAD;
//    uint maxIndex = 0;
//    char maxValue = 0;
//    for (uint i = firstIndex; i<endIndex; i++) {
//        if (diff[i] > maxValue) {
//            maxValue = diff[i];
//            maxIndex = i;
//        }
//    }
//    maxValueArray[id] = maxValue;
//    maxIndexArray[id] = maxIndex;
//}

