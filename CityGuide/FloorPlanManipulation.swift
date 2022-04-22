//
//  FloorPlanManipulation.swift
//  CityGuide
//
//  Created by Studentadm on 4/4/22.
//

import Foundation
import UIKit

func extractCoordinates(currNode : Int) -> [Int]{
    var axis : [Int] = []
    
    for i in dArray{
        if i["beacon_id"] as! Int == currNode{
            if let checkerForHub = i["locname"] as? String{
                if checkerForHub.contains("Hub "){
                    let n = i["other"] as? String
                    if n != nil{
                        let components = n!.components(separatedBy: ",")
                        axis.append(Int(components[0])!)
                        axis.append(Int(components[1])!)
                    }
                }
            }
        }
    }
    
    return axis
}

func drawOnImage(_ image: UIImage, x : Int, y : Int) -> UIImage{
    UIGraphicsBeginImageContext(image.size)
    image.draw(at: CGPoint.zero)
    
    // Get context here
    let context = UIGraphicsGetCurrentContext()
    
    context?.setFillColor (UIColor.red.cgColor)
    context?.setAlpha(1.0)
    context?.setLineWidth(0.75)
    context?.addEllipse(in: CGRect(x: x, y: y, width: 15, height: 15))
    context?.drawPath(using: .fillStroke)
    // Save context as new UIImage
    let myImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return myImage!
}
