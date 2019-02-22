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
    
    let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
    var captureId: Int = 0
    
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
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
//        initializeMetal()
    }
    
    func setCaptureId(captureId: Int) {
        self.captureId = captureId
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
        // convert buffer to PNG and save it
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
    
    func addToArrayForSaving(imageBytes: UnsafeRawPointer, length: Int) {
        // copy pixel buffer to array and save it every 90 frames
        let data = Data(bytes: imageBytes, count: length)
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@_%d.data", dateString, self.captureId)
        let dataFile = DataFile(data: data, fileName: fileName)
        if savingFiles == false {
            // check if the file system is busy writing from previous session
            //
            dataFileArray.append(dataFile)
            if dataFileArray.count >= 90 {
                savingFiles = true
                DispatchQueue.global(qos: .userInitiated).async {
                    self.writeEntireArray(to: self.dataFileArray[0].fileName)
//                    for dataFile in self.dataFileArray {
//                        NSLog("Saving file")
//                        self.write(imageData: dataFile.data, to: dataFile.fileName)
//                    }
                    self.dataFileArray.removeAll()
                    self.savingFiles = false
                }
            }
        }
    }
    
    func writeEntireArray(to filename: String) {
        let url = self.dir.appendingPathComponent(filename) as URL
        for dataFile in self.dataFileArray {
            do {
                try dataFile.data.appendToFile(fileURL: url)
            } catch {
                NSLog("save error")
                return
            }
        }
        NSLog("Saved file")
    }
    
    func write(imageData: Data, to fileName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            // Save image.
            do {
                try imageData.write(to: filePath, options: .atomic)
            }
            catch {
                NSLog("write error")
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
    
    func decode(imageBytes: UnsafeRawPointer, length: Int) {
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
        
        evenFrame = !evenFrame
    }
    
    
    var historyBufferOdd: MTLBuffer?
    var matchBufferOdd: MTLBuffer?
    var historyBufferEven: MTLBuffer?
    var matchBufferEven: MTLBuffer?
    var bufferLength = 0
    
    var minBuffer: MTLBuffer?
    var maxBuffer: MTLBuffer?
    
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
        historyBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModePrivate)
        matchBufferOdd = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
        historyBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModePrivate)
        matchBufferEven = device?.makeBuffer(length: bufferLength, options: .storageModeShared)
        
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
        if evenFrame != true {
            hBuffer = self.historyBufferOdd
            mBuffer = self.matchBufferOdd
        } else {
            hBuffer = self.historyBufferEven
            mBuffer = self.matchBufferEven
        }
        
        guard let historyBuffer = hBuffer else {
            NSLog("no history buffer")
            return
        }
        
        guard let matchBuffer = mBuffer else {
            NSLog("no match buffer")
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
    
    
    func countFoundPreambleBits() {
        guard let matchBufferOdd = self.matchBufferOdd else {
            NSLog("no match buffer")
            return
        }
        let matchArrayOdd = matchBufferOdd.contents().assumingMemoryBound(to: UInt8.self)
        var numberOfMatchesOdd = 0
        for i in 0..<bufferLength {
            if matchArrayOdd[i] == 1 {
                numberOfMatchesOdd += 1
            }
        }
//        for i in 0..<100 {
//            NSLog("his odd 0x%x", matchArrayOdd[i])
//        }
        NSLog("number of matches odd: %d", numberOfMatchesOdd)
        
        
        
        guard let matchBufferEven = self.matchBufferEven else {
            NSLog("no match buffer")
            return
        }
        let matchArrayEven = matchBufferEven.contents().assumingMemoryBound(to: UInt8.self)
        var numberOfMatchesEven = 0
        for i in 0..<bufferLength {
            if matchArrayEven[i] == 1 {
                numberOfMatchesEven += 1
            }
        }
        if let maxArray = self.maxBuffer?.contents().assumingMemoryBound(to: UInt8.self), let minArray = self.minBuffer?.contents().assumingMemoryBound(to: UInt8.self) {
            for i in 0..<100 {
                NSLog("max: %d", maxArray[i])
            }
            for i in 0..<100 {
                NSLog("min: %d", minArray[i])
            }
        }
//        for i in 0..<100 {
//            NSLog("his even 0x%x", matchArrayEven[i])
//        }
        NSLog("number of matches even: %d", numberOfMatchesEven)
    }
    

    
    
    
    
    

//    lazy var imageQueue = DispatchQueue(label: "imagequeue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//    let numImageWorkPartitions = 20
//    func add(imageData: Data) {
//
//
//        let bufferSize = 2
//        imageDataArray.append(imageData)
//        while imageDataArray.count > bufferSize {
//            imageDataArray.remove(at: 0)
//        }
//        imageQueue.sync {
//            let imageGroup = DispatchGroup()
//        if self.imageDataArray.count >= bufferSize {
////            let imageDataArrayCopy = imageDataArray.map { (data) -> Data in
////                return data
////            }
//
//                let byteCount = self.imageDataArray[0].count
//                var diffData = Data(count: byteCount)//Data(count: byteCount)
//                for imageIndex in 1..<self.imageDataArray.count {
//                    let currentImageData = self.imageDataArray[imageIndex]
//                    let partitionSize = currentImageData.count / numImageWorkPartitions
//                    let prevImageData = self.imageDataArray[imageIndex-1]
//                    //for pixelIndex in 0..<currentImageData.count {
//                    for partitionIndex in 0..<2/*numImageWorkPartitions*/ {
//                        imageGroup.enter()
//                        DispatchQueue.global(qos: .userInitiated).async {
//                            for pixelIndex in partitionIndex*partitionSize..<(partitionIndex+1)*partitionSize {
//
//                                let prevPixel = prevImageData[pixelIndex]
//                                let currPixel = currentImageData[pixelIndex]
//                                let diff:UInt8 = UInt8(abs(Int(currPixel) - Int(prevPixel)))
//                       // if diff > diffData[pixelIndex] {
//
//
//                                NSLog("%d pixelIndex: %d", partitionIndex, pixelIndex)
//                                NSLog("%d diffData.count: %d", partitionIndex, diffData.count)
//
//                                diffData[pixelIndex] = diff
//                            }
//                            imageGroup.leave()
//                        }
//                       // }
//                    }
//                }
//                imageGroup.wait()
//
//                var largestDiffValue:UInt8 = 0
//                var largestDiffIndex = 0
//                for pixelIndex in 0..<byteCount {
//                    if diffData[pixelIndex] > largestDiffValue {
//                        largestDiffIndex = pixelIndex
//                        largestDiffValue = diffData[pixelIndex]
//                    }
//                }
//
//                let x = largestDiffIndex % self.width
//                let y = largestDiffIndex / self.width
//
//                NSLog("largest diff x: \(x), y: \(y)")
//
//
//            }
//        }
//
//    }
    
}

extension Data {
    func appendToFile(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
