//
//  ViewController.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 12/4/18.
//  Copyright © 2018 Wiselab. All rights reserved.
//

import UIKit
import ARKit
import VideoToolbox
import CoreMotion

let kLightData = "LightData"

class ViewController: UIViewController {

    let sceneView = ARSCNView()
    let scene = SCNScene()
    
    let trackingStateLabel = UILabel()
    
    let locationView = LocationView(frame: CGRect.zero)
    let colorView = UIView()
    
    var targetPoint3d: SCNVector3?
 //   var lastFrame: ARFrame?
 //   var sphereNode = SCNNode()
    
    var planes = [ARPlaneAnchor: Plane]()
    
    var lightDecoder = LightDecoder()
    
    let fileNameDateFormatter = DateFormatter()
    
    let lightAnchorManager = LightAnchorManager()
    
    var capture = false
    var blinkTimer: Timer?
    
    var showPixels = true

    
    let settingsViewController = SettingsViewController()
    
    var sphereNode: SCNNode?
    
    /* UI Elements */
    var numConnectionsLabel: UILabel = UILabel()
    let lightDataLabel = UILabel()
    let cameraConfigLabel = UILabel()
    //    var detectLabel: UILabel = UILabel()
    //    var lightAnchorLabel = UILabel()
    let buttonStackView = UIStackView()
    var captureButton: UIButton = UIButton()
//    let testButton = UIButton()
    let showPixelsButton = UIButton()
    
    /* json logging */
    var captureId: Int = 0
    var logDict: NSMutableDictionary?
    var blinkDataArray: NSMutableArray?
    var frameDataArray: NSMutableArray?
    var motionDataArray: NSMutableArray?
    var dataPointDict: NSMutableDictionary?
    
    let dateFormatter = DateFormatter()
    var timeStamp = Date()
    
    let frameRateLabel = UILabel()
    var frameCount = 0;
    
    let motionManager = CMMotionManager()
    
    let imageView = UIImageView()
    
    let imageViewBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.95)
    
    let clusterView1 = ClusterView()
    let clusterView2 = ClusterView()
    
    
    var cameraAngle:Float = 0.0
    var cameraPosition = SCNVector3(0,0,0)
    
    let xLabel = UILabel()
    let yLabel = UILabel()
    let zLabel = UILabel()
    let labelStackView = UIStackView()
    
    init () {
        super.init(nibName: nil, bundle: nil)
        
        fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.session.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()
        
        view.addSubview(sceneView)
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(locationView)
        locationView.translatesAutoresizingMaskIntoConstraints = false
        locationView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        locationView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        locationView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        locationView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.addSubview(trackingStateLabel)
        trackingStateLabel.translatesAutoresizingMaskIntoConstraints = false
        trackingStateLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        trackingStateLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        trackingStateLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        trackingStateLabel.heightAnchor.constraint(equalToConstant: 50)
        
        
//        view.addSubview(numConnectionsLabel)
//        numConnectionsLabel.translatesAutoresizingMaskIntoConstraints = false
//        numConnectionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
//        numConnectionsLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
//        numConnectionsLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
//        numConnectionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        
//        view.addSubview(lightDataLabel)
//        lightDataLabel.translatesAutoresizingMaskIntoConstraints = false
//        lightDataLabel.leadingAnchor.constraint(equalTo: numConnectionsLabel.leadingAnchor).isActive = true
//        lightDataLabel.topAnchor.constraint(equalTo: numConnectionsLabel.topAnchor).isActive = true
//        lightDataLabel.heightAnchor.constraint(equalTo: numConnectionsLabel.heightAnchor).isActive = true
//        lightDataLabel.trailingAnchor.constraint(equalTo: numConnectionsLabel.trailingAnchor).isActive = true
        
        lightDataLabel.textColor = UIColor.red
        lightDataLabel.textAlignment = .right
        
//        view.addSubview(cameraConfigLabel)
//        cameraConfigLabel.translatesAutoresizingMaskIntoConstraints = false
//        cameraConfigLabel.leadingAnchor.constraint(equalTo: numConnectionsLabel.leadingAnchor).isActive = true
//        cameraConfigLabel.topAnchor.constraint(equalTo: numConnectionsLabel.bottomAnchor).isActive = true
//        cameraConfigLabel.heightAnchor.constraint(equalTo: numConnectionsLabel.heightAnchor).isActive = true
//        cameraConfigLabel.trailingAnchor.constraint(equalTo: numConnectionsLabel.trailingAnchor).isActive = true
//        cameraConfigLabel.textColor = UIColor.red
        
        view.addSubview(frameRateLabel)
        frameRateLabel.translatesAutoresizingMaskIntoConstraints = false
        frameRateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        frameRateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
       // frameRateLabel.topAnchor.constraint(equalTo: cameraConfigLabel.bottomAnchor).isActive = true
        frameRateLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
//        frameRateLabel.heightAnchor.constraint(equalTo: numConnectionsLabel.heightAnchor).isActive = true
        frameRateLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        

        
        view.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
        buttonStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15).isActive = true
        buttonStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -30).isActive = true
        if UI_USER_INTERFACE_IDIOM() == .pad {
            buttonStackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.04).isActive = true
        } else {
            buttonStackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.08).isActive = true
        }
        
        buttonStackView.addArrangedSubview(captureButton)
     //   buttonStackView.addArrangedSubview(testButton)
        buttonStackView.addArrangedSubview(showPixelsButton)
        buttonStackView.axis = .horizontal
        buttonStackView.alignment = .center
        buttonStackView.distribution = .equalSpacing
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            captureButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        } else {
            captureButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
        }
        captureButton.heightAnchor.constraint(equalTo: buttonStackView.heightAnchor).isActive = true
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(startCapture(sender:)), for: .touchUpInside)
        captureButton.backgroundColor = UIColor.blue
        captureButton.layer.cornerRadius = 20
        
//        if UI_USER_INTERFACE_IDIOM() == .pad {
//            testButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
//        } else {
//            testButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
//        }
//        testButton.heightAnchor.constraint(equalTo: buttonStackView.heightAnchor).isActive = true
//        testButton.setTitle("Test", for: .normal)
//        testButton.addTarget(self, action: #selector(test(sender:)), for: .touchUpInside)
//        testButton.backgroundColor = UIColor.blue
//        testButton.layer.cornerRadius = 20
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            showPixelsButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
        } else {
            showPixelsButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
        }
        showPixelsButton.heightAnchor.constraint(equalTo: buttonStackView.heightAnchor).isActive = true
        showPixelsButton.setTitle("Show Pixels", for: .normal)
        showPixelsButton.addTarget(self, action: #selector(showPixelsClicked(sender:)), for: .touchUpInside)
        showPixelsButton.backgroundColor = UIColor.blue
        showPixelsButton.layer.cornerRadius = 20
        
        numConnectionsLabel.textColor = UIColor.red
        numConnectionsLabel.text = "# Connections: 0"
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: sceneView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: sceneView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: sceneView.rightAnchor).isActive = true
        
//        view.addSubview(clusterView)
//        clusterView.translatesAutoresizingMaskIntoConstraints = false
//        clusterView.topAnchor.constraint(equalTo: sceneView.topAnchor).isActive = true
//        clusterView.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
//        clusterView.leftAnchor.constraint(equalTo: sceneView.leftAnchor).isActive = true
//        clusterView.rightAnchor.constraint(equalTo: sceneView.rightAnchor).isActive = true
        
        view.addSubview(clusterView1)
        clusterView1.translatesAutoresizingMaskIntoConstraints = false
        clusterView1.topAnchor.constraint(equalTo: sceneView.topAnchor).isActive = true
        clusterView1.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
        clusterView1.leftAnchor.constraint(equalTo: sceneView.leftAnchor).isActive = true
        clusterView1.rightAnchor.constraint(equalTo: sceneView.rightAnchor).isActive = true
        
        view.addSubview(clusterView2)
        clusterView2.translatesAutoresizingMaskIntoConstraints = false
        clusterView2.topAnchor.constraint(equalTo: sceneView.topAnchor).isActive = true
        clusterView2.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
        clusterView2.leftAnchor.constraint(equalTo: sceneView.leftAnchor).isActive = true
        clusterView2.rightAnchor.constraint(equalTo: sceneView.rightAnchor).isActive = true
        
        view.addSubview(labelStackView)
        labelStackView.addArrangedSubview(xLabel)
        labelStackView.addArrangedSubview(yLabel)
        labelStackView.addArrangedSubview(zLabel)
        
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.topAnchor.constraint(equalTo: frameRateLabel.bottomAnchor).isActive = true
        labelStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        labelStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        labelStackView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        labelStackView.alignment = .fill
        labelStackView.axis = .vertical
        labelStackView.distribution = .fillEqually
        
//        view.addSubview(colorView)
//        colorView.translatesAutoresizingMaskIntoConstraints = false
//        colorView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.25).isActive = true
//        colorView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
//        colorView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
//        colorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            //NSLog("number of frames: \(self.frameCount)")
            self.frameRateLabel.text = "\(self.frameCount) fps"
            NSLog("frame rate %d fps", self.frameCount)
            self.frameCount = 0
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        for format in ARWorldTrackingConfiguration.supportedVideoFormats {
            NSLog("format: \(format)")
        }
        
        configuration.planeDetection = .horizontal//[.horizontal, .vertical]
        configuration.worldAlignment = .gravity/*.gravityAndHeading*///based on compass
        sceneView.debugOptions = [.showWorldOrigin/*, .showFeaturePoints*//*.showWireframe*/]
        // Run the view's session
        sceneView.session.run(configuration)
        
     //   let sphere = createSphere(at: SCNVector3(x: 0, y: 0, z: 1), color: UIColor.yellow)
     //   scene.rootNode.addChildNode(sphere)
        
        trackingStateLabel.textColor = UIColor.red
        
        colorView.backgroundColor = UIColor.red
        
        lightAnchorManager.delegate = self
        lightAnchorManager.scanForLightAnchors()
        
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settings))
        
        frameRateLabel.textColor = UIColor.red
        
        imageView.contentMode = .scaleAspectFill
    //    imageView.alpha = 0.9
     //   imageView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        lightDecoder.delegate = self
        
        updatePixelView()
        updateShowPixelsButton()
        
        xLabel.textColor = UIColor.red
        yLabel.textColor = UIColor.red
        zLabel.textColor = UIColor.red
        
      //  lightDecoder.evaluateResults()
        self.navigationController?.navigationBar.isHidden = true
        
    }

    
    @objc func startCapture(sender:UIButton) {
        if capture == false { // start
            timeStamp = Date()
            //startBle()
            logDict = NSMutableDictionary()
            blinkDataArray = NSMutableArray()
            frameDataArray = NSMutableArray()
            motionDataArray = NSMutableArray()
            logDict?.setValue(blinkDataArray, forKey: "blinkdata")
            logDict?.setValue(frameDataArray, forKey: "framedata")
            logDict?.setValue(motionDataArray, forKey: "motiondata")
            captureId = UserDefaults.standard.integer(forKey: kCaptureId)
            self.title = String(format: "Test #: %d", captureId)
            logDict?.setValue(captureId, forKey: "captureid")
            logDict?.setValue(timeStamp.timeIntervalSince1970, forKey: "starttime")
            let iso = UserDefaults.standard.float(forKey: kIsoKey)
            let exposure = UserDefaults.standard.integer(forKey: kExposureKey)
            logDict?.setValue(iso, forKey: "iso")
            logDict?.setValue(exposure, forKey: "exposure")
            let whiteBalanceLock = UserDefaults.standard.bool(forKey: kWhiteBalanceLock)
            logDict?.setValue(whiteBalanceLock, forKey: "wblock")
            
            imageView.backgroundColor = imageViewBackgroundColor
            
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { (timer) in
                NSLog("Fire!")
                var dataValue = 0
                if UserDefaults.standard.bool(forKey: kGenerateRandomData) {
                    dataValue = Int.random(in: 0..<0x3F)
                } else {
                    dataValue = UserDefaults.standard.integer(forKey: kLightData)
                }
                let dataString = String(format: "0x%x", dataValue)
                self.dataPointDict = NSMutableDictionary()
                if let dataPointDict = self.dataPointDict {
                    dataPointDict.setValue(dataString, forKey: "value")
                    dataPointDict.setValue(Date().timeIntervalSince1970, forKey: "time")
                    dataPointDict.setValue(false, forKey: "error")
                    self.blinkDataArray?.add(dataPointDict)
                }
                self.lightDecoder.shouldSave = true
                NSLog("set data to: %@", dataString)
                self.lightDataLabel.text = dataString
                self.lightAnchorManager.startBlinking(with: dataValue)
            }

            capture = true
        } else { // stop
            lightAnchorManager.stopBlinking()
            imageView.image = nil
            imageView.backgroundColor = UIColor.clear
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: logDict, options: .prettyPrinted)
                let jsonString = String(bytes: jsonData, encoding: .utf8)
                if let string = jsonString {
                    NSLog("json: %@", string)
                } else {
                    NSLog("no json")
                }
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                
                let dateString = dateFormatter.string(from: timeStamp)
                let dataValue = UserDefaults.standard.integer(forKey: kLightData)
                
                let fileName = String(format: "%@_%d.json", dateString, captureId)
                let filePath = String(format: "%@/%@", documentsPath, fileName)
                NSLog("filePath: %@", filePath)
                let url = URL(fileURLWithPath: filePath)
                try jsonData.write(to: url)
            } catch {
                NSLog("error writing json file")
            }
            
            lightDataLabel.text = ""
            if let timer = blinkTimer {
                timer.invalidate()
            }
            capture = false
            captureId = UserDefaults.standard.integer(forKey: kCaptureId)+1
            UserDefaults.standard.setValue(captureId, forKey: kCaptureId)
            self.title = String(format: "Test #: %d", captureId)
            
            clusterView1.update(location: CGPoint(x: 0, y: 0), radius: 0.0)
            clusterView2.update(location: CGPoint(x: 0, y: 0), radius: 0.0)
            
            lightDecoder.evaluateResults()
        }
        updateCaptureButton()
    }

    
//    @objc func test(sender: UIButton) {
//        var dataValue = 0
//        if UserDefaults.standard.bool(forKey: kGenerateRandomData) {
//            dataValue = Int.random(in: 0..<0x3F)
//        } else {
//            dataValue = UserDefaults.standard.integer(forKey: kLightData)
//        }
//        let dataString = String(format: "0x%x", dataValue)
//        NSLog("set data to: %@", dataString)
//        lightDataLabel.text = dataString
//        lightAnchorManager.startBlinking(with: dataValue)
//    }
    
    
    @objc func showPixelsClicked(sender: UIButton) {
        NSLog("showPixelsClicked")
        if showPixels == false {
            showPixels = true
        } else {
            showPixels = false
        }
        
        updatePixelView()
        updateShowPixelsButton()
    }
    
    
    @objc func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        NSLog("handleTap")
        let tapLocation = gestureRecognizer.location(in: sceneView)
        NSLog("Tap Location x: \(tapLocation.x), y: \(tapLocation.y)")
//        if let frame = lastFrame {
            let results = sceneView.hitTest(tapLocation, types: [/*.existingPlaneUsingGeometry, .existingPlane, */.existingPlaneUsingExtent, .estimatedHorizontalPlane, .estimatedVerticalPlane])
            NSLog("number of hit test results: \(results.count)")
            if let result = results.last {
                
//                let x = result.worldTransform.columns.3[0]
//                let y = result.worldTransform.columns.3[1]
//                let z = result.worldTransform.columns.3[2]
//                let transform = SCNMatrix4.init(result.worldTransform)
                let x = result.worldTransform.columns.3.x//transform.m41
                let y = result.worldTransform.columns.3.y//transform.m42
                let z = result.worldTransform.columns.3.z//transform.m43
                targetPoint3d = SCNVector3(x: x, y: y, z: z)
                NSLog("targetPoint3d x: \(x), y: \(y), z: \(z)")
                if let location = targetPoint3d {
            //        sphereNode.removeFromParentNode()
             //       sphereNode = createSphere(at: location, color: UIColor.green)
       //             scene.rootNode.addChildNode(sphereNode)
                }
            }
 //       }
        
        
        
    }
    
    
    
    func createSphere(at location: SCNVector3, color: UIColor) -> SCNNode{
        let sphereGeometry = SCNSphere(radius: 0.03)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color.cgColor
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereGeometry.materials = [sphereMaterial]
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = location
        return sphereNode
    }

    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        let plane = Plane(anchor)
        planes[anchor] = plane
        node.addChildNode(plane)
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    
    func savePixelBuffer(_ buffer: CVPixelBuffer) {
        let now = Date()
        let dateString = fileNameDateFormatter.string(from: now)
        let fileName = String(format: "%@.gray", dateString)
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            let format = CVPixelBufferGetPixelFormatType(buffer)
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            
//            NSLog("pixelBuffer width: %d, height: %d, format: \(format), bytes per row: \(bytesPerRow) ", width, height)
            
            let grayPlaneHeight = 1920
            let grayPlaneWidth = 1440
            var grayPlaneIndex = 0
            let planeCount = CVPixelBufferGetPlaneCount(buffer)
            for planeIndex in 0..<planeCount {
                let planeHeight = CVPixelBufferGetHeightOfPlane(buffer, planeIndex)
                let planeWidth = CVPixelBufferGetWidthOfPlane(buffer, planeIndex)
                if planeWidth == grayPlaneWidth && planeHeight == grayPlaneHeight {
                    grayPlaneIndex = planeIndex
                }
            }
    
            let numGrayBytes = grayPlaneHeight*grayPlaneWidth
            
            CVPixelBufferLockBaseAddress(buffer, .readOnly)
            //let dataSize = CVPixelBufferGetDataSize(frame.capturedImage)
//            NSLog("dataSize: %d", numGrayBytes)
            
//            let ciImage = CIImage(cvPixelBuffer: buffer)
//            let uiImage = UIImage(ciImage: ciImage)
//            let blurredImage = ciImage.applyingGaussianBlur(sigma: 10)
//            let blurUIImage = UIImage(ciImage: blurredImage)
//            if let blurredPixelBuffer = blurredImage.pixelBuffer {

                if let baseAddressGray = CVPixelBufferGetBaseAddressOfPlane(buffer, grayPlaneIndex) {
    //                NSLog("frame.captureImage: \(buffer)\n\n")
    //                NSLog("baseAddress: \(baseAddressGray)")
              //      let bufferData = Data(bytes: baseAddressGray, count: numGrayBytes)
                    //self.lightDecoder.add(imageBytes: baseAddressGray, length: numGrayBytes)
                    //self.lightDecoder.save(imageData: baseAddressGray, length: numGrayBytes)
                  // self.lightDecoder.add(imageData: bufferData)
                    //self.lightDecoder.addToArrayForSaving(imageBytes: baseAddressGray, length: numGrayBytes)
                    self.lightDecoder.decode(imageBytes: baseAddressGray, length: numGrayBytes)

                }
                
//            } else {
//                NSLog("no blurredPixelBuffer")
//            }
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        
    }
    
    
    func updatePixelView() {
        if showPixels == true {
            imageView.isHidden = false
            clusterView1.color = UIColor.white
            clusterView2.color = UIColor.white
        } else {
            imageView.isHidden = true
            clusterView1.color = UIColor.green
            clusterView2.color = UIColor.red
        }
    }
    
    
    func updateCaptureButton() {
        if capture == false {
            captureButton.setTitle("Capture", for: .normal)
        } else {
            captureButton.setTitle("Stop", for: .normal)
        }
    }
    
    func updateShowPixelsButton() {
        if showPixels == false {
            showPixelsButton.setTitle("Show Pixels", for: .normal)
        } else {
            showPixelsButton.setTitle("Hide Pixels", for: .normal)
        }
    }
    
    @objc func settings() {
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    let fovDegreesLandscape: Float = 99
    
    func angleToLight(using x: Float) -> Float {
        let width: Float = 1920
        let height: Float = 1440
        let fovDegreesPotrait = height/width * fovDegreesLandscape
        let angle = (x - Float(clusterView1.frame.size.width)/2.0)/Float(clusterView1.frame.size.width) * (fovDegreesPotrait/2.0)
        return angle
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}




extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    /*
     Called when a SceneKit node corresponding to a
     new AR anchor has been added to the scene.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
     //           self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }

    
    
    /*
     Called when a SceneKit node's properties have been
     updated to match the current state of its corresponding anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            updatePlane(anchor: planeAnchor)
        }
    }
    
    /*
     Called when SceneKit node corresponding to a removed
     AR anchor has been removed from the scene.
     */
    func renderer(_ renderer: SCNSceneRenderer,
                  didRemove node: SCNNode, for anchor: ARAnchor) {
        // ...
    }
    
    
    
}



extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

        
        cameraAngle = frame.camera.eulerAngles.y
        NSLog("camera angle: %f", cameraAngle)
        let x = frame.camera.transform.columns.3[0]
        let y = frame.camera.transform.columns.3[1]
        let z = frame.camera.transform.columns.3[2]
        cameraPosition = SCNVector3(x, y, z)
        
        xLabel.text = String(format: "x: %.3f", x)
        yLabel.text = String(format: "y: %.3f", y)
        zLabel.text = String(format: "z: %.3f", z)
        
        if capture == true {
            let currentTransform = frame.camera.transform
            let x = currentTransform[3][0]
            let y = currentTransform[3][1]
            let z = currentTransform[3][2]
            let pitch = frame.camera.eulerAngles[0]
            let yaw = frame.camera.eulerAngles[1]
            let roll = frame.camera.eulerAngles[2]
            let frameDataDict = NSMutableDictionary()
            frameDataDict.setValue(x, forKey: "x")
            frameDataDict.setValue(y, forKey: "y")
            frameDataDict.setValue(z, forKey: "z")
            frameDataDict.setValue(pitch, forKey: "pitch")
            frameDataDict.setValue(yaw, forKey: "yaw")
            frameDataDict.setValue(roll, forKey: "roll")
            frameDataDict.setValue(Date().timeIntervalSince1970, forKey: "time")
            frameDataArray?.add(frameDataDict)
            let xMotion = motionManager.deviceMotion?.userAcceleration.x
            let yMotion = motionManager.deviceMotion?.userAcceleration.y
            let zMotion = motionManager.deviceMotion?.userAcceleration.z
            let xRot = motionManager.deviceMotion?.rotationRate.x
            let yRot = motionManager.deviceMotion?.rotationRate.y
            let zRot = motionManager.deviceMotion?.rotationRate.z
            let motionDataDict = NSMutableDictionary()
            motionDataDict.setValue(xMotion, forKey: "xAcc")
            motionDataDict.setValue(yMotion, forKey: "yAcc")
            motionDataDict.setValue(zMotion, forKey: "zAcc")
            motionDataDict.setValue(xRot, forKey: "xRot")
            motionDataDict.setValue(yRot, forKey: "yRot")
            motionDataDict.setValue(zRot, forKey: "zRot")
            motionDataDict.setValue(Date().timeIntervalSince1970, forKey: "time")
            motionDataArray?.add(motionDataDict)
            
//            let width = CVPixelBufferGetWidth(frame.capturedImage)
//            let height = CVPixelBufferGetHeight(frame.capturedImage)
//            NSLog("frame width: \(width) height: \(height)")
            
            
            savePixelBuffer(frame.capturedImage)
        }
        
        frameCount += 1
            
            

    }
    
    
    /**
     This is called when new anchors are added to the session.
     
     @param session The session being run.
     @param anchors An array of added anchors.
     */
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        
    }
    
    
    /**
     This is called when anchors are updated.
     
     @param session The session being run.
     @param anchors An array of updated anchors.
     */
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
    }
    
    
    /**
     This is called when anchors are removed from the session.
     
     @param session The session being run.
     @param anchors An array of removed anchors.
     */
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        let cameraTrackingState = camera.trackingState
                switch (trackingState) {
                case .normal:
                    trackingStateLabel.text = "Normal"
                   // NSLog("ARTrackingStateNormal")
                case.limited(let reason):
                    trackingStateLabel.text = "Limited: \(reason)"
                    //NSLog("ARTrackingStateLimited: \(reason)")
                case.notAvailable:
                    trackingStateLabel.text = "Not Available"
                    //NSLog("ARTrackingStateNotAvailable")
        
                }
        
    }
    

}


extension ViewController: LightAnchorManagerDelegate {
    func lightAnchorManager(bleManager: LightAnchorManager, didDiscoverLightAnchorIdentifiedBy lightAnchorId: Int) {
        numConnectionsLabel.text = String(format: "# Connections: %d", lightAnchorManager.lightAnchors.count)
    }
    
    func lightAnchorManagerDidDisconnectFromLightAnchor(bleManager: LightAnchorManager) {
        
    }
    
    
}



extension UIImage {
    func saveToFile(named fileName: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent(fileName) {
            // Save image.
            do {
                try self.pngData()?.write(to: filePath, options: .atomic)
            }
            catch {
                // Handle the error
            }
        }
    }
    
    
    func croppedImage(inRect rect: CGRect) -> UIImage {
        let rad: (Double) -> CGFloat = { deg in
            return CGFloat(deg / 180.0 * .pi)
        }
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            let rotation = CGAffineTransform(rotationAngle: rad(90))
            rectTransform = rotation.translatedBy(x: 0, y: -size.height)
        case .right:
            let rotation = CGAffineTransform(rotationAngle: rad(-90))
            rectTransform = rotation.translatedBy(x: -size.width, y: 0)
        case .down:
            let rotation = CGAffineTransform(rotationAngle: rad(-180))
            rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        let transformedRect = rect.applying(rectTransform)
        let imageRef = cgImage!.cropping(to: transformedRect)!
        let result = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        return result
    }
    
}



extension ViewController: LightDecoderDelegate {
    func lightDecoder(_: LightDecoder, didUpdateResultImage resultImage: UIImage) {
        NSLog("received result image")
        imageView.image = resultImage
    }
    
    func lightDecoder(_: LightDecoder, didUpdate codeIndex:Int, meanX: Float, meanY: Float, stdDevX: Float, stdDevY: Float) {
        let avgStdDev = CGFloat((stdDevX + stdDevY) / 2.0)
        
        let scale = CGFloat(clusterView1.frame.size.height / 1920)
        let widthScaled = 1440*scale
        let xOffset = (widthScaled-clusterView1.frame.size.width)/2.0
        let meanXScaled = scale * CGFloat(meanX)
        let meanYScaled = scale * CGFloat(meanY)
        let avgStdDevScaled = avgStdDev * scale
        let radius:CGFloat = avgStdDevScaled
        

        
        if avgStdDev > 150 {
            if codeIndex == 1 {
                self.clusterView1.update(location: CGPoint(x: 0, y: 0), radius: 0)
            } else if codeIndex == 2 {
                self.clusterView2.update(location: CGPoint(x: 0, y: 0), radius: 0)
            }
        } else {
            let lightAngle = angleToLight(using: Float(meanXScaled-xOffset))
            NSLog("meanX: %f", meanXScaled-xOffset)
            NSLog("angle to light: %f", lightAngle)
            
            if sphereNode == nil {
                let sphere = SCNSphere(radius: 0.02)
              //  let sphere = SCNText(string: "AB", extrusionDepth: 0.01)
                let sphereMaterial = SCNMaterial()
                sphereMaterial.diffuse.contents = UIColor.green.cgColor
                sphereMaterial.locksAmbientWithDiffuse = true
                sphere.materials = [sphereMaterial]
                sphereNode = SCNNode(geometry: sphere)
                if let node = sphereNode {
                    sceneView.scene.rootNode.addChildNode(node)
                }
            }
            if let node = sphereNode {
                NSLog("light angle: %.2f", lightAngle)
                let angle = cameraAngle - lightAngle / 180 * Float.pi
                let zDisp = -1*cos(angle)
                let xDisp = -1*sin(angle)
                NSLog("zDisp: \(zDisp), xDisp: \(xDisp)")
                let nodeX = cameraPosition.x + xDisp
                let nodeZ = cameraPosition.z + zDisp
                node.position = SCNVector3(nodeX, 0, nodeZ)
            }
            
            
            if codeIndex == 1 {
                self.clusterView1.update(location: CGPoint(x: CGFloat(meanXScaled-xOffset), y: CGFloat(meanYScaled)), radius: radius)
            } else if codeIndex == 2 {
                self.clusterView2.update(location: CGPoint(x: CGFloat(meanXScaled-xOffset), y: CGFloat(meanYScaled)), radius: radius)
            }
        }
    }
    
    
}



