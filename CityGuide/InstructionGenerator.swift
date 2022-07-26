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

func cardinalDirection(compassIndication : String, userDirection : String) -> String{       // Used for exploration mode
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

func generatePOIDirections(POI : [Int], angle : Double, currentNode : Int) -> [Int : String]{           // Used for exploration mode
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

func getOppositeDirection(dir : String) -> String{
    switch(dir){
    case "N":
        return "S"
    case "S":
        return "N"
    case "E":
        return "W"
    case "W":
        return "E"
    case "NE":
        return "SW"
    case "NW":
        return "SE"
    case "SE":
        return "NW"
    case "SW":
        return "NE"
    default:
        return "Error"
    }
}

func instructions(path : [Int], angle : Double) -> [Int : String]{      // Used for Navigation mode
    var atBeaconInstruction : [Int : String] = [:]
    let userDirection = getDirection(angl: angle)
    let possibleBeaconLocations = ["bnorth", "bneast", "beast", "bseast", "bsouth", "bswest", "bwest", "bnwest"]
    let costToBeacon = ["ndist", "neastdist", "edist", "seastdist", "sdist", "swestdist", "wdist", "nwestdist"]
    let comapssDirection = ["N","NE","E","SE","S","SW","W","NW"]
    var dis = ""
    var instructionToUser : [String] = []
    var to = ""
    var from = ""
    var pathCopy = path
    
    if pathCopy.count == 1{
        //Already at destination
        instructionToUser.append("You are within range of your destination.")
    }
    else{
        for i in path{
            let conn = matrixDictionary[i] as! [String:Int]
            // check if i is elevator && if i is not the last element in the path?
            if(pathCopy.contains(i) && pathCopy.firstIndex(of: i)! < pathCopy.count-1){
                var checkForElevator = ""
                var checkForElevator2 = ""
                var toFloor = 0
                let index = pathCopy.firstIndex(of: i)
                if index!+1 < pathCopy.count-1 && index!+2 <= pathCopy.count-1{
                    for j in dArray{
                        if j["node"] as! Int == pathCopy[index! + 1]{
                            checkForElevator = (j["locname"] as? String)!
                        }
                    }
                    for j in dArray{
                        if j["node"] as! Int == pathCopy[index! + 2]{
                            checkForElevator2 = (j["locname"] as? String)!
                            toFloor = (j["_level"] as? Int)!
                        }
                    }
                }
                
                // Check for 2 elevators else normal instructions
                if checkForElevator.contains("elevator") && checkForElevator2.contains("elevator"){
                    for nextNode in possibleBeaconLocations{
                        if Int(truncating: conn[nextNode]! as NSNumber) == pathCopy[pathCopy.firstIndex(of: i)! + 1]{
                            if from == ""{
                                from = userDirection
                            }
                            to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                            let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                            dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                            break
                        }
                    }
                    
                    var removeIdx = 1
                    var e = index! + 2  // e is the second elevator index in the path
                    if(e != path.count-1){  // if its not the end of the path
                        var endElevator = checkForElevator2
                        while(endElevator.contains("elevator")){    // traverse all elevators in path ex: 1->2->3
                            e+=1
                            removeIdx+=1
                            if(e >= path.count){
                                break
                            }
                            for j in dArray{
                                if j["node"] as! Int == pathCopy[e]{
                                    endElevator = (j["locname"] as? String)!
                                    toFloor = (j["_level"] as? Int)!
                                }
                            }
                        }
                    }
                    
                    while(removeIdx > 0){
                        pathCopy.remove(at: index!+1)
                        removeIdx-=1
                    }
                    
                    if pathCopy[index!] == pathCopy.last{
                        instructionToUser.append(turnTowards(from: from, to: to) + dis + " and use the elevator to go to floor " + String(toFloor) + " to reach your destination.")
                        break
                    }
                    else{
                        instructionToUser.append(turnTowards(from: from, to: to) + dis + " and use the elevator to go to floor " + String(toFloor))
                        // We enter the elevator in one direction and exit it usign the opposite direction
                        from  = getOppositeDirection(dir: to)
                    }
                }
                else{
                    if i == pathCopy.first{
                        from = userDirection
                    }
                    if pathCopy.firstIndex(of: i)! + 1 <= pathCopy.count-1 && pathCopy[pathCopy.firstIndex(of: i)! + 1] == pathCopy.last{ // if on the second last node
                        var elevatorFlag = false
                        for nextNode in possibleBeaconLocations{
                            if from == ""{
                                elevatorFlag = true
                                break
                            }
                            if Int(truncating: conn[nextNode]! as NSNumber) == pathCopy.last{
                                to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                                let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                                dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                                instructionToUser.append(turnTowards(from: from, to: to) + dis + " to reach your destination.")
                                break
                            }
                        }
                        if elevatorFlag{
                            let prevConn = matrixDictionary[path[path.firstIndex(of: i)! - 1]] as! [String:Int]
                            
                            for nextNode in possibleBeaconLocations{
                                if Int(truncating: conn[nextNode]! as NSNumber) == pathCopy.last{
                                    to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                                    break
                                }
                            }
                            
                            for nextNode in possibleBeaconLocations{
                                if Int(truncating: prevConn[nextNode]! as NSNumber) == i{
                                    from = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                                    let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                                    dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                                    instructionToUser.append(turnTowards(from: from, to: to) + dis + " to reach your destination.")
                                    break
                                }
                            }
                            
                        }
                        break
                    }
                    
                    for nextNode in possibleBeaconLocations{
                        if  pathCopy.firstIndex(of: i)! + 1 <= pathCopy.count-1 &&
                            Int(truncating: conn[nextNode]! as NSNumber) == pathCopy[pathCopy.firstIndex(of: i)! + 1]{
                            to = comapssDirection[possibleBeaconLocations.firstIndex(of: nextNode)!]
                            let distToCalcualate = conn[costToBeacon[possibleBeaconLocations.firstIndex(of: nextNode)!]]!
                            dis = distCalculator(cost: Int(truncating: distToCalcualate as NSNumber))
                            instructionToUser.append(turnTowards(from: from, to: to) + dis)
                        }
                    }
                    from = to
                }
            }
        }
    }
    for k in pathCopy{
        if k != pathCopy.last{
            atBeaconInstruction[k] = instructionToUser[pathCopy.firstIndex(of: k)!]
        }
        else if pathCopy.firstIndex(of: k)! < instructionToUser.count{
            let str = instructionToUser[pathCopy.firstIndex(of: k)!]
            if(str.contains(" elevator ")){
                atBeaconInstruction[k] = instructionToUser[pathCopy.firstIndex(of: k)!]
            }
        }
    }
    
    return atBeaconInstruction
}
