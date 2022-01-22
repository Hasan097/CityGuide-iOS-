//
//  ViewController.swift
//  CityGuide
//
//  Created by Studentadm on 9/14/21.
//

import UIKit
import CoreLocation
import AVFoundation
import CoreHaptics

class ViewController: UIViewController, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate {
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
//    @IBOutlet weak var searchBar: UISearchBar!
//    @IBOutlet weak var searchBarPosition: NSLayoutConstraint!
    @IBOutlet weak var compassImage: UIImageView!
    @IBOutlet weak var floorPlan: UIImageView!
    
    var beaconManager : CLLocationManager?
    var locationManager : CLLocationManager?
    var userDefinedRssi: Float = 0.0
    var beaconList : [Int] = []
    var detectedGroupId = -1
    var groupID : Int = -1
    var floorNo : Int = -10
    var CURRENT_NODE = -1
    var userAngle : Double = -1
    var atBeaconInstr : [Int : String] = [:]
    let srVC = SearchResultsVC()
    let narator = AVSpeechSynthesizer()
    var currentlyAt = -1
    var engine: CHHapticEngine?
    
    //Flags
    var newGroupNoticed = false
    var getBeaconsFlag = false
    var getThePath = false
    var speechFlag = false
    var recursionFlag = false
    var indoorWayFindingFlag = false
    var stopRepeatsFlag = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        narator.delegate = self
        
        beaconManager = CLLocationManager()
        beaconManager?.delegate = self
        beaconManager?.requestAlwaysAuthorization()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingHeading()
        
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
        
        if let userInputs = UserDefaults.standard.value(forKey: "userInputItems") as? [String : Float]{
            userDefinedRssi = userInputs["Set Threshold"] ?? (-80.00)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        UIView.animate(withDuration: 0.5) {
            let angle = newHeading.trueHeading
//            let rad = angle * .pi / 180               // to convert degrees to radians
//            let degrees = angle * 180 / .pi         // to convert radinas to degrees
            self.userAngle = angle
//            print("Direction: " + String(angle))
//            print("Direction: " + String(degrees))
//            print("Direction: " + String(rad))
            self.compassImage.transform = CGAffineTransform(rotationAngle: angle)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus{
            case .authorizedAlways, .authorizedWhenInUse:
                print("Authorized")
                if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
                    if CLLocationManager.isRangingAvailable(){
                        startScanning()
                    }
                }
            case .notDetermined:
                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were undetermined.", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            case .restricted:
                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were restricted.", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            case .denied:
                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were denied.", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            @unknown default:
                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were denied.", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    func startScanning(){
        let uuid = UUID.init(uuidString: "CA1D78EA-BE1A-4580-8D87-1F60B67A80AB")!
        let beaconRegion = CLBeaconRegion.init(uuid: uuid, major: 0, identifier: "Gimbal Beacon")
        let beconIdConstraint = CLBeaconIdentityConstraint.init(uuid: uuid)
        beaconManager?.startMonitoring(for: beaconRegion)
        beaconManager?.startRangingBeacons(satisfying: beconIdConstraint)
    }
    
    func updateBeaconReading(distance : CLProximity, beacon: CLBeacon?){
        
        if beacon?.minor != nil{
            CURRENT_NODE = Int(truncating: beacon!.minor as NSNumber)
            if beaconList.contains(Int(truncating: beacon!.minor)) == false{
                let beaconID = Int(truncating: beacon!.minor)
                beaconList.append(beaconID)
                postToDB(typeOfAction: "beacons", beaconID: beaconID, auth: "eW7jYaEz7mnx0rrM", floorNum: nil, vc: self)
            }
        }
        
        if dArray.count != 0{
            let temp = dArray[0]
            if let val = temp["group_id"] as? Int{
                if groupID != val{
                    newGroupNoticed = true
                    groupID = val
                }
                if detectedGroupId != groupID && detectedGroupId != -1{
                    detectedGroupId = groupID
                    groupChangeNoticed()                // Call to get reset matrix values
                }
            }
            if let v = temp["_level"] as? Int{
                if floorNo != v{
                    floorNo = v
                    postToDB(typeOfAction: "getFloor", beaconID: groupID, auth: "eW7jYaEz7mnx0rrM", floorNum: floorNo, vc: self)
                }
            }
        }
        
        if imageView.image != nil && floorPlan.image != imageView.image{
            self.floorPlan.image = imageView.image
        }
        
        if groupID != -1 && newGroupNoticed && floorNo != -10{
            // get all the beacons for the new group.
            print("Group ID set: \(groupID)")
            postToDB(typeOfAction: "getbeacons", beaconID: groupID, auth: "eW7jYaEz7mnx0rrM", floorNum: floorNo, vc: self)
            newGroupNoticed = false
            getBeaconsFlag = true
        }
        
        if getBeaconsFlag && !listOfBecaon.isEmpty{ // get all values of the new set of beacons
            for i in listOfBecaon{
                if !beaconList.contains(i){
                    beaconList.append(i)
                    postToDB(typeOfAction: "beacons", beaconID: i, auth: "eW7jYaEz7mnx0rrM", floorNum: nil, vc: self)
                }
            }
            getBeaconsFlag = false
        }
        
        if destinations.count != srVC.locations.count{
            srVC.getLocations(values: destinations)
        }
        
        if pathFound{
            print("Path Found!")
            for i in dArray{
                if i["beacon_id"] as! Int == CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            let n = i["node"] as! Int
                            if n != shortestPath.first!{
                                let utterance = AVSpeechUtterance(string: "Re-Routing")
                                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                narator.speak(utterance)
                                shortestPath = pathFinder(current: n, destination: shortestPath.last!)
                            }
                        }
                    }
                }
            }
            print(shortestPath)
            if userAngle != -1{
                atBeaconInstr = instructions(path: shortestPath, angle: userAngle)
                speechFlag = true
                recursionFlag = false
                indoorWayFindingFlag = true
            }
            else{
                print("User's Angle is still -1")
            }
            pathFound = false
        }
        
        switch distance {
        case .unknown:
            print("No Beacons Detected: ")
        case .immediate:
            print("Beacon is very close: " + String(describing: beacon!.minor) + " " + String(beacon!.rssi))
            if indoorWayFindingFlag{
                if !checkForReRoute(currNode: CURRENT_NODE){
                    indoorWayFinding(beaconRSSI: beacon!.rssi)
                    stopRepeatsFlag = true
                }
            }
        case .near:
            print("Beacon is near: "  + String(describing: beacon!.minor) + " " + String(beacon!.rssi))
            if indoorWayFindingFlag{
                if !checkForReRoute(currNode: CURRENT_NODE){
                    indoorWayFinding(beaconRSSI: beacon!.rssi)
                    stopRepeatsFlag = true
                }
            }
        case .far:
            print("Beacon is Far: "  + String(describing: beacon!.minor) + " " + String(beacon!.rssi))
            // rssi must be less than the set threshold
            if Float(beacon!.rssi) > userDefinedRssi && indoorWayFindingFlag{
                if indoorWayFindingFlag{
                    if !checkForReRoute(currNode: CURRENT_NODE){
                        indoorWayFinding(beaconRSSI: beacon!.rssi)
                        stopRepeatsFlag = true
                    }
                }
            }
            else{
                if indoorWayFindingFlag && stopRepeatsFlag{
                    let utterance = AVSpeechUtterance(string: "Please move closer to a recognizable beacon")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    narator.speak(utterance)
                    stopRepeatsFlag = false
                }
            }
        @unknown default:
            print("No Beacons Detected (Default)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        var filteredBeacons : [CLBeacon] = []
        for i in beacons{
            if i.rssi != 0{
                filteredBeacons.append(i)
            }
        }

        if let beacon = filteredBeacons.first{
            updateBeaconReading(distance: beacon.proximity, beacon: beacon)
        }
        else{
            updateBeaconReading(distance: .unknown, beacon: nil)
        }
    }
    
    func presentAlert(alert : UIAlertController){
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func didTapSettingsButton(){
        let tvc = SettingsTableController()
        tvc.items = [
            "User Category",
            "Route Preview",
            "Distance Unit",
            "Referece Distance Unit",
            "Orientation Preference" ,
            "Monitoring" ,
            "Step Size (ft)",
            "Weighted Moving Average",
            "Set Threshold" ,
            "Timer (Seconds)",
            "Searching Radius (Meters)" ,
            "GPS Accuracy"
        ]
        tvc.title = "Settings"
        
        navigationController?.pushViewController(tvc, animated: true)

    }
    
    
    @IBAction func searchTapped(_ sender: Any) {
        for i in dArray{
            if i["beacon_id"] as! Int == CURRENT_NODE{
                if let checkerForHub = i["locname"] as? String{
                    if checkerForHub.contains("Hub "){
                        let n = i["node"] as! Int
                        srVC.setCurrentNode(node: n)
                    }
                }
            }
        }
        navigationController?.pushViewController(srVC, animated: true)
    }
    
    func indoorWayFinding(beaconRSSI : Int){
        if speechFlag && !recursionFlag{
            hapticVibration()
            for i in dArray{
                if i["beacon_id"] as! Int == CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            let n = i["node"] as! Int
                            let validRSSI = i["threshold"] as! Float
                            if Float(beaconRSSI) < validRSSI{     // Check if within RSSI range set by server entry
                                if atBeaconInstr[n]!.contains("destination."){
                                    indoorWayFindingFlag = false
                                    print("Near Destination")
                                    hapticVibration(atDestination: true)
                                }
                                let utterance = AVSpeechUtterance(string: atBeaconInstr[n]!)
                                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                narator.speak(utterance)
                            }
                        }
                    }
                }
            }
            currentlyAt = CURRENT_NODE
            recursionFlag = true
        }
        if currentlyAt != CURRENT_NODE{
            recursionFlag = false
        }
    }
    
    func checkForReRoute(currNode : Int) -> Bool{
        for i in dArray{
            if i["beacon_id"] as! Int == currNode{
                if let checkerForHub = i["locname"] as? String{
                    if checkerForHub.contains("Hub "){
                        let n = i["node"] as! Int
                        if !shortestPath.contains(n){
                            let utterance = AVSpeechUtterance(string: "Rerouting")
                            hapticVibration()
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            narator.speak(utterance)
                            shortestPath = pathFinder(current: n, destination: shortestPath.last!)
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func hapticVibration(atDestination : Bool? = false){
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
        let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 0)
        let parameter = CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [start, end], relativeTime: 0)

        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [sharpness, intensity], relativeTime: 0, duration: 0.5)
        
        if atDestination! == true{
            usleep(500000) //0.5 seconds
        }

        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [parameter])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}


