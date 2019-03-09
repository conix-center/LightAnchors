//
//  LightDecoder.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 1/31/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

import UIKit
import MetalPerformanceShaders
import MetalKit


protocol LightDecoderDelegate {
    
    func lightDecoder(_ :LightDecoder, didUpdateResultImage resultImage: UIImage)
}


class CapturedImage {
    
    let image: UIImage
    let name: String
    
    

    
    init(image: UIImage, name: String) {
        self.image = image
        self.name = name
       
    }

}

class LightDecoder: NSObject {

    let maxFrameBuffers = 10
    
    var frameBuffers = NSMutableArray()//Array<CVPixelBuffer>()
    
    let fileNameDateFormatter = DateFormatter()
    
    //var imageDataArray: [Data] = []
    
  
    var imageBufferArray = [MTLBuffer]()
    var processingImageBuffers = false
    
    var width = 1440
    
    var device:MTLDevice?
    var library:MTLLibrary?
    var commandQueue:MTLCommandQueue?
    
    var differenceFunction:MTLFunction?
    var maxFunction: MTLFunction?
    var matchPreambleFunction: MTLFunction?
    var blurFunction: MPSImageGaussianBlur?
    
    var delegate: LightDecoderDelegate?
    
    override init() {
        super.init()
        NSLog("LightDecoder init")
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        
        initializeMetal()
    }
    
    
    func initializeMetal() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        NSLog("documents: %@", documentsPath)
        device = MTLCreateSystemDefaultDevice()
        let libraryPath = Bundle.main.path(forResource: "kernels", ofType: "metal")
        NSLog("libraryPath: \(libraryPath)")
        if  let lPath = libraryPath{
            
            do {
                if let device = self.device {
                    try library = device.makeLibrary(source: lPath, options: nil)
                }
            } catch {
                NSLog("error making a library")
            }
        } else {
            NSLog("Cannot find library path")
            if let device = self.device {
           
                self.library = device.makeDefaultLibrary()
                if let library = self.library {
                    self.differenceFunction = library.makeFunction(name: "difference")
                    self.maxFunction = library.makeFunction(name: "max")
                   // setupMatchPreamble()
                }
                
            }
        }
        if let device = self.device {
            commandQueue = device.makeCommandQueue()
        }
    }
    
    
    func add(image: UIImage) {
      //  frameBuffers.append(buffer)
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.png", dateString)
        //MemoryLayout.size(ofValue: coreImage)
        let capturedImage = CapturedImage(image: image, name: fileName)
        NSLog("capturedImage.size width: %f height: %f", capturedImage.image.size.width, capturedImage.image.size.height)
        frameBuffers.add(capturedImage)
        if frameBuffers.count > maxFrameBuffers {
            //frameBuffers.removeObject(at: 0)
            var data = Data()
            for cImage in frameBuffers  {
                let caImage = cImage as! CapturedImage
                NSLog("saving to file")
                //caImage.image.saveToFile(named: caImage.name)
                if let imageData = caImage.image.pngData() {
                    data.append(imageData)
                }
            }
            
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            if let filePath = paths.first?.appendingPathComponent(fileName) {
                // Save image.
                do {
                    try data.write(to: filePath, options: .atomic)
                }
                catch {
                    // Handle the error
                }
            }
            
            frameBuffers.removeAllObjects()
        }
    }
    
    
    

    class DataFile {
        let data: Data
        let fileName: String
        
        init(data: Data, fileName: String) {
            self.data = data
            self.fileName = fileName
        }
    }
    
    var dataFileArray = [DataFile]()
    var processingDataFiles = false
    var savingFiles = false
    var shouldSave = false
    
    func addToArrayForSaving(imageBytes: UnsafeRawPointer, length: Int) {
        let data = Data(bytes: imageBytes, count: length)
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.data", dateString)
        let dataFile = DataFile(data: data, fileName: fileName)
        if savingFiles == false {
            if shouldSave == true {
                dataFileArray.append(dataFile)
            
                if dataFileArray.count >= 90 {
                    savingFiles = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        
                        for dataFile in self.dataFileArray {
                            NSLog("Saving file")
                            self.write(imageData: dataFile.data, to: dataFile.fileName)
                        }
                        self.dataFileArray.removeAll()
                        self.savingFiles = false
                        self.shouldSave = false
                    }
                }
            }
        } else {
            shouldSave = false
        }
    }
    
    
    
    func write(imageData: Data, to fileName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            // Save image.
            do {
                try imageData.write(to: filePath, options: .atomic)
            }
            catch {
                // Handle the error
            }
        }
        
    }
    

    
  
   
    
    func add(imageBytes: UnsafeRawPointer, length: Int) {
        
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        
        
     
        guard let imageBuffer:MTLBuffer = device.makeBuffer(bytes: imageBytes, length: length, options: .storageModeShared) else {
            NSLog("Cannot create image buffer")
            return
        }

        
        
        if processingImageBuffers == false {
            imageBufferArray.append(imageBuffer)
        
            if imageBufferArray.count >= 90 {
                processingImageBuffers = true
                DispatchQueue.global(qos: .userInitiated).async {
                    let startTime = Date().timeIntervalSince1970
                    var prevBuffer = self.imageBufferArray[0]
                    for bufferIndex in 1..<self.imageBufferArray.count {
                        let buffer = self.imageBufferArray[bufferIndex]
                        self.compare( buffer, to: prevBuffer)
                        prevBuffer = buffer
                    }
                    self.imageBufferArray.removeAll()
                    let endTime = Date().timeIntervalSince1970
                    let runTime = endTime-startTime
                    NSLog("run time: %lf", runTime)
                    self.processingImageBuffers = false
                }
            }
        }
        
        

    }
    
    
    func compare(_ imageBuffer: MTLBuffer, to prevImageBuffer: MTLBuffer) {

        
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        

        
        if imageBuffer.length != prevImageBuffer.length {
            NSLog("buffers do not match")
            return
        }
        let length = imageBuffer.length
        
        guard let diffBuffer = device.makeBuffer(length: length, options: .storageModePrivate) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let commandQueue = self.commandQueue else {
            NSLog("No command queue")
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Cannot make command buffer")
            return
        }

//        guard let library = self.library else {
//            NSLog("No library")
//            return
//        }
        
        guard let differenceFunction = self.differenceFunction else {
            NSLog("Cannot make difference function")
            return
        }
        
        guard let differenceComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            NSLog("Cannot make compute command encoder")
            return
        }
        
        var differenceComputePipelineState: MTLComputePipelineState?
        do {
            differenceComputePipelineState = try device.makeComputePipelineState(function: differenceFunction)
        } catch {
            NSLog("Error making compute pipeline state")
            differenceComputeCommandEncoder.endEncoding()
            return
        }
        
        guard let differencePipelineState = differenceComputePipelineState else {
            NSLog("No compute pipeline state")
            differenceComputeCommandEncoder.endEncoding()
            return
        }
        
        differenceComputeCommandEncoder.setBuffer(prevImageBuffer, offset: 0, index: 0)
        differenceComputeCommandEncoder.setBuffer(imageBuffer, offset: 0, index: 1)
        differenceComputeCommandEncoder.setBuffer(diffBuffer, offset: 0, index: 2)
        differenceComputeCommandEncoder.setComputePipelineState(differencePipelineState)
        
        let differenceThreadExecutionWidth = differencePipelineState.threadExecutionWidth
    //    NSLog("threadExecutionWidth: %d", differenceThreadExecutionWidth)
        let differenceThreadsPerGroup = MTLSize(width: differenceThreadExecutionWidth, height: 1, depth: 1)
        
        let differenceNumThreadGroups = MTLSize(width: /*1*/(length/4/*+threadExecutionWidth*/)/differenceThreadExecutionWidth, height: 1, depth: 1)
        differenceComputeCommandEncoder.dispatchThreadgroups(differenceNumThreadGroups, threadsPerThreadgroup: differenceThreadsPerGroup)
        differenceComputeCommandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        
        let maxNumThreads = 128
        
        guard let maxValueBuffer = device.makeBuffer(length: maxNumThreads, options: .storageModeShared) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let maxIndexBuffer = device.makeBuffer(length: maxNumThreads*4, options: .storageModeShared) else {
            NSLog("Cannot make result buffer")
            return
        }
        
        guard let maxFunction = self.maxFunction else {
            NSLog("Cannot make max function")
            return
        }
        
        guard let maxCommandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Cannot make command buffer")
            return
        }
        
        guard let maxComputeCommandEncoder = maxCommandBuffer.makeComputeCommandEncoder() else {
            NSLog("Cannot make max compute command encoder")
            return
        }
        
        var maxComputePipelineState: MTLComputePipelineState?
        do {
            maxComputePipelineState = try device.makeComputePipelineState(function: maxFunction)
        } catch {
            NSLog("Error making compute pipeline state")
            maxComputeCommandEncoder.endEncoding()
            return
        }
        
        guard let maxPipelineState = maxComputePipelineState else {
            NSLog("No compute pipeline state")
            maxComputeCommandEncoder.endEncoding()
            return
        }
        
        maxComputeCommandEncoder.setBuffer(diffBuffer, offset: 0, index: 0)
        maxComputeCommandEncoder.setBuffer(maxValueBuffer, offset: 0, index: 1)
        maxComputeCommandEncoder.setBuffer(maxIndexBuffer, offset: 0, index: 2)
        maxComputeCommandEncoder.setComputePipelineState(maxPipelineState)
        
        let maxThreadExecutionWidth = maxPipelineState.threadExecutionWidth
   //     NSLog("threadExecutionWidth: %d", maxThreadExecutionWidth)
        let maxThreadsPerGroup = MTLSize(width: differenceThreadExecutionWidth, height: 1, depth: 1)
        
        let maxNumThreadGroups = MTLSize(width: 4, height: 1, depth: 1)
        maxComputeCommandEncoder.dispatchThreadgroups(maxNumThreadGroups, threadsPerThreadgroup: maxThreadsPerGroup)
        maxComputeCommandEncoder.endEncoding()
        
        maxCommandBuffer.commit()
        maxCommandBuffer.waitUntilCompleted()
        
        var maxValue: UInt8 = 0
        var maxIndex = 0
        let maxValueArray: UnsafeMutablePointer<UInt8> = maxValueBuffer.contents().assumingMemoryBound(to: UInt8.self)
        let maxIndexArray: UnsafeMutablePointer<Int> = maxIndexBuffer.contents().assumingMemoryBound(to: Int.self)
        for i in 0..<maxNumThreads {
            if maxValueArray[i] > maxValue {
                maxValue = maxValueArray[i]
                maxIndex = maxIndexArray[i]
            }
        }
        
        NSLog("max value: %d at index: %d", maxValue, maxIndex)
        


    }
    
    
    var matchPreambleInitialized = false
    var evenFrame = false
    
    var decoding = 0

    
    func decode(imageBytes: UnsafeRawPointer, length: Int) {
        evenFrame = !evenFrame
        
        if decoding > 0 {
            NSLog("decoding count: %d", decoding)
        }
        decoding += 1
        
        let start = Date().timeIntervalSince1970
        if matchPreambleInitialized == false {
            setupMatchPreamble()
            matchPreambleInitialized = true
        }
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        guard let imageBuffer = device.makeBuffer(bytes: imageBytes, length: length, options: .storageModeShared) else {
            NSLog("Can't create image buffer")
            return
        }
        matchPreamble(imageBuffer: imageBuffer)
        let end = Date().timeIntervalSince1970
        NSLog("decode runtime: %f", end-start)
        decoding -= 1

    }
    
    let numberOfDataCodes = 32
    var dataCodesBuffer: MTLBuffer?
 
    var matchBufferOdd: MTLBuffer?
    var dataBufferOdd: MTLBuffer?

    var matchBufferEven: MTLBuffer?
    var dataBufferEven: MTLBuffer?
    var bufferLength = 0
    var baselineMinBufferOdd: MTLBuffer?
    var baselineMaxBufferOdd: MTLBuffer?
    var baselineMinBufferEven: MTLBuffer?
    var baselineMaxBufferEven: MTLBuffer?
    
    
    var minBuffer: MTLBuffer?
    var maxBuffer: MTLBuffer?
    
    var oddBufferArray = [MTLBuffer]()
    var evenBufferArray = [MTLBuffer]()
    
    var dataMinBufferOdd: MTLBuffer?
    var dataMaxBufferOdd: MTLBuffer?
    var dataMinBufferEven: MTLBuffer?
    var dataMaxBufferEven: MTLBuffer?
    
    
    var matchCounterBufferOdd: MTLBuffer?
    var matchCounterBufferEven: MTLBuffer?
    
    var inPlaceTexture: UnsafeMutablePointer<MTLTexture>?
    
    
    func setupMatchPreamble() {
        guard let library = self.library else {
            NSLog("no library")
            return
        }

        
        let constantValues = MTLFunctionConstantValues()
//        constantValues.setConstantValue(&threshold, type: .char, index: 0)
//        constantValues.setConstantValue(&preamble, type: .char, index: 1)
        
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        
        //   let blur = MPSImageGaussianBlur(device: device, sigma: 50)
        //    let blur = MPSImageMedian(device: device, kernelDiameter: 21)
        //  let blur = MPSImageBox(device: device, kernelWidth: 51, kernelHeight: 51)
        blurFunction = MPSImageGaussianBlur(device: device, sigma: 20)
        do {
            matchPreambleFunction = try library.makeFunction(name: "matchPreamble", constantValues: constantValues)
        } catch {
            NSLog("Error creating match preamble function")
        }
        
        bufferLength = 1920*1440
//        let  dataCodesArray: [UInt16] = [0x9556,0x9559,0x955a,0x9565,0x9566,0x9569,0x956a,0x9595,0x9596,0x9599,0x959a,0x95a5,0x95a6,0x95a9,0x95aa,0x9655,0x9656,0x9659,0x965a,0x9665,0x9666,0x9669,0x966a,0x9695,0x9696,0x9699,0x969a,0x96a5,0x96a6,0x96a9,0x96aa,0x9955]
        
        /* 12 bit codes */
        let  dataCodesArray: [UInt16] = [0x956,0x959,0x95a,0x965,0x966,0x969,0x96a,0x995,0x996,0x999,0x99a,0x9a5,0x9a6,0x9a9,0x9aa,0xa55,0xa56,0xa59,0xa5a,0xa65,0xa66,0xa69,0xa6a,0xa95,0xa96,0xa99,0xa9a,0xaa5,0xaa6,0xaa9,0xaaa,0x955];
        let dataCodesPtr: UnsafeMutablePointer<UInt16> = UnsafeMutablePointer(mutating: dataCodesArray)
        dataCodesBuffer = device.makeBuffer(bytes: dataCodesPtr, length: dataCodesArray.count*2, options: .storageModeShared)

        matchBufferOdd = device.makeBuffer(length: bufferLength*4, options: .storageModeShared)
        dataBufferOdd = device.makeBuffer(length: bufferLength*2, options: .storageModeShared)
        baselineMinBufferOdd = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMaxBufferOdd = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        

        matchBufferEven = device.makeBuffer(length: bufferLength*4, options: .storageModeShared)
        dataBufferEven = device.makeBuffer(length: bufferLength*2, options: .storageModeShared)
        baselineMinBufferEven = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMaxBufferEven = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        dataMinBufferOdd = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMaxBufferOdd = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMinBufferEven = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMaxBufferEven = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        matchCounterBufferOdd = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        matchCounterBufferEven = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        inPlaceTexture = UnsafeMutablePointer<MTLTexture>.allocate(capacity: 1)
        
        self.minBuffer = device.makeBuffer(length: bufferLength, options:.storageModeShared)
        if let minBuffer = self.minBuffer {
            let minArray = minBuffer.contents().assumingMemoryBound(to: UInt8.self)
            for i in 0..<bufferLength {
                minArray[i] = 0xFF;
            }
        }
        self.maxBuffer = device.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        
    }
    
    
    func matchPreamble(imageBuffer: MTLBuffer) {
        guard let device = self.device else {
            NSLog("no device")
            return
        }
        
        var hBuffer: MTLBuffer?
        var mBuffer: MTLBuffer?
        var dBuffer: MTLBuffer?
        var baselineMinBufferOpt: MTLBuffer?
        var baselineMaxBufferOpt: MTLBuffer?
        var prevBuffer1: MTLBuffer?
        var prevBuffer2: MTLBuffer?
        var prevBuffer3: MTLBuffer?
        var prevBuffer4: MTLBuffer?
        var prevBuffer5: MTLBuffer?
        var prevBuffer6: MTLBuffer?
        var prevBuffer7: MTLBuffer?
        var prevBuffer8: MTLBuffer?
        var prevBuffer9: MTLBuffer?
        var prevBuffer10: MTLBuffer?
        var prevBuffer11: MTLBuffer?
        var prevBuffer12: MTLBuffer?
        var prevBuffer13: MTLBuffer?
        var prevBuffer14: MTLBuffer?
        var prevBuffer15: MTLBuffer?
        var prevBuffer16: MTLBuffer?
        var prevBuffer17: MTLBuffer?
        var prevBuffer18: MTLBuffer?
        var prevBuffer19: MTLBuffer?

        
        var dataMinBufferOpt: MTLBuffer?
        var dataMaxBufferOpt: MTLBuffer?
        
        var matchCounterBuffer: MTLBuffer?
        
        if evenFrame != true {//odd
            mBuffer = self.matchBufferOdd
            dBuffer = self.dataBufferOdd
            baselineMinBufferOpt = self.baselineMinBufferOdd
            baselineMaxBufferOpt = self.baselineMaxBufferOdd
            
            oddBufferArray.append(imageBuffer)
            while oddBufferArray.count > 20 {
                oddBufferArray.remove(at: 0)
            }
            if oddBufferArray.count < 20 {
                return
            }
            prevBuffer1 = oddBufferArray[18]
            prevBuffer2 = oddBufferArray[17]
            prevBuffer3 = oddBufferArray[16]
            prevBuffer4 = oddBufferArray[15]
            prevBuffer5 = oddBufferArray[14]
            prevBuffer6 = oddBufferArray[13]
            prevBuffer7 = oddBufferArray[12]
            prevBuffer8 = oddBufferArray[11]
            prevBuffer9 = oddBufferArray[10]
            prevBuffer10 = oddBufferArray[9]
            prevBuffer11 = oddBufferArray[8]
            prevBuffer12 = oddBufferArray[7]
            prevBuffer13 = oddBufferArray[6]
            prevBuffer14 = oddBufferArray[5]
            prevBuffer15 = oddBufferArray[4]
            prevBuffer16 = oddBufferArray[3]
            prevBuffer17 = oddBufferArray[2]
            prevBuffer18 = oddBufferArray[1]
            prevBuffer19 = oddBufferArray[0]
      
            
            dataMinBufferOpt = self.dataMinBufferOdd
            dataMaxBufferOpt = self.dataMaxBufferOdd
            
            
            matchCounterBuffer = self.matchCounterBufferOdd
            
        } else {

            mBuffer = self.matchBufferEven
            dBuffer = self.dataBufferEven
            baselineMinBufferOpt = self.baselineMinBufferEven
            baselineMaxBufferOpt = self.baselineMaxBufferEven
            
            evenBufferArray.append(imageBuffer)
            while evenBufferArray.count > 20 {
                evenBufferArray.remove(at: 0)
            }
            if evenBufferArray.count < 20 {
                return
            }
            
            prevBuffer1 = evenBufferArray[18]
            prevBuffer2 = evenBufferArray[17]
            prevBuffer3 = evenBufferArray[16]
            prevBuffer4 = evenBufferArray[15]
            prevBuffer5 = evenBufferArray[14]
            prevBuffer6 = evenBufferArray[13]
            prevBuffer7 = evenBufferArray[12]
            prevBuffer8 = evenBufferArray[11]
            prevBuffer9 = evenBufferArray[10]
            prevBuffer10 = evenBufferArray[9]
            prevBuffer11 = evenBufferArray[8]
            prevBuffer12 = evenBufferArray[7]
            prevBuffer13 = evenBufferArray[6]
            prevBuffer14 = evenBufferArray[5]
            prevBuffer15 = evenBufferArray[4]
            prevBuffer16 = evenBufferArray[3]
            prevBuffer17 = evenBufferArray[2]
            prevBuffer18 = evenBufferArray[1]
            prevBuffer19 = evenBufferArray[0]
            
            dataMinBufferOpt = self.dataMinBufferEven
            dataMaxBufferOpt = self.dataMaxBufferEven
            
            matchCounterBuffer = self.matchCounterBufferEven
            
        }
        
        guard let dataCodesBuffer = self.dataCodesBuffer else {
            NSLog("no data codes buffer")
            return
        }
        
        guard let matchBuffer = mBuffer else {
            NSLog("no match buffer")
            return
        }
        
        guard let actualDataBuffer = dBuffer else {
            NSLog("no data buffer")
            return
        }
        
        guard let baselineMinBuffer = baselineMinBufferOpt else {
            NSLog("no baseline min buffer")
            return
        }
        
        guard let baselineMaxBuffer = baselineMaxBufferOpt else {
            NSLog("no baseline max buffer")
            return
        }
        
        guard let prevImageBuffer1 = prevBuffer1 else {
            NSLog("no prevBuffer1")
            return
        }
        
        guard let prevImageBuffer2 = prevBuffer2 else {
            NSLog("no prevBuffer2")
            return
        }
        
        guard let prevImageBuffer3 = prevBuffer3 else {
            NSLog("no prevBuffer3")
            return
        }
        
        guard let prevImageBuffer4 = prevBuffer4 else {
            NSLog("no prevBuffer4")
            return
        }
        
        guard let prevImageBuffer5 = prevBuffer5 else {
            NSLog("no prevBuffer5")
            return
        }
        
        guard let prevImageBuffer6 = prevBuffer6 else {
            NSLog("no prevBuffer1")
            return
        }
        
        guard let prevImageBuffer7 = prevBuffer7 else {
            NSLog("no prevBuffer2")
            return
        }
        
        guard let prevImageBuffer8 = prevBuffer8 else {
            NSLog("no prevBuffer3")
            return
        }
        
        guard let prevImageBuffer9 = prevBuffer9 else {
            NSLog("no prevBuffer4")
            return
        }
        
        guard let prevImageBuffer10 = prevBuffer10 else {
            NSLog("no prevBuffer5")
            return
        }
        
        guard let prevImageBuffer11 = prevBuffer11 else {
            NSLog("no prevBuffer1")
            return
        }
        
        guard let prevImageBuffer12 = prevBuffer12 else {
            NSLog("no prevBuffer2")
            return
        }
        
        guard let prevImageBuffer13 = prevBuffer13 else {
            NSLog("no prevBuffer3")
            return
        }
        
        guard let prevImageBuffer14 = prevBuffer14 else {
            NSLog("no prevBuffer4")
            return
        }
        
        guard let prevImageBuffer15 = prevBuffer15 else {
            NSLog("no prevBuffer5")
            return
        }
        
        guard let prevImageBuffer16 = prevBuffer16 else {
            NSLog("no prevBuffer1")
            return
        }
        
        guard let prevImageBuffer17 = prevBuffer17 else {
            NSLog("no prevBuffer2")
            return
        }
        
        guard let prevImageBuffer18 = prevBuffer18 else {
            NSLog("no prevBuffer3")
            return
        }
        
        guard let prevImageBuffer19 = prevBuffer19 else {
            NSLog("no prevBuffer3")
            return
        }

        
        guard let dataMinBuffer = dataMinBufferOpt else {
            NSLog("no data min buffer")
            return
        }
        
        guard let dataMaxBuffer = dataMaxBufferOpt else {
            NSLog("no data max buffer")
            return
        }
        
  
        

        let length = imageBuffer.length
        
        
        guard let commandQueue = self.commandQueue else {
            NSLog("No command queue")
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Cannot make command buffer")
            return
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm/*.a8Unorm*/, width: 1920, height: 1440, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        guard var texture = imageBuffer.makeTexture(descriptor: descriptor, offset: 0, bytesPerRow: 1920) else {
            NSLog("no texture")
            return
        }


        guard let blurFunction = self.blurFunction else {
            NSLog("no blur function")
            return
        }
        blurFunction.encode(commandBuffer: commandBuffer, inPlaceTexture: &texture)

        

//        commandBuffer.commit()
//        commandBuffer.waitUntilCompleted()
//        let imageArray = imageBuffer.contents().assumingMemoryBound(to: UInt8.self)
//        let image = UIImage.image(buffer: imageArray, length: 1920*1440, rowWidth: 1920)

        
        

        guard let matchPreambleFunction = self.matchPreambleFunction else {
            NSLog("Cannot make difference function")
            return
        }

        guard let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            NSLog("Cannot make compute command encoder")
            return
        }

        var computePipelineState: MTLComputePipelineState?
        do {
            computePipelineState = try device.makeComputePipelineState(function: matchPreambleFunction)
        } catch {
            NSLog("Error making compute pipeline state")
            computeCommandEncoder.endEncoding()
            return
        }

        guard let pipelineState = computePipelineState else {
            NSLog("No compute pipeline state")
            computeCommandEncoder.endEncoding()
            return
        }

        computeCommandEncoder.setBuffer(imageBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(dataCodesBuffer, offset: 0, index: 1)
        computeCommandEncoder.setBuffer(actualDataBuffer, offset: 0, index: 2)
        computeCommandEncoder.setBuffer(matchBuffer, offset: 0, index: 3)
        computeCommandEncoder.setBuffer(dataMinBuffer, offset: 0, index: 4)
        computeCommandEncoder.setBuffer(dataMaxBuffer, offset: 0, index: 5)
        computeCommandEncoder.setBuffer(baselineMinBuffer, offset: 0, index: 6)
        computeCommandEncoder.setBuffer(baselineMaxBuffer, offset: 0, index: 7)
        computeCommandEncoder.setBuffer(matchCounterBuffer, offset: 0, index: 8)

        computeCommandEncoder.setBuffer(prevImageBuffer1, offset: 0, index: 9)
        computeCommandEncoder.setBuffer(prevImageBuffer2, offset: 0, index: 10)
        computeCommandEncoder.setBuffer(prevImageBuffer3, offset: 0, index: 11)
        computeCommandEncoder.setBuffer(prevImageBuffer4, offset: 0, index: 12)
        computeCommandEncoder.setBuffer(prevImageBuffer5, offset: 0, index: 13)
        computeCommandEncoder.setBuffer(prevImageBuffer6, offset: 0, index: 14)
        computeCommandEncoder.setBuffer(prevImageBuffer7, offset: 0, index: 15)
        computeCommandEncoder.setBuffer(prevImageBuffer8, offset: 0, index: 16)
        computeCommandEncoder.setBuffer(prevImageBuffer9, offset: 0, index: 17)
        computeCommandEncoder.setBuffer(prevImageBuffer10, offset: 0, index: 18)
        computeCommandEncoder.setBuffer(prevImageBuffer11, offset: 0, index: 19)
        computeCommandEncoder.setBuffer(prevImageBuffer12, offset: 0, index: 20)
        computeCommandEncoder.setBuffer(prevImageBuffer13, offset: 0, index: 21)
        computeCommandEncoder.setBuffer(prevImageBuffer14, offset: 0, index: 22)
        computeCommandEncoder.setBuffer(prevImageBuffer15, offset: 0, index: 23)
        computeCommandEncoder.setBuffer(prevImageBuffer16, offset: 0, index: 24)
        computeCommandEncoder.setBuffer(prevImageBuffer17, offset: 0, index: 25)
        computeCommandEncoder.setBuffer(prevImageBuffer18, offset: 0, index: 26)
        computeCommandEncoder.setBuffer(prevImageBuffer19, offset: 0, index: 27)


        computeCommandEncoder.setComputePipelineState(pipelineState)

        let threadExecutionWidth = pipelineState.threadExecutionWidth
  //      NSLog("threadExecutionWidth: %d", threadExecutionWidth)
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)

        let numThreadGroups = MTLSize(width: /*1*/(length/4/*+threadExecutionWidth*/)/threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadGroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
 
        
        frameCountForImageRender += 1
        if frameCountForImageRender == 20 {
            frameCountForImageRender = 0
            updateResultImage()
        }

        
    }
    
    
    
    
    
    var frameCountForImageRender = 0
    
    func updateResultImage() {
        
        let length = 1920*1440
        
        
        guard let matchArrayOdd = matchBufferOdd?.contents().assumingMemoryBound(to: UInt32.self) else {
            NSLog("no match array odd")
            return
        }
        
        guard let matchArrayEven = matchBufferEven?.contents().assumingMemoryBound(to: UInt32.self) else {
            NSLog("no match array even")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let dataImageArray = UnsafeMutablePointer<UInt32>.allocate(capacity: length)
  //          let dataImageArrayNoSNR = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
            
            for i in 0..<length {
                if matchArrayOdd[i] != 0 || matchArrayEven[i] != 0 {
                    dataImageArray[i] = matchArrayOdd[i] | matchArrayEven[i]
                }
            }
            
            var dict = Dictionary<UInt32, Int>()
            for i in 0..<1920*1440 {
                let pixel: UInt32 = dataImageArray[i]
                if pixel != 0 {
                    if let count = dict[pixel] {
                        dict[pixel] = count + 1
                    } else {
                        dict[pixel] = 1
                    }
                }
            }
            
            for key in dict.keys {
                if let count = dict[key] {
                    NSLog("code: 0x%x count: %d", key, count)
                }
            }
            
            let rotatedImageArray = UnsafeMutablePointer<UInt32>.allocate(capacity: length)
            for row in 0..<1440 {
                for column in 0..<1920 {
                    rotatedImageArray[column*1440 + (1439-row)] = dataImageArray[row*1920+column]
                }
            }
            
            if let image = UIImage.colorImage(buffer: rotatedImageArray, length: length, rowWidth: 1440) {
                DispatchQueue.main.async {
                    self.delegate?.lightDecoder(self, didUpdateResultImage: image)
                }
            }

            free(dataImageArray)
      //      free(dataImageArrayNoSNR)
            free(rotatedImageArray)
            
            
        }
        
    }

    
    
    
    
    
    
    
    func evaluateResults() {
        guard let matchBufferOdd = self.matchBufferOdd else {
            NSLog("no match buffer")
            return
        }
        
        let length = 1920*1440
        
        let matchArrayOdd = matchBufferOdd.contents().assumingMemoryBound(to: UInt8.self)
        var numberOfPreambleMatchesOdd = 0
        for i in 0..<bufferLength {
            if matchArrayOdd[i] == 1 {
                numberOfPreambleMatchesOdd += 1
            }
        }
//        for i in 0..<100 {
//            NSLog("his odd 0x%x", matchArrayOdd[i])
//        }

        
        guard let minArray = self.minBuffer?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no minArray")
            return
        }
        let minImage = UIImage.image(buffer: minArray, length: 1920*1440, rowWidth: 1920)
        
        guard let maxArray = self.maxBuffer?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no maxArray")
            return
        }
        let maxImage = UIImage.image(buffer: maxArray, length: 1920*1440, rowWidth: 1920)
        
        var historyBufferImageOdd: UIImage?
        var historyBufferImageEven: UIImage?
        

        

        
        
        
        guard let matchBufferEven = self.matchBufferEven else {
            NSLog("no match buffer")
            return
        }
        let matchArrayEven = matchBufferEven.contents().assumingMemoryBound(to: UInt8.self)
        var numberOfPreambleMatchesEven = 0
        for i in 0..<bufferLength {
            if matchArrayEven[i] == 1 {
                numberOfPreambleMatchesEven += 1
            }
        }
        if let maxArray = self.maxBuffer?.contents().assumingMemoryBound(to: UInt8.self), let minArray = self.minBuffer?.contents().assumingMemoryBound(to: UInt8.self) {
            for i in 0..<100 {
          //      NSLog("max: %d", maxArray[i])
            }
            for i in 0..<100 {
         //       NSLog("min: %d", minArray[i])
            }
        }
        

        
        var matchImageOdd: UIImage?
        var matchImageEven: UIImage?
        if let matchArrayOdd = self.matchBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) {
            var matchImageArrayOdd = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
            for i in 0..<length {
                if matchArrayOdd[i] != 0 {
                    matchImageArrayOdd[i] = 0xFF
                }
            }
            matchImageOdd = UIImage.image(buffer: matchImageArrayOdd, length: length, rowWidth: 1920)
        }
        
        if let matchArrayEven = self.matchBufferEven?.contents().assumingMemoryBound(to: UInt8.self) {
            var matchImageArrayEven = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
            for i in 0..<length {
                if matchArrayEven[i] != 0 {
                    matchImageArrayEven[i] = 0xFF
                }
            }
            matchImageEven = UIImage.image(buffer: matchImageArrayEven, length: length, rowWidth: 1920)
        }
        
        var dataImageOdd: UIImage?
        var dataImageEven: UIImage?
        
        guard let dataArrayOdd = self.dataBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataArrayOdd")
            return
        }
        

        
        guard let baselineMinArrayOdd = self.baselineMinBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no baselinMinArrayOdd")
            return
        }
        guard let baselineMaxArrayOdd = self.baselineMaxBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no baselinMaxArrayOdd")
            return
        }
        
        guard let dataMinArrayOdd = self.dataMinBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataMaxArrayEven")
            return
        }
        
        guard let dataMaxArrayOdd = self.dataMaxBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataMaxArrayEven")
            return
        }
        
        let dataImageArrayOdd = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        let dataImageArrayOddNoSNR = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        
        var numOddMatchingData = 0
        var numOddMatchingDataAndSnr = 0
        for i in 0..<length {
            let snr = (Double(dataMaxArrayOdd[i])-Double(dataMinArrayOdd[i])) / (Double(baselineMaxArrayOdd[i])-Double(baselineMinArrayOdd[i]))

            if dataArrayOdd[i] == 0x2A {
           //     NSLog("odd max: %d, min: %d, snr: %f", dataMaxArrayOdd[i], dataMinArrayOdd[i], snr)
                numOddMatchingData += 1
                if snr > 10 && snr.isFinite {
                    numOddMatchingDataAndSnr += 1
                    dataImageArrayOdd[i] = 0xFF
                } else {
                    dataImageArrayOddNoSNR[i] = 0xFF
                }
            }
        }
        
        for i in 0..<200 {
            NSLog("data min: %d", dataMinArrayOdd[i])
            NSLog("data max: %d", dataMaxArrayOdd[i])
        }
        
        dataImageOdd = UIImage.image(buffer: dataImageArrayOdd, length: length, rowWidth: 1920)

        
        
        guard let dataArrayEven = self.dataBufferEven?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataArrayEven")
            return
        }
        
        guard let baselineMinArrayEven = self.baselineMinBufferEven?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no baselinMinArrayOdd")
            return
        }
        guard let baselineMaxArrayEven = self.baselineMaxBufferEven?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no baselinMaxArrayOdd")
            return
        }
        
        guard let dataMinArrayEven = self.dataMinBufferEven?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataMaxArrayEven")
            return
        }
        
        guard let dataMaxArrayEven = self.dataMaxBufferEven?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no dataMaxArrayEven")
            return
        }
        
        var numEvenMatchingData = 0
        var numEvenMatchingDataAndSnr = 0
        let dataImageArrayEven = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        let dataImageArrayEvenNoSNR = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        for i in 0..<length {
            let snr = (Double(dataMaxArrayEven[i])-Double(dataMinArrayEven[i])) / (Double(baselineMaxArrayEven[i])-Double(baselineMinArrayEven[i]))

            if dataArrayEven[i] == 0x2A {
             //   NSLog("even max: %d, min: %d, snr: %f", dataMaxArrayEven[i], dataMinArrayEven[i], snr)
                numEvenMatchingData += 1
                if snr > 10 && snr.isFinite {
                    numEvenMatchingDataAndSnr += 1
                    dataImageArrayEven[i] = 0xFF
                } else {
                    dataImageArrayEvenNoSNR[i] = 0xFF;
                }
            }
        }
        dataImageEven = UIImage.image(buffer: dataImageArrayEven, length: length, rowWidth: 1920)
     
        NSLog("number of preamble matches odd: %d", numberOfPreambleMatchesOdd)
        NSLog("num odd matching data: %d", numOddMatchingData)
        NSLog("num odd matching data and snr: %d", numOddMatchingDataAndSnr)
        NSLog("number of preamble matches even: %d", numberOfPreambleMatchesEven)
        NSLog("num even matching data: %d", numEvenMatchingData)
        NSLog("num even matching data and snr: %d", numEvenMatchingDataAndSnr)
        
        
        let dataImageArray = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        for i in 0..<length {
            dataImageArray[i] = dataImageArrayOdd[i] | dataImageArrayEven[i]
        }
        let dataImage = UIImage.image(buffer: dataImageArray, length: length, rowWidth: 1920)
        
        let dataImageArrayNoSNR = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        for i in 0..<length {
            dataImageArrayNoSNR[i] = dataImageArrayOddNoSNR[i] | dataImageArrayEvenNoSNR[i]
        }
 //       let dataImageNoSNR = UIImage.colorImage(buffer: dataImageArrayNoSNR, length: length, rowWidth: 1920)
        
        

        
        
        

        
    }
    
    
    
    
    
    
    

    
    
    
}


extension UIImage {
    
    class func image(buffer: UnsafeMutablePointer<UInt8>, length: Int, rowWidth: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let data = Data(bytes: buffer, count: length)
       
        guard let provider = CGDataProvider(data: data as CFData) else {
            NSLog("no provider")
            return nil
        }

        let bitmapInfo:CGBitmapInfo = .byteOrderMask
        
        let intent = CGColorRenderingIntent.defaultIntent
        
        let imageRef = CGImage(width: rowWidth, height: length/rowWidth, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: rowWidth, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: intent)
        guard let cgImage = imageRef else {
            NSLog("no imageRef")
            return nil
        }
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    
    class func colorImage(buffer: UnsafeMutablePointer<UInt32>, length: Int, rowWidth: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let redByte = 0
        let greenByte = 1
        let blueByte = 2
        let alphaByte = 3
        
        let bytesPerPixel = 4
        let colorBufferLength = length * bytesPerPixel
        let colorRowWidthBytes = rowWidth * bytesPerPixel
        
        let colorBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: colorBufferLength)
        let targetBit: UInt32 = 1 << 0 /* which code are we looking for */
        for i in 0..<length {
            if buffer[i] & targetBit != 0  {
                colorBuffer[i*bytesPerPixel + greenByte] = 0xFF;
                colorBuffer[i*bytesPerPixel + alphaByte] = 0xFF;
                if buffer[i] & ~targetBit != 0 {
                    colorBuffer[i*bytesPerPixel + redByte] = 0xFF;
                }
            } else if buffer[i] != 0 {
                colorBuffer[i*bytesPerPixel + redByte] = 0xFF;
                colorBuffer[i*bytesPerPixel + alphaByte] = 0xFF;
            }
        }
        
        let data = Data(bytes: colorBuffer, count: colorBufferLength)
        
        guard let provider = CGDataProvider(data: data as CFData) else {
            NSLog("no provider")
            return nil
        }
        
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)//.byteOrderMask
//        bitmapInfo |= CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue).rawValue
        
        let intent = CGColorRenderingIntent.defaultIntent
        
        let imageRef = CGImage(width: rowWidth, height: length/rowWidth, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: colorRowWidthBytes, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: intent)
        guard let cgImage = imageRef else {
            NSLog("no imageRef")
            return nil
        }
    
        let image = UIImage(cgImage: cgImage)
        free(colorBuffer)
        return image
    }
    
}
