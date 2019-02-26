//
//  LightDecoder.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 1/31/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

import UIKit

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
        NSLog("threadExecutionWidth: %d", differenceThreadExecutionWidth)
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
        NSLog("threadExecutionWidth: %d", maxThreadExecutionWidth)
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
//        evenFrame = !evenFrame
        
        NSLog("decoding count: %d", decoding)
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
    
    
    var historyBufferOdd: MTLBuffer?
    var matchBufferOdd: MTLBuffer?
    var dataBufferOdd: MTLBuffer?
    var historyBufferEven: MTLBuffer?
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
    
    
    func setupMatchPreamble() {
        guard let library = self.library else {
            NSLog("no library")
            return
        }
        var threshold = 80
        var preamble = 0x2A
        
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&threshold, type: .char, index: 0)
        constantValues.setConstantValue(&preamble, type: .char, index: 1)
        do {
            matchPreambleFunction = try library.makeFunction(name: "matchPreamble", constantValues: constantValues)
        } catch {
            NSLog("Error creating match preamble function")
        }
        
        bufferLength = 1920*1440
        historyBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        matchBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMinBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMaxBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        historyBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        matchBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMinBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        baselineMaxBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        dataMinBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMaxBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMinBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        dataMaxBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        self.minBuffer = device?.makeBuffer(length: bufferLength, options:.storageModeShared)
        if let minBuffer = self.minBuffer {
            let minArray = minBuffer.contents().assumingMemoryBound(to: UInt8.self)
            for i in 0..<bufferLength {
                minArray[i] = 0xFF;
            }
        }
        self.maxBuffer = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        
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
        
        var dataMinBufferOpt: MTLBuffer?
        var dataMaxBufferOpt: MTLBuffer?
        
        if evenFrame != true {//odd
            hBuffer = self.historyBufferOdd
            mBuffer = self.matchBufferOdd
            dBuffer = self.dataBufferOdd
            baselineMinBufferOpt = self.baselineMinBufferOdd
            baselineMaxBufferOpt = self.baselineMaxBufferOdd
            
            oddBufferArray.append(imageBuffer)
            while oddBufferArray.count > 6 {
                oddBufferArray.remove(at: 0)
            }
            if oddBufferArray.count < 6 {
                return
            }
            prevBuffer1 = oddBufferArray[4]
            prevBuffer2 = oddBufferArray[3]
            prevBuffer3 = oddBufferArray[2]
            prevBuffer4 = oddBufferArray[1]
            prevBuffer5 = oddBufferArray[0]
            
            dataMinBufferOpt = self.dataMinBufferOdd
            dataMaxBufferOpt = self.dataMaxBufferOdd
        } else {
            hBuffer = self.historyBufferEven
            mBuffer = self.matchBufferEven
            dBuffer = self.dataBufferEven
            baselineMinBufferOpt = self.baselineMinBufferEven
            baselineMaxBufferOpt = self.baselineMaxBufferEven
            
            evenBufferArray.append(imageBuffer)
            while evenBufferArray.count > 6 {
                evenBufferArray.remove(at: 0)
            }
            if evenBufferArray.count < 6 {
                return
            }
            
            prevBuffer1 = evenBufferArray[4]
            prevBuffer2 = evenBufferArray[3]
            prevBuffer3 = evenBufferArray[2]
            prevBuffer4 = evenBufferArray[1]
            prevBuffer5 = evenBufferArray[0]
            
            dataMinBufferOpt = self.dataMinBufferEven
            dataMaxBufferOpt = self.dataMaxBufferEven
            
        }
        
        guard let historyBuffer = hBuffer else {
            NSLog("no history buffer")
            return
        }
        
        guard let matchBuffer = mBuffer else {
            NSLog("no match buffer")
            return
        }
        
        guard let dataBuffer = dBuffer else {
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
        
        guard let dataMinBuffer = dataMinBufferOpt else {
            NSLog("no data min buffer")
            return
        }
        
        guard let dataMaxBuffer = dataMaxBufferOpt else {
            NSLog("no data max buffer")
            return
        }
        
  
        
        if imageBuffer.length != historyBuffer.length || imageBuffer.length != matchBuffer.length {
            NSLog("buffers do not match")
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
        computeCommandEncoder.setBuffer(historyBuffer, offset: 0, index: 1)
        computeCommandEncoder.setBuffer(matchBuffer, offset: 0, index: 2)
        computeCommandEncoder.setBuffer(minBuffer, offset: 0, index: 3)
        computeCommandEncoder.setBuffer(maxBuffer, offset: 0, index: 4)
        computeCommandEncoder.setBuffer(dataBuffer, offset: 0, index: 5)
        computeCommandEncoder.setBuffer(baselineMinBuffer, offset: 0, index: 6)
        computeCommandEncoder.setBuffer(baselineMaxBuffer, offset: 0, index: 7)
        computeCommandEncoder.setBuffer(prevImageBuffer1, offset: 0, index: 8)
        computeCommandEncoder.setBuffer(prevImageBuffer2, offset: 0, index: 9)
        computeCommandEncoder.setBuffer(prevImageBuffer3, offset: 0, index: 10)
        computeCommandEncoder.setBuffer(prevImageBuffer4, offset: 0, index: 11)
        computeCommandEncoder.setBuffer(prevImageBuffer5, offset: 0, index: 12)
        computeCommandEncoder.setBuffer(dataMinBuffer, offset: 0, index: 13)
        computeCommandEncoder.setBuffer(dataMaxBuffer, offset: 0, index: 14)
        computeCommandEncoder.setComputePipelineState(pipelineState)
        
        let threadExecutionWidth = pipelineState.threadExecutionWidth
        NSLog("threadExecutionWidth: %d", threadExecutionWidth)
        let threadsPerGroup = MTLSize(width: threadExecutionWidth, height: 1, depth: 1)
        
        let numThreadGroups = MTLSize(width: /*1*/(length/4/*+threadExecutionWidth*/)/threadExecutionWidth, height: 1, depth: 1)
        computeCommandEncoder.dispatchThreadgroups(numThreadGroups, threadsPerThreadgroup: threadsPerGroup)
        computeCommandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        NSLog("preamble match complete")
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
        
        guard let historyArrayOdd = self.historyBufferOdd?.contents().assumingMemoryBound(to: UInt8.self) else {
            NSLog("no history array odd")
            return;
        }
            historyBufferImageOdd = UIImage.image(buffer: historyArrayOdd, length: length, rowWidth: 1920)
        
        if let historyArrayEven = self.historyBufferEven?.contents().assumingMemoryBound(to: UInt8.self) {
            historyBufferImageEven = UIImage.image(buffer: historyArrayEven, length: length, rowWidth: 1920)
        }
        
        for i in 0..<1920 {
            NSLog(" possible preamble: 0x%x", historyArrayOdd[1920*720+i])
        }
        
        
        
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
        let dataImageNoSNR = UIImage.image(buffer: dataImageArrayNoSNR, length: length, rowWidth: 1920)
        
        

        
        
        

        
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
    
}
