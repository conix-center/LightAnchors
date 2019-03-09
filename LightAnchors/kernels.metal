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

//#define NUM_PREAMBLE_BITS 6
//#define NUM_DATA_BITS 6
#define NUM_SNR_BASELINE_BITS 4

#define NUM_DATA_CODES 32
#define NUM_DATA_BUFFERS 16
#define NUM_BASELINE_BUFFERS 4
#define SNR_THRESHOLD 2



using namespace metal;

//constant char threshold [[ function_constant(0) ]];
//constant char preamble [[ function_constant(1) ]];



/* iterate over entire preamble every frame */
kernel void matchPreamble(
                          const device uchar4 *image [[ buffer(0) ]],
                          device ushort *dataCodesBuffer [[ buffer(1) ]],
                          device ushort4 *actualDataBuffer [[ buffer(2) ]],
                          device uint4 *matchBuffer [[ buffer(3) ]],
                          device uchar4 *dataMinBuffer [[ buffer(4) ]],
                          device uchar4 *dataMaxBuffer [[ buffer(5) ]],
                          device uchar4 *baselineMinBuffer [[ buffer(6) ]],
                          device uchar4 *baselineMaxBuffer [[ buffer(7) ]],
                          device uchar4 *matchCounterBuffer [[ buffer(8) ]],
                          const device uchar4 *prevImage1 [[ buffer(9) ]],
                          const device uchar4 *prevImage2 [[ buffer(10) ]],
                          const device uchar4 *prevImage3 [[ buffer(11) ]],
                          const device uchar4 *prevImage4 [[ buffer(12) ]],
                          const device uchar4 *prevImage5 [[ buffer(13) ]],
                          const device uchar4 *prevImage6 [[ buffer(14) ]],
                          const device uchar4 *prevImage7 [[ buffer(15) ]],
                          const device uchar4 *prevImage8 [[ buffer(16) ]],
                          const device uchar4 *prevImage9 [[ buffer(17) ]],
                          const device uchar4 *prevImage10 [[ buffer(18) ]],
                          const device uchar4 *prevImage11 [[ buffer(19) ]],
                          const device uchar4 *prevImage12 [[ buffer(20) ]],
                          const device uchar4 *prevImage13 [[ buffer(21) ]],
                          const device uchar4 *prevImage14 [[ buffer(22) ]],
                          const device uchar4 *prevImage15 [[ buffer(23) ]],
                          
                          const device uchar4 *prevImage16 [[ buffer(24) ]],
                          const device uchar4 *prevImage17 [[ buffer(25) ]],
                          const device uchar4 *prevImage18 [[ buffer(26) ]],
                          const device uchar4 *prevImage19 [[ buffer(27) ]],
 
                          uint id [[ thread_position_in_grid ]]
                          ) {
    /* preamble detector */
    if (matchBuffer[id][0] == 0 && matchBuffer[id][1] == 0 && matchBuffer[id][2] == 0 && matchBuffer[id][3] == 0) {
        
        uchar4 baselineBuffers[NUM_BASELINE_BUFFERS];
        baselineBuffers[0] = prevImage19[id];
        baselineBuffers[1] = prevImage18[id];
        baselineBuffers[2] = prevImage17[id];
        baselineBuffers[3] = prevImage16[id];
        
        uchar4 imageBuffers[NUM_DATA_BUFFERS];
        imageBuffers[0] = prevImage15[id];
        imageBuffers[1] = prevImage14[id];
        imageBuffers[2] = prevImage13[id];
        imageBuffers[3] = prevImage12[id];
        imageBuffers[4] = prevImage11[id];
        imageBuffers[5] = prevImage10[id];
        imageBuffers[6] = prevImage9[id];
        imageBuffers[7] = prevImage8[id];
        imageBuffers[8] = prevImage7[id];
        imageBuffers[9] = prevImage6[id];
        imageBuffers[10] = prevImage5[id];
        imageBuffers[11] = prevImage4[id];
        imageBuffers[12] = prevImage3[id];
        imageBuffers[13] = prevImage2[id];
        imageBuffers[14] = prevImage1[id];
        imageBuffers[15] = image[id];
        
        /* calculate threshold */
        /* looking at previous images and current images means that the first bit of data we are looking for must be 1 */
        uchar4 minValue = min(0xFF, image[id]);
        uchar4 maxValue = max(0, image[id]);
        for (int i = 10; i<16; i++) {
            uchar4 buffer = imageBuffers[i];
            minValue = min(minValue, buffer);
            maxValue = max(maxValue, buffer);
        }
        uchar4 thresh = (uchar4)(((ushort4)maxValue+(ushort4)minValue)/2);
        
        ushort4 bit = (ushort4)(image[id] > thresh);
        
        actualDataBuffer[id] = (actualDataBuffer[id] << 1) | bit;
      //  ushort4 restrictedActualData = actualDataBuffer[id] & 0x0FFF;
        ushort4 restrictedActualData = actualDataBuffer[id];
        uint4 matches = 0;
        for (int i=0; i<NUM_DATA_CODES; i++) {
            ushort dataCode = dataCodesBuffer[i];
            ushort4 match = (ushort4)((restrictedActualData ^ dataCode) == 0);
            matches = matches << 1;
            matches |= (uint4)match;
            
        }

        
        if (any(matches != 0) ) {
            uchar4 baselineMinValue = 0xFF;
            uchar4 baselineMaxValue = 0;
            for (int i=0; i<NUM_BASELINE_BUFFERS; i++) {
                uchar4 buffer = baselineBuffers[i][id];
                baselineMinValue = min(baselineMinValue, buffer);
                baselineMaxValue = max(baselineMaxValue, buffer);
            }
            uchar4 snr = (maxValue-minValue)/ (baselineMaxValue-baselineMinValue);
            uint4 acceptMask = (uint4)(snr > SNR_THRESHOLD) * 0xFFFF;
            uint4 acceptedMatches = matches & acceptMask;
            matchBuffer[id] = acceptedMatches;
        }
        
 

        
        
        
    } else {
        /* how long to keep matches for */
        matchCounterBuffer[id] += (uchar4)(matchBuffer != 0);
        if (any(matchCounterBuffer[id] == 20)) {
            matchCounterBuffer[id] = 0;
            matchBuffer[id] = 0;
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

