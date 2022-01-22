//
//  BeaconCode.swift
//  CityGuide
//
//  Created by Studentadm on 10/16/21.
//

import Foundation
import CoreLocation

// Matrix content: Node, Threshold, NSEW beacons, and distances.
var matrix : [String:Int] = [
    "node" : -1,
    "threshold" : -1,
    "beast" : -10,           //E
    "edist" : -10,
    "bneast" : -10,          //NE
    "neastdist" : -10,
    "bnwest" : -10,          //NW
    "nwestdist" : -10,
    "bseast" : -10,          //SE
    "seastdist" : -10,
    "bsouth" : -10,          //S
    "sdist" : -10,
    "bswest" : -10,          //SW
    "swestdist" : -10,
    "bwest" : -10,           // W
    "wdist" : -10,
    "bnorth" : -10,          // N
    "ndist" : -10
]
var matrixDictionary : [Int:Any] = [:]
var current = -1
var shortestPath : [Int] = []
var pathFound = false

func groupChangeNoticed(){
    matrixDictionary.removeAll()
}

func makeMatrix(template : [String:Any]){
    var numsens = -1
    if !template.isEmpty{
        let keys = matrix.keys
        for i in keys{
            let val = Int(truncating: template[i] as! NSNumber)
            matrix[i] = Int(val)
        }
        numsens = Int(truncating: template["numsens"] as! NSNumber)
        if matrixDictionary.isEmpty{
            for i in 0...numsens{
                matrixDictionary[i] = [:]
            }
        }
    }
    

    if matrix["node"] != -1 && !matrix.isEmpty{
        let nodeVal = Int(truncating: matrix["node"] as! NSNumber)
        matrixDictionary[nodeVal] = matrix
    }

}

func pathFinder(current : Int, destination : Int) -> [Int]{
    var visited : [Int] = []            // An array of visted nodes
    var unvisited : [Int] = []          // An array of unvisited nodes
    var currentNode = current
    var shortest : [Int] = []
    var pathDictionary : [Int : [Int]] = [ : ]
    
    for keys in matrixDictionary.keys{
        if let m = matrixDictionary[keys] as? [String:Int]{
            if m.count != 0{
                pathDictionary[keys] = [10000000000,-1]
                unvisited.append(keys)
            }
        }
    }
    
    unvisited = unvisited.sorted()
    
    pathDictionary[currentNode] = [0,-1]
    
//    Test to check matrix validity of matrixDictionary.
//    var arr : [Int] = []
//    for i in matrixDictionary.keys{
//        arr.append(i)
//        arr = arr.sorted()
//    }
//    for j in arr{
//        print(matrixDictionary[j])
//    }
    
    if currentNode == destination{
        shortest.append(currentNode)
        pathFound = true
        return shortest
    }
    else{
        var nextNodeArr : [Int] = []                   // Next node after setting the smallest cost
        while !unvisited.isEmpty{
            //print(currentNode)
            let connections = matrixDictionary[currentNode] as! [String:Int]    // Gives us matrix
            
            var currentCost : Int = (pathDictionary[currentNode]![0])
            var vertEdges : [Int:Int] = [:]
            
            // Had to make this manually as in a dictionary, keys are independent of each other
            
            vertEdges[Int(truncating: connections["beast"]! as NSNumber)] = connections["edist"]          //E
            
            vertEdges[Int(truncating: connections["bneast"]! as NSNumber)] = connections["neastdist"]         //NE
            
            vertEdges[Int(truncating: connections["bnwest"]! as NSNumber)] = connections["nwestdist"]         //NW
            
            vertEdges[Int(truncating: connections["bseast"]! as NSNumber)] = connections["seastdist"]         //SE
            
            vertEdges[Int(truncating: connections["bsouth"]! as NSNumber)] = connections["sdist"]         //S
            
            vertEdges[Int(truncating: connections["bswest"]! as NSNumber)] = connections["swestdist"]         //SW
            
            vertEdges[Int(truncating: connections["bwest"]! as NSNumber)] = connections["wdist"]          // W
            
            vertEdges[Int(truncating: connections["bnorth"]! as NSNumber)] = connections["ndist"]         // N
            
            let connKeys = vertEdges.keys   // contains keys of the above matrix
            for i in connKeys{              // Check for the an edge
                if i != -10 && connKeys.count != 2{
                    // its a node
                    if !visited.contains(i){
                        currentCost = (pathDictionary[currentNode]![0])
                        currentCost = currentCost + vertEdges[i]!
                        if (pathDictionary[i]![0]) > currentCost{
                            pathDictionary[i]![0] = currentCost
                            pathDictionary[i]![1] = currentNode
                            if !nextNodeArr.contains(i){
                                nextNodeArr.append(i)
                            }
                        }
                    }
                }
            }
            
            for frst in 0..<nextNodeArr.count{  // sorting based on cost
                let n = nextNodeArr[frst]
                let j = frst
                for scnd in j+1..<nextNodeArr.count{
                    let k = nextNodeArr[scnd]
                    if pathDictionary[n]![0] >= pathDictionary[k]![0]{
                        nextNodeArr.swapAt(frst, scnd)
                    }
                }
            }
            
            for check in nextNodeArr{       // To remove subnodes as the next jump
                let checkConnections = matrixDictionary[check] as! [String:Int]
                var Edges : [Int:Int] = [:]
                
                Edges[Int(truncating: checkConnections["beast"]! as NSNumber)] = checkConnections["edist"]          //E
                Edges[Int(truncating: checkConnections["bneast"]! as NSNumber)] = checkConnections["neastdist"]         //NE
                Edges[Int(truncating: checkConnections["bnwest"]! as NSNumber)] = checkConnections["nwestdist"]         //NW
                Edges[Int(truncating: checkConnections["bseast"]! as NSNumber)] = checkConnections["seastdist"]         //SE
                Edges[Int(truncating: checkConnections["bsouth"]! as NSNumber)] = checkConnections["sdist"]         //S
                Edges[Int(truncating: checkConnections["bswest"]! as NSNumber)] = checkConnections["swestdist"]         //SW
                Edges[Int(truncating: checkConnections["bwest"]! as NSNumber)] = checkConnections["wdist"]          // W
                Edges[Int(truncating: checkConnections["bnorth"]! as NSNumber)] = checkConnections["ndist"]         // N
                
                if Edges.keys.count == 2{
                    nextNodeArr.remove(at: nextNodeArr.firstIndex(of: check)!)
                    
                    if !visited.contains(check) && unvisited.contains(check){
                        visited.append(check)
                        unvisited.remove(at: unvisited.firstIndex(of: check)!)
                    }
                }
            }
            
            if !nextNodeArr.isEmpty{
                if !visited.contains(currentNode) && unvisited.contains(currentNode){
                    visited.append(currentNode)
                    unvisited.remove(at: unvisited.firstIndex(of: currentNode)!)
                }
                if nextNodeArr.contains(currentNode){
                    nextNodeArr.remove(at: nextNodeArr.firstIndex(of: currentNode)!)
                }
                
                if !nextNodeArr.isEmpty{
                    currentNode = nextNodeArr.first!
                }
            }
            else{
                if !visited.contains(currentNode) && unvisited.contains(currentNode){
                    visited.append(currentNode)
                    unvisited.remove(at: unvisited.firstIndex(of: currentNode)!)
                }
            }
        }
        
//        for k in pathDictionary.keys{
//            let a = pathDictionary[k]
//            print("From: " + String(current))
//            print("To: " + String(k))
//            print("Cost: " + String(a![0]))
//            print("Previous Node: " + String(a![1]))
//            print("=====================================")
//        }
        shortest = extractPath(matrix: pathDictionary, start: current, Finish: destination)
        
        pathFound = true
        return shortest
    }
    
}

func extractPath(matrix : [Int : [Int]], start : Int, Finish : Int) -> [Int]{
    var path : [Int] = []
    var prevNode : Int = -1

    for keys in matrix.keys{
        if Finish == keys{
            path.append(Finish)
            prevNode = matrix[keys]![1]
        }
    }
    
    if prevNode == start{
        path.append(prevNode)
    }
    else{
        while(prevNode != start){
            path.append(prevNode)
            prevNode = matrix[prevNode]![1]
        }
        path.append(prevNode)
    }
    
    path = path.reversed()
    return path
}
