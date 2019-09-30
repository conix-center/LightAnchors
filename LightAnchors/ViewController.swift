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
import LightAnchorFramework
import LASwift

let kLightData = "LightData"


let anchor1Location = SCNVector3(3.643, 1.693, -1.640);
let anchor2Location = SCNVector3(3.644, 2.375, -1.622);
let anchor3Location = SCNVector3(3.671, 2.120, -1.031);
let anchor4Location = SCNVector3(3.703, 1.739, -0.576);

//let anchor1Location = SCNVector3(0,1,0)
//let anchor2Location = SCNVector3(1,1,0)
//let anchor3Location = SCNVector3(1,0,0)
//let anchor4Location = SCNVector3(0,0,0)

//let anchor1Location = SCNVector3(0,2.9,0)
//let anchor2Location = SCNVector3(5.23,2.9,0)
//let anchor3Location = SCNVector3(5.23,0,0)
//let anchor4Location = SCNVector3(0,0,0)


class ViewController: UIViewController {

    let sceneView = ARSCNView()
    let scene = SCNScene()
    
    let trackingStateLabel = UILabel()
    
    let locationView = LocationView(frame: CGRect.zero)
    let colorView = UIView()
    
    var targetPoint3d: SCNVector3?
 //   var lastFrame: ARFrame?
 //   var sphereNode = SCNNode()
    
//    var planes = [ARPlaneAnchor: Plane]()
    
    
    
//    let fileNameDateFormatter = DateFormatter()

    var showPixels = true

    
    let settingsViewController = SettingsViewController()
    
//    var coneNode1: SCNNode?
//    var coneNode2: SCNNode?
    
//    var textNode1: SCNNode?
//    var textNode2: SCNNode?
    
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
//    var captureId: Int = 0
//    var logDict: NSMutableDictionary?
//    var blinkDataArray: NSMutableArray?
//    var frameDataArray: NSMutableArray?
//    var motionDataArray: NSMutableArray?
//    var dataPointDict: NSMutableDictionary?
    
    let dateFormatter = DateFormatter()
    var timeStamp = Date()
    
    let frameRateLabel = UILabel()
    var frameCount = 0;
    
 //   let motionManager = CMMotionManager()
    
    let imageView = UIImageView()
    
    let imageViewBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
    
    let clusterView1 = ClusterView()
    let clusterView2 = ClusterView()
    
    
    var cameraAngle:Float = 0.0
 //   var cameraPosition = SCNVector3(0,0,0)
    
    let resolutionLabel = UILabel()
    let xLabel = UILabel()
    let yLabel = UILabel()
    let zLabel = UILabel()
    let pX1Label = UILabel()
    let pY1Label = UILabel()
    let pX2Label = UILabel()
    let pY2Label = UILabel()
    let labelStackView = UIStackView()

    let firstNode = SCNNode()
    
//    var cameraPosition = SCNVector3(0, 0, 0)
    

    
    var poseManager: LightAnchorPoseManager!
    
    init () {
        super.init(nibName: nil, bundle: nil)
        
 //       fileNameDateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
        
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
        
        lightDataLabel.textColor = UIColor.red
        lightDataLabel.textAlignment = .right
        
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
        labelStackView.addArrangedSubview(resolutionLabel)
        labelStackView.addArrangedSubview(xLabel)
        labelStackView.addArrangedSubview(yLabel)
        labelStackView.addArrangedSubview(zLabel)
        labelStackView.addArrangedSubview(pX1Label)
        labelStackView.addArrangedSubview(pY1Label)
        labelStackView.addArrangedSubview(pX2Label)
        labelStackView.addArrangedSubview(pY2Label)
        
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        labelStackView.topAnchor.constraint(equalTo: frameRateLabel.bottomAnchor).isActive = true
        labelStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        labelStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        labelStackView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        
        labelStackView.alignment = .fill
        labelStackView.axis = .vertical
        labelStackView.distribution = .fillEqually
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            //NSLog("number of frames: \(self.frameCount)")
            self.frameRateLabel.text = "\(self.frameCount) fps"
 //           NSLog("frame rate %d fps", self.frameCount)
            self.frameCount = 0
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.last!
        
        let anchorLocations = [anchor1Location, anchor2Location, anchor3Location, anchor4Location]
        //poseManager.imageSize = ImageSize(width: Int(configuration.videoFormat.imageResolution.width), height: Int(configuration.videoFormat.imageResolution.height))
        poseManager = LightAnchorPoseManager(imageWidth: Int(configuration.videoFormat.imageResolution.width), imageHeight: Int(configuration.videoFormat.imageResolution.height))
        poseManager.delegate = self
  
        resolutionLabel.text = String(format: "w: %d h: %d", poseManager.imageWidth, poseManager.imageHeight)
        NSLog("image size width: \(poseManager.imageWidth) height: \(poseManager.imageHeight)")
        for format in ARWorldTrackingConfiguration.supportedVideoFormats {
            NSLog("format: \(format)")
        }
        
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.worldAlignment = .gravity/*.gravityAndHeading*///based on compass
//        sceneView.debugOptions = [.showWorldOrigin/*, .showFeaturePoints*//*.showWireframe*/]
        // Run the view's session
        

        sceneView.session.run(configuration)
        
     //   let sphere = createSphere(at: SCNVector3(x: 0, y: 0, z: 1), color: UIColor.yellow)
     //   scene.rootNode.addChildNode(sphere)
        
        trackingStateLabel.textColor = UIColor.red
        
        colorView.backgroundColor = UIColor.red
        

        
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(settings))
        
        frameRateLabel.textColor = UIColor.red
        
        imageView.contentMode = .scaleAspectFill
    //    imageView.alpha = 0.9
     //   imageView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        

        
        updatePixelView()
        updateShowPixelsButton()
        
        resolutionLabel.textColor = UIColor.red
        xLabel.textColor = UIColor.red
        yLabel.textColor = UIColor.red
        zLabel.textColor = UIColor.red
        
        pX1Label.textColor = UIColor.red
        pY1Label.textColor = UIColor.red
        pX2Label.textColor = UIColor.red
        pY2Label.textColor = UIColor.red
        

        scene.rootNode.addChildNode(firstNode)
        
      //  lightDecoder.evaluateResults()
        self.navigationController?.navigationBar.isHidden = true
        let nodeRadius = Float(0.1)
        let node1 = createSphere(at: anchor1Location, radius:nodeRadius, color: .green)
        firstNode.addChildNode(node1)
        let node2 = createSphere(at: anchor2Location, radius: nodeRadius, color: .red)
        firstNode.addChildNode(node2)
        let node3 = createSphere(at: anchor3Location, radius: nodeRadius, color: .blue)
        firstNode.addChildNode(node3)
        let node4 = createSphere(at: anchor4Location, radius: nodeRadius, color: .yellow)
        firstNode.addChildNode(node4)
    }

    
    @objc func startCapture(sender:UIButton) {
        
        if !poseManager.capturing {
            imageView.backgroundColor = imageViewBackgroundColor
            poseManager.startCapture()
        } else {
            poseManager.stopCapture()
            imageView.image = nil
            imageView.backgroundColor = UIColor.clear
            clusterView1.update(location: CGPoint(x: 0, y: 0), radius: 0.0)
            clusterView2.update(location: CGPoint(x: 0, y: 0), radius: 0.0)
            
            lightDataLabel.text = ""
        }
        updateCaptureButton()
    }
    
    
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
                let x = result.worldTransform.columns.3.x//transform.m41
                let y = result.worldTransform.columns.3.y//transform.m42
                let z = result.worldTransform.columns.3.z//transform.m43
                
                targetPoint3d =  SCNVector3(x: x, y: y, z: z)
                NSLog("targetPoint3d x: \(x), y: \(y), z: \(z)")
                if let location = targetPoint3d {
            //        sphereNode.removeFromParentNode()
             //       sphereNode = createSphere(at: location, color: UIColor.green)
       //             scene.rootNode.addChildNode(sphereNode)
                }
            }
 //       }
        
        
        
    }
    
    
    
    func createSphere(at location: SCNVector3, radius: Float, color: UIColor) -> SCNNode{
        let sphereGeometry = SCNSphere(radius: CGFloat(radius))
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = color.cgColor
        sphereMaterial.locksAmbientWithDiffuse = true
        sphereGeometry.materials = [sphereMaterial]
        let sphereNode = SCNNode(geometry: sphereGeometry)
        sphereNode.position = location
        return sphereNode
    }

//    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
//        let plane = Plane(anchor)
//        planes[anchor] = plane
// //       node.addChildNode(plane)
//    }
//
//    func updatePlane(anchor: ARPlaneAnchor) {
//        if let plane = planes[anchor] {
//            plane.update(anchor)
//        }
//    }
    
    

    
    
    func updatePixelView() {
        if showPixels == true {
            imageView.isHidden = false
            clusterView1.color = UIColor.white
            clusterView2.color = UIColor.white
        } else {
            imageView.isHidden = true
            clusterView1.color = UIColor.blue
            clusterView2.color = UIColor.purple
        }
    }
    
    
    func updateCaptureButton() {
        if poseManager.capturing == false {
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
        let width: Float = Float(poseManager.imageWidth)
        let height: Float = Float(poseManager.imageHeight)
        let fovDegreesPotrait = height/width * fovDegreesLandscape
        let angle = (x - Float(clusterView1.frame.size.width)/2.0)/Float(clusterView1.frame.size.width) * (fovDegreesPotrait/2.0)
        return angle
    }
    

    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    func updateClusterView(codeIndex: Int, displayMeanX: Float, displayMeanY: Float, displayStdDevX: Float, displayStdDevY: Float) {
        
            let avgStdDev = CGFloat((displayStdDevX + displayStdDevY) / 2.0)
            
            let screenWidth = clusterView1.frame.size.width
            let screenHeight = clusterView1.frame.size.height
            
            
            var scale = CGFloat(1.0)
            var widthScaled = CGFloat(0)
            var heightScaled = CGFloat(0)
            
            var xOffset = CGFloat(0)
            var yOffset = CGFloat(0)
            NSLog("imageSize.width: \(poseManager.imageWidth), imageSize.height: \(poseManager.imageHeight)")
            NSLog("screenWidth: \(screenWidth), screenHeight: \(screenHeight)")
            
            if screenHeight/screenWidth > CGFloat(poseManager.imageWidth)/CGFloat(poseManager.imageHeight) {
                scale = CGFloat(clusterView1.frame.size.height / CGFloat(poseManager.imageWidth))
                widthScaled = CGFloat(poseManager.imageHeight)*scale
                //       let heightScaled = CGFloat(imageSize.width)*scale
                
                xOffset = (widthScaled-clusterView1.frame.size.width)/2.0
                
                NSLog("sizeI widthScaled: \(widthScaled)")
                NSLog("sizeI clusterView width: \(clusterView1.frame.size.width)")
                NSLog("sizeI xOffset: \(xOffset)")
                
                //        let yOffset = (widthScaled-clusterView1.frame.size.height)/2.0
                
                
                
            } else {
                scale = CGFloat(screenWidth/CGFloat(poseManager.imageHeight))
                heightScaled = CGFloat(poseManager.imageWidth)*scale
                yOffset = (heightScaled-screenHeight)/2.0
                
            }
            
            
            let meanXScaled = scale * CGFloat(displayMeanX)
            let meanYScaled = scale * CGFloat(displayMeanY)
            let meanXScreen = meanXScaled-xOffset
            let meanYScreen = meanYScaled-yOffset
            let avgStdDevScaled = avgStdDev * scale
            let radius:CGFloat = avgStdDevScaled
            
            
            
            
            if avgStdDev > 150 {
                if codeIndex == 1 {
                    self.clusterView1.update(location: CGPoint(x: 0, y: 0), radius: 0)
                    //                pX1Label.text = String(format: "pX1: %.2f", 0.0)
                    //                pY1Label.text = String(format: "pY1: %.2f", 0.0)
                } else if codeIndex == 2 {
                    self.clusterView2.update(location: CGPoint(x: 0, y: 0), radius: 0)
                    //                pX2Label.text = String(format: "pX2: %.2f", 0.0)
                    //                pY2Label.text = String(format: "pY2: %.2f", 0.0)
                }
            } else {
                if codeIndex == 1 {
                  //  self.clusterPointOnScreen1 = CGPoint(x: meanXScreen, y: CGFloat(meanYScreen))
                    self.clusterView1.update(location: CGPoint(x: CGFloat(meanXScaled-xOffset), y: CGFloat(meanYScaled-yOffset)), radius: radius)
//                    point1 = CGPoint(x: CGFloat(imageMeanX), y: CGFloat(imageMeanY))
                } else if codeIndex == 2 {
                 //   self.clusterPointOnScreen2 = CGPoint(x: meanXScreen, y: CGFloat(meanYScreen))
                    self.clusterView2.update(location: CGPoint(x: CGFloat(meanXScaled-xOffset), y: CGFloat(meanYScaled-yOffset)), radius: radius)
                //    point2 = CGPoint(x: CGFloat(imageMeanX), y: CGFloat(imageMeanY))
                } else if codeIndex == 3 {
                //    point3 = CGPoint(x: CGFloat(imageMeanX), y: CGFloat(imageMeanY))
                } else if codeIndex == 4 {
                //    point4 = CGPoint(x: CGFloat(imageMeanX), y: CGFloat(imageMeanY))
                }
            }
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
//        DispatchQueue.main.async {
//            if let planeAnchor = anchor as? ARPlaneAnchor {
//       //         NSLog("adding plane")
//                self.addPlane(node: node, anchor: planeAnchor)
//            }
//        }
    }

    
    
    /*
     Called when a SceneKit node's properties have been
     updated to match the current state of its corresponding anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer,
                  didUpdate node: SCNNode, for anchor: ARAnchor) {
//        if let planeAnchor = anchor as? ARPlaneAnchor {
//            updatePlane(anchor: planeAnchor)
//        }
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
        let cameraPosition = SCNVector3(x: frame.camera.transform.columns.3.x, y: frame.camera.transform.columns.3.y, z: frame.camera.transform.columns.3.z)
        
        let mat = simd_float4x4(firstNode.transform)
        let row1: [Double] = [Double(mat.columns.0.x), Double(mat.columns.1.x), Double(mat.columns.2.x), Double(mat.columns.3.x)]
        let row2: [Double] = [Double(mat.columns.0.y), Double(mat.columns.1.y), Double(mat.columns.2.y), Double(mat.columns.3.y)]
        let row3: [Double] = [Double(mat.columns.0.z), Double(mat.columns.1.z), Double(mat.columns.2.z), Double(mat.columns.3.z)]
        let row4: [Double] = [Double(mat.columns.0.w), Double(mat.columns.1.w), Double(mat.columns.2.w), Double(mat.columns.3.w)]
        let mat1 = Matrix([row1, row2, row3, row4])
        let mat2 = inv(mat1)
        
        let pointAR = Vector([Double(cameraPosition.x), Double(cameraPosition.y), Double(cameraPosition.z), 1.0])
        let pointGlobal = mat2 * Matrix(pointAR)
        xLabel.text = String(format: "x: %f", pointGlobal[0])
        yLabel.text = String(format: "y: %f", pointGlobal[1])
        zLabel.text = String(format: "z: %f", pointGlobal[2])
        
        poseManager.process(frame: frame)
        self.frameCount += 1
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


extension ViewController: LightAnchorPoseManagerDelegate {
    func lightAnchorPoseManager(_: LightAnchorPoseManager, didUpdate transform: SCNMatrix4) {
        sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4(transform))
        //firstNode.transform = transform
    }
    
    func lightAnchorPoseManager(_: LightAnchorPoseManager, didUpdatePointsFor codeIndex: Int, displayMeanX: Float, displayMeanY: Float, displayStdDevX: Float, displayStdDevY: Float) {
        updateClusterView(codeIndex: codeIndex, displayMeanX: displayMeanX, displayMeanY: displayMeanY, displayStdDevX: displayStdDevX, displayStdDevY: displayStdDevY)
    }
    
    func lightAnchorPoseManager(_: LightAnchorPoseManager, didUpdateResultImage resultImage: UIImage) {
        imageView.image = resultImage
    }
    
    
}










