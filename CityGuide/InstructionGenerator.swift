//
//  InstructionGenerator.swift
//  CityGuide
//
//  Created by Studentadm on 1/18/22.
//

import Foundation

func getDirection(angl : Double) -> String{
    if (angl < 22.5 || angl >= 337.5){
        return "N"
    }
    if (angl >= 22.5 && angl < 67.5){
        return "NE"
    }
    if (angl >= 67.5 && angl < 112.5){
        return "E"
    }
    if (angl >= 112.5 && angl < 157.5){
        return "SE"
    }
    if (angl >= 157.5 && angl < 202.5){
        return "S"
    }
    if (angl >= 202.5 && angl < 247.5){
        return "SW"
    }
    if (angl >= 247.5 && angl < 292.5){
        return "W"
    }
    if (angl >= 292.5 && angl < 337.5){
        return "NW"
    }
        
    return "Error"
}

func turnTowards(from : String, to : String) -> String{
    var guidance : String = "Error"
    let circle : [String] = ["N","NE","E","SE","S","SW","W","NW"]
    let toIndex = circle.firstIndex(of: to) // Possible index [0 to 7]
    let fromIndex = circle.firstIndex(of: from) // Possible index [0 to 7]
    let sub = fromIndex! - toIndex!
    
    var user = 1
    let userProfile = UserDefaults.standard.value(forKey: "checkmarks") as? [String:Int]
    if !userProfile!.isEmpty{
        user = userProfile!["User Category"]!
    }
    // user = 1 or 2 is a sighted user and user = 0 is blind
    if user == 1 || user == 2{
        switch(sub){
            case 0:
                guidance = "Go straight for "
            case let n where n == -1 || n == 7:
                guidance = "Turn slight right and go straight for "
            case let n where n == 1 || n == -7:
                guidance = "Turn slight left and go straight for "
            case let n where n == -2 || n == 6:
                guidance = "Take a sharp right and go straight for "
            case let n where n == 2 || n == -6:
                guidance = "Take a sharp left and go straight for "
            case let n where n == 4 || n == -4:
                guidance = "Turn around and go straight for "
            case let n where n == -3 || n == 5:
                guidance = "Turn 4 O'Clock and go straight for "
            case let n where n == 3 || n == -5:
                guidance = "Turn 7 O'Clock and go straight for "
            default :
                guidance = "Error"
        }
    }
    else{
        switch(sub){
            case 0:
                guidance = "Go straight"
            case let n where n == -1 || n == 7:
                guidance = "Turn slight right and go straight"
            case let n where n == 1 || n == -7:
                guidance = "Turn slight left and go straight"
            case let n where n == -2 || n == 6:
                guidance = "Take a sharp right and go straight"
            case let n where n == 2 || n == -6:
                guidance = "Take a sharp left and go straight"
            case let n where n == 4 || n == -4:
                guidance = "Turn around and go straight"
            case let n where n == -3 || n == 5:
                guidance = "Turn 4 O'Clock and go straight"
            case let n where n == 3 || n == -5:
                guidance = "Turn 7 O'Clock and go straight"
            default :
                guidance = "Error"
        }
    }
    
    return guidance
}

func distCalculator (cost : Int) -> String{
    var distanceDialog = ""
    var unitOfMeasurement = -1
    if let userInputs = UserDefaults.standard.value(forKey: "checkmarks") as? [String : Int]{
        unitOfMeasurement = userInputs["Distance Unit"] ?? -1
    }
    var user = 1
    let userProfile = UserDefaults.standard.value(forKey: "checkmarks") as? [String:Int]
    if !userProfile!.isEmpty{
        user = userProfile!["User Category"]!
    }
    
    if unitOfMeasurement == 0 && (user == 1 || user == 2){
        //meters
        distanceDialog = (String(cost) + " meters")
    }
    else if unitOfMeasurement == 1 && (user == 1 || user == 2){
        //feet
        var toFeet = Double(cost) * 3.28
        toFeet = Double(round(100 * toFeet) / 100)
        distanceDialog = (String(Int(toFeet)) + " feet")
    }
    else if (user == 1 || user == 2) {
        //error
        distanceDialog = "Error"
    }
    return distanceDialog
}

func cardinalDirection(compassIndication : String, userDirection : String) -> String{
    var guidance : String = "Error"
    let circle : [String] = ["bnorth", "bneast", "beast", "bseast", "bsouth", "bswest", "bwest", "bnwest"]
    let compass : [String] = ["N","NE","E","SE","S","SW","W","NW"]
    let toIndex = circle.firstIndex(of: compassIndication) // Possible index [0 to 7]
    let fromIndex = circle.firstIndex(of: circle[compass.firstIndex(of: userDirection)!]) // Possible index [0 to 7]
    let sub = fromIndex! - toIndex!
    
    switch(sub){
        case 0:
            guidance = "straight ahead"
        case let n where n == -1 || n == 7:
            guidance = "slightly right"
        case let n where n == 1 || n == -7:
            guidance = "slightly left"
        case let n where n == -2 || n == 6:
            guidance = "to your right"
        case let n where n == 2 || n == -6:
            guidance = "to your left"
        case let n where n == 4 || n == -4:
            guidance = "straight behind"
        case let n where n == -3 || n == 5:
            guidance = "at 4 O'Clock"
        case let n where n == 3 || n == -5:
            guidance = "at 7 O'Clock"
        default :
            guidance = "Error"
    }
    
    return guidance
}

func generatePOIDirections(POI : [Int], angle : Double, currentNode : Int) -> [Int : String]{
    let conn = matrixDictionary[currentNode] as! [String:Int]
    let possibleBeaconLocations = ["bnorth", "bneast", "beast", "bseast", "bsouth", "bswest", "bwest", "bnwest"]
    var cardinalMatrix : [Int: String] = [:]
    
    for i in possibleBeaconLocations{
        if POI.contains(Int(truncating: conn[i]! as NSNumber)){
            let k = POI[POI.firstIndex(of: Int(truncating: conn[i]! as NSNumber))!]
            cardinalMatrix[k] = cardinalDirection(compassIndication: i, userDirection: getDirection(angl: angle))
        }
    }
    
    return cardinalMatrix
}

func instructions(path : [Int], angle : Double) -> [Int : String]{
    var atBeaconInstruction : [Int : String] = [:]
    let userDirection = getDirection(angl: angle)
    let possibleBeaconLocations = ["bnorth", "bneast", "beast", "bseast", "bsouth", "bswest", "bwest", "bnwest"]
    let costToBeacon = ["ndist", "neastdist", "edist", "seastdist", "sdist", "swestdist", "wdist", "nwestdist"]
    let comapssDirection = ["N","NE","E","SE","S","SW","W","NW"]
    var dis = ""
    var instructionToUser : [String] = []
    var to = ""
    var from = ""
    
    if path.count == 1{
        //Already at destination
        instructionToUser.append("You are within range of your destination.")
    }
    else{
        for i in path{
            let conn = matrixDictionary[i] as! [String:Int]
            
            if i == path.first{
                from = userDirection
            }
            if path[path.firstIndex(of: i)! + 1] == path.last{ // if on the second last node
                for nextNode in possibleBeaconLocations{
                    if Int(truncating: conn[nextNode]! as NSNumber) == path.last{
                        to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                        let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                        dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                        instructionToUser.append(turnTowards(from: from, to: to) + dis + " to reach your destination.")
                        break
                    }
                }
                break
            }
            
            for nextNode in possibleBeaconLocations{
                if Int(truncating: conn[nextNode]! as NSNumber) == path[path.firstIndex(of: i)! + 1]{
                    to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                    let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                    dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                    instructionToUser.append(turnTowards(from: from, to: to) + dis)
                }
            }
            from = to
        }
    }
    for k in path{
        if k != path.last{
            atBeaconInstruction[k] = instructionToUser[path.firstIndex(of: k)!]
        }
    }
    
    return atBeaconInstruction
}
