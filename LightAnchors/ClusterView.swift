//
//  ClusterView.swift
//  LightAnchors
//
//  Created by Nick Wilkerson on 3/10/19.
//  Copyright © 2019 Wiselab. All rights reserved.
//

import UIKit

class ClusterView: UIView {

    
    var location = CGPoint(x: 0, y: 0)
    var radius:CGFloat = 0.0
    
    var color = UIColor.white
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false
    }
    
    func update(location: CGPoint, radius: CGFloat) {
        if location.x.isNaN || location.y.isNaN || radius.isNaN {
            self.location = CGPoint(x: 0, y: 0)
            self.radius = 0
        } else {
            self.location = location
            self.radius = radius
        }
        
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            NSLog("no context")
            return
        }
        
        context.setLineWidth(1.0)
        context.setStrokeColor(color.cgColor)
        context.addArc(center: CGPoint(x: location.x, y: location.y), radius: radius, startAngle: 0.0, endAngle: CGFloat.pi*2.0, clockwise: true)
        context.strokePath()
        
    }
 

}
