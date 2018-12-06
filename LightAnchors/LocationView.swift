//
//  LocationView.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 12/5/18.
//  Copyright © 2018 Wiselab. All rights reserved.
//

import UIKit

class LocationView: UIView {

    var circleLayer: CAShapeLayer
    var lastLocation = CGPoint.zero
    
    let radius = CGFloat(3.0)
    
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    
    override init(frame: CGRect) {
        screenWidth = UIScreen.main.bounds.size.width
        screenHeight = UIScreen.main.bounds.size.height
        
        let thickness = CGFloat(1.0)
        circleLayer = CAShapeLayer()
        circleLayer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0*radius, height: 2.0*radius), cornerRadius: radius).cgPath
        circleLayer.strokeColor = UIColor.blue.cgColor
        //circleLayer.fillColor
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func move(to location: CGPoint) {
        var newLocation = location
        if newLocation.x < 0 {
            newLocation.x = 0
        }
        if newLocation.x > screenWidth {
            newLocation.x = screenWidth
        }
        if newLocation.y < 0 {
            newLocation.y = 0
        }
        if newLocation.y > screenHeight {
            newLocation.y = screenHeight
        }
        //NSLog("move to x: \(newLocation.x) y: \(newLocation.y)")
        let lastRectLocation = CGPoint(x: lastLocation.x-radius, y: lastLocation.y-radius)
        let newRectPosition = CGPoint(x: newLocation.x-radius, y: newLocation.y-radius)
        let circleAnimation = CABasicAnimation(keyPath: "circle")
        circleAnimation.fromValue = lastRectLocation
        circleAnimation.toValue = newRectPosition
        circleAnimation.duration = 0.001
        circleLayer.add(circleAnimation, forKey: "position")
        circleLayer.position = newRectPosition
        lastLocation = newLocation
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
 

}
