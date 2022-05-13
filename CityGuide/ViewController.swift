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
import Speech

class ViewController: UIViewController, CLLocationManagerDelegate, AVSpeechSynthesizerDelegate, SFSpeechRecognizerDelegate, BeaconScannerDelegate {
    
    @IBOutlet weak var naratorMute: UIButton!
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var settingsBtn: UIButton!
    @IBOutlet weak var stopBtn: UIButton!
    //    @IBOutlet weak var searchBar: UISearchBar!
    //    @IBOutlet weak var searchBarPosition: NSLayoutConstraint!
    @IBOutlet weak var compassImage: UIImageView!
    @IBOutlet weak var floorPlan: UIImageView!
    
    var beaconScanner: BeaconScanner!
    var beaconManager : CLLocationManager?
    var locationManager : CLLocationManager?
    var userDefinedRssi: Float = 0.0
    var beaconList : [Int] = []
    var detectedGroupId = -1
    var groupID : Int = -1
    var floorNo : Int = -10
    var CURRENT_NODE = -1
    var CLOSEST_RSSI = -100000.0
    var FARTHEST_NODE = -1
    var userAngle : Double = -1
    var atBeaconInstr : [Int : String] = [:]
    var poiAtCurrentNode : [Int:String] = [:]
    let srVC = SearchResultsVC()
    let narator = AVSpeechSynthesizer()
    var currentlyAt = -1
    var engine: CHHapticEngine?
    var speechRecognizer = SpeechRecognizer()
    var timer : Timer?
    var window : [Int : [Int]] = [:]
    let group = DispatchGroup()
    
    //Flags
    var newGroupNoticed = false
    var getBeaconsFlag = false
    var getThePath = false
    var speechFlag = false
    var recursionFlag = false
    var indoorWayFindingFlag = false
    var isOnRoute = false
    var stopRepeatsFlag = true
    var explorationFlag = true
    var userResponse = false
    var voiceSearchFlag = false
    var muteFlag = false
    var allowDot = false
    var searchListResetFlag = false
    
    @objc func buttonDown(_ sender: UIButton) {
        singleFire(check: nil)
    }

    @objc func buttonUp(_ sender: UIButton) {
        timer?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        narator.delegate = self
        
//        beaconManager = CLLocationManager()
//        beaconManager?.delegate = self
//        beaconManager?.requestAlwaysAuthorization()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingHeading()
        
        becomeFirstResponder()
        
        if UIDevice.current.userInterfaceIdiom == .phone{
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("There was an error creating the engine: \(error.localizedDescription)")
            }
        }
        
        if let userInputs = UserDefaults.standard.value(forKey: "userInputItems") as? [String : Float]{
            userDefinedRssi = userInputs["Set Threshold"] ?? (-80.00)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
        recButton.addTarget(self, action: #selector(buttonDown), for: .touchDown)
        recButton.addTarget(self, action: #selector(buttonUp), for: [.touchUpInside, .touchUpOutside])
        
        self.beaconScanner = BeaconScanner()
        self.beaconScanner!.delegate = self
        self.beaconScanner!.startScanning()
        
        self.naratorMute.setImage(UIImage(systemName: "volume.fill"), for: .normal)
        self.naratorMute.tintColor = .black
        self.recButton.tintColor = .black
        self.stopBtn.tintColor = .black
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake{
            doubleTapped()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        stopBtn.isHidden = true
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
    
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        switch manager.authorizationStatus{
//            case .authorizedAlways, .authorizedWhenInUse:
//                print("Authorized")
//                if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
//                    if CLLocationManager.isRangingAvailable(){
//                        startScanning()
//                    }
//                }
//            case .notDetermined:
//                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were undetermined.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            case .restricted:
//                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were restricted.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            case .denied:
//                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were denied.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//            @unknown default:
//                let alert = UIAlertController.init(title: "Cannot Find Beacons", message: "Permissions were denied.", preferredStyle: .alert)
//                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
//                self.present(alert, animated: true, completion: nil)
//        }
//    }
    
//    func startScanning(){
//        let uuid = UUID.init(uuidString: "CA1D78EA-BE1A-4580-8D87-1F60B67A80AB")!
//        let beaconRegion = CLBeaconRegion.init(uuid: uuid, major: 0, identifier: "Gimbal Beacon")
//        let beconIdConstraint = CLBeaconIdentityConstraint.init(uuid: uuid)
//        beaconManager?.startMonitoring(for: beaconRegion)
//        beaconManager?.startRangingBeacons(satisfying: beconIdConstraint)
//    }
    //
    
    func didFindBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
        //NSLog("FIND: %@", beaconInfo.description)
        callOperations(beaconScanner: beaconScanner, beaconInfo: beaconInfo)
    }
    
    func didLoseBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
        //NSLog("LOST: %@", beaconInfo.description)
    }
    func didUpdateBeacon(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo) {
        //NSLog("UPDATE: %@", beaconInfo.description)
        callOperations(beaconScanner: beaconScanner, beaconInfo: beaconInfo)
    }
    
    func callOperations(beaconScanner: BeaconScanner, beaconInfo: BeaconInfo){
        if userDefinedRssi == 0.0{
            userDefinedRssi = -80.0
        }
        if(beaconInfo.RSSI >= Int(userDefinedRssi) && beaconInfo.RSSI < -45){
            if(window[beaconInfo.beaconID.bID] == nil){
                let arr = [beaconInfo.RSSI]
                window[beaconInfo.beaconID.bID] = arr
            }
            else{
                var arr = window[beaconInfo.beaconID.bID]
                if arr!.count >= 4{
                    arr?.remove(at: 0)
                }
                arr?.append(beaconInfo.RSSI)
                window[beaconInfo.beaconID.bID] = arr
                for i in window.keys{
                    if window[i] != arr{
                        if window[i]!.count >= 4{
                            window[i]?.remove(at: 0)
                        }
                        window[i]!.append(-100)
                    }
                }
            }
        }
        
        checkWindow()
        
        if(CURRENT_NODE != -1 && CLOSEST_RSSI > Double(userDefinedRssi)){
            updateBeaconReading(distance: CLOSEST_RSSI, beacon: CURRENT_NODE)
        }
    }
    
    func didObserveURLBeacon(beaconScanner: BeaconScanner, URL: NSURL, RSSI: Int) {
        //do nothing here
    }
    
    // Screening window code and functions
    // ===================================
    func checkWindow(){
        var maxNumOfDetection = 0
        var singleRssiArray = 0
        var doubleRssiArray = 0
        print("==================================")
        for i in window.keys{
            print(String(i), terminator: ": ")
            print(window[i]!)
            maxNumOfDetection+=1
        }
        print("==================================")
        if(maxNumOfDetection > 5){
            for i in window.keys{
                let checker = window[i]!;
                var sum = 0
                for i in checker{
                    sum += i
                }
                
                if(checker.count == 1){
                    singleRssiArray+=1
                }
                if(checker.count == 2){
                    doubleRssiArray+=1
                }
                
                if Float(sum/checker.count) < userDefinedRssi{
                    window.removeValue(forKey: i)
                }
                if !listOfBeacon.contains(i){
                    window.removeValue(forKey: i)
                }
            }
        }
        
        if(singleRssiArray > 3 || doubleRssiArray > 3){
            for i in window.keys{
                let checker = window[i]!
                if(checker.count == 1 && singleRssiArray > 3){
                    window.removeValue(forKey: i)
                }
                if(checker.count == 2 && doubleRssiArray > 3){
                    window.removeValue(forKey: i)
                }
            }
        }
        maxNumOfDetection = 0
        screeningWindow()
    }
    
    func screeningWindow(){
        var closestRssi = -100000.0
        var closestBeacon = 0
        var farthestBeacon = 0
        var farthestRssi = 100000.0
        for i in window.keys{
            let arr = window[i]
            let arrSize = arr?.count
            var numerator = 0
            
            if(arrSize! >= 4){
                var weight = arrSize!
                
                for vector in arr!{
                    numerator = numerator + (-1 * vector * (weight))
                    weight-=1
                }
                var denominator = 0
                for w in 1...arrSize!{
                    denominator += w
                }
                
                let temp = closestRssi
                let far = farthestRssi
                
                closestRssi = max(closestRssi, -1.0 * Double(numerator / denominator))
                farthestRssi = min(farthestRssi, -1.0 * Double(numerator / denominator))
                
                if closestRssi != temp{
                    closestBeacon = i
                }
                if farthestRssi != far{
                    farthestBeacon = i
                }
            }
        }
        
        if(closestBeacon != 0){
            CURRENT_NODE = closestBeacon
            CLOSEST_RSSI = closestRssi
            FARTHEST_NODE = farthestBeacon
        }
        if FARTHEST_NODE != -1 && CURRENT_NODE != FARTHEST_NODE{
            window.removeValue(forKey: FARTHEST_NODE)
        }
        if(groupID == -1){
            newGroupNoticed = true
        }
        print("Closest Beacon : " + String(CURRENT_NODE) + " Rssi : " + String(CLOSEST_RSSI) + " Group : " + String(groupID))
        
        for i in dArray{    // to match groupid and floorplan
            if i["beacon_id"] as! Int == CURRENT_NODE{
                if let checkerForHub = i["locname"] as? String{
                    if checkerForHub.contains("Hub "){
                        let n = i["group_id"] as? Int
                        if n != groupID{
                            newGroupNoticed = true
                            break
                        }
                        let flr = i["_level"] as? Int
                        if flr != floorNo{
                            floorNo = flr!
                            allowDot = false
                            postToDB(typeOfAction: "getFloor", beaconID: groupID, auth: "eW7jYaEz7mnx0rrM", floorNum: floorNo, vc: self)
                            DispatchQueue.main.async {
                                if image != nil && self.floorPlan.image != image && !self.allowDot{
                                    self.floorPlan.image = image
                                    self.allowDot = true
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            if(self.CURRENT_NODE != -1 && self.floorPlan.image != nil){
                let coordinates = extractCoordinates(currNode: self.CURRENT_NODE)
                if(!coordinates.isEmpty && image != nil){
                    self.floorPlan.image = image
                    self.floorPlan.image = drawOnImage(self.floorPlan.image!, x: coordinates[0], y: coordinates[1])
                }
            }
        }
    }
    // ===================================
    
    
    func updateBeaconReading(distance : Double, beacon: Int){
        
        if beacon != -1{
            if beaconList.contains(beacon) == false{
                beaconList.append(beacon)
                postToDB(typeOfAction: "beacons", beaconID: beacon, auth: "eW7jYaEz7mnx0rrM", floorNum: nil, vc: self)
            }
        }
        
        if dArray.count != 0 && newGroupNoticed{
            for i in dArray{    // to match groupid and floorplan
                if i["beacon_id"] as! Int == CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            let n = i["group_id"] as? Int
                            if n != groupID{
                                groupID = n!
                            }
                            if detectedGroupId != groupID && detectedGroupId != -1{
                                detectedGroupId = groupID
                                groupChangeNoticed()                // Call to get reset matrix values
                            }
                            if let v = i["_level"] as? Int{
                                if floorNo != v{
                                    floorNo = v
                                    postToDB(typeOfAction: "getFloor", beaconID: groupID, auth: "eW7jYaEz7mnx0rrM", floorNum: floorNo, vc: self)
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            if image != nil && self.floorPlan.image != image && !self.allowDot{
                self.floorPlan.image = image
                self.allowDot = true
            }
        }
        
        if groupID != -1 && newGroupNoticed && floorNo != -10{
            // get all the beacons for the new group.
            print("Group ID set: \(groupID)")
            self.allowDot = false
            listOfBeacon.removeAll()
            destinations.removeAll()
            matrixDictionary.removeAll()
            postToDB(typeOfAction: "getbeacons", beaconID: groupID, auth: "eW7jYaEz7mnx0rrM", floorNum: floorNo, vc: self)
            newGroupNoticed = false
            getBeaconsFlag = true
            searchListResetFlag = true
        }
        
        if getBeaconsFlag && !listOfBeacon.isEmpty{ // get all values of the new set of beacons
            dArray.removeAll()
            beaconList.removeAll()
            for i in listOfBeacon{
                if !beaconList.contains(i){
                    beaconList.append(i)
                    postToDB(typeOfAction: "beacons", beaconID: i, auth: "eW7jYaEz7mnx0rrM", floorNum: nil, vc: self)
                }
            }
            
            if(explorationFlag){
                speechFlag = true
                recursionFlag = false
            }
            getBeaconsFlag = false
        }
        
        if destinations.count != srVC.locations.count || searchListResetFlag{
            srVC.getLocations(values: destinations)
            searchListResetFlag = false
        }
        
        if pathFound{
            print("Path Found!")
            for i in dArray{
                if i["beacon_id"] as! Int == CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            let n = i["node"] as! Int
                            if n != shortestPath.first!{
                                speakThis(sentence: "Re-Routing")
                                shortestPath = pathFinder(current: n, destination: shortestPath.last!)
                                break
                            }
                        }
                    }
                }
            }
            print(shortestPath)
            if userAngle != -1{
                atBeaconInstr = instructions(path: shortestPath, angle: userAngle)
                indoorKeyIgnition()
            }
            else{
                print("User's Angle is still -1")
            }
            pathFound = false
        }
        
//            print("Beacon: " + String(describing: beacon) + " " + String(distance))
        if distance > Double(userDefinedRssi) && explorationFlag && !indoorWayFindingFlag{
            explorationMode(currentNode: CURRENT_NODE)
        }
        if distance > Double(userDefinedRssi) && indoorWayFindingFlag{
            if !self.checkForReRoute(currNode: self.CURRENT_NODE){
                self.indoorWayFinding(beaconRSSI: Float(distance))
                self.stopRepeatsFlag = true
            }
        }
        else{
            if indoorWayFindingFlag && stopRepeatsFlag && !isOnRoute{
                if(stopBtn.isHidden){
                    stopBtn.isHidden = false
                }
                speakThis(sentence: "Please move closer to a beacon for directions.")
                stopRepeatsFlag = false
            }
        }
    }
    
//    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
//        var filteredBeacons : [CLBeacon] = []
//        for i in beacons{
//            if i.rssi != 0{
//                filteredBeacons.append(i)
//            }
//        }
        
//        if beacons.count > 0{
//            for a in beacons{
//                if a.rssi < 0{
//                    print("==> Beacon: " + String(describing: a.minor) + " RSSI: " + String(a.rssi))
//                }
//            }
//        }

//        if let beacon = filteredBeacons.first{
//            updateBeaconReading(distance: beacon.proximity, beacon: beacon)
//        }
//        else{
//            updateBeaconReading(distance: .unknown, beacon: nil)
//        }
//    }
    
    func presentAlert(alert : UIAlertController){
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func didTapStop(_ sender: Any) {
        indoorWayFindingFlag = false
        if UIDevice.current.userInterfaceIdiom == .phone{
            hapticVibration(atDestination: true)
        }
        explorationFlag = true
        speechFlag = true
        recursionFlag = false
        stopBtn.isHidden = true
        speakThis(sentence: "Routing stopped. Switching to exploration mode.")
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
                        break
                    }
                }
            }
        }
        navigationController?.pushViewController(srVC, animated: true)
    }
    
    func explorationMode(currentNode : Int){
        if destinations.isEmpty{
            return
        }
        isOnRoute = false
        var POI : [Int] = []
        var locnames : [String] = []
        var curNode = -1
        for i in dArray{
            if i["beacon_id"] as! Int == CURRENT_NODE{
                if let checkerForHub = i["locname"] as? String{
                    if !checkerForHub.contains("Hub "){
                        let n = i["node"] as! Int
                        if !POI.contains(n){
                            POI.append(n)
                            locnames.append(checkerForHub)
                        }
                    }
                    else{
                        let n = i["node"] as! Int
                        curNode = n
                    }
                }
            }
        }
        if !POI.isEmpty && userAngle != -1 && curNode != -1{
            poiAtCurrentNode = generatePOIDirections(POI: POI, angle: userAngle, currentNode: curNode)
            speechFlag = true
        }
        
        if speechFlag && !recursionFlag && !voiceSearchFlag && !muteFlag{
            //let numPOI = POI.count
            if(narator.isSpeaking){
                narator.stopSpeaking(at: .immediate)
            }
//            if numPOI > 1{
//                speakThis(sentence: "You are near " + String(numPOI) + " points of interest")
//            }
            
            for j in POI{
//                print(POI)
//                print(locnames)
//                print(poiAtCurrentNode)
                let index = POI.firstIndex(of: j)
                let sentence = locnames[index!] + " is " + poiAtCurrentNode[j]!
                speakThis(sentence: sentence)
            }
            
            currentlyAt = CURRENT_NODE
            recursionFlag = true
            speechFlag = false
        }
        if currentlyAt != CURRENT_NODE{
            recursionFlag = false
            speechFlag = true
        }
    }
    
    func indoorWayFinding(beaconRSSI : Float){
        DispatchQueue.main.async {
            if self.stopBtn.isHidden{
                    self.stopBtn.isHidden = false
            }
        }
        var exitToExplore = ""
        if speechFlag && !recursionFlag{
            if UIDevice.current.userInterfaceIdiom == .phone{
                hapticVibration()
            }
            for i in dArray{
                if i["beacon_id"] as! Int == CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            let n = i["node"] as! Int
                            let validRSSI = i["threshold"] as! Float
                            if beaconRSSI < validRSSI{     // Check if within RSSI range set by server entry
                                if atBeaconInstr[n]!.contains("destination."){
                                    indoorWayFindingFlag = false
                                    print("Near Destination")
                                    if UIDevice.current.userInterfaceIdiom == .phone{
                                        hapticVibration(atDestination: true)
                                    }
                                    explorationFlag = true
                                    speechFlag = true
                                    recursionFlag = false
                                    exitToExplore = "Switching back to Exploration Mode."
                                    DispatchQueue.main.async {
                                        if !self.stopBtn.isHidden{
                                            self.stopBtn.isHidden = true
                                        }
                                    }
                                }
                                if(narator.isSpeaking && indoorWayFindingFlag && !muteFlag){
                                    if shortestPath.contains(n){
                                        if n != shortestPath.first{
                                            while(n != shortestPath.first){
                                                shortestPath.remove(at: 0)
                                            }
                                        }
                                    }
                                    else{
                                        return
                                    }
                                    speakThis(sentence: atBeaconInstr[n]!)
                                }
                                else{
                                    if !muteFlag{
                                        speakThis(sentence: atBeaconInstr[n]!)
                                    }
                                }
                                if exitToExplore != "" && !muteFlag{
                                    speakThis(sentence: exitToExplore)
                                    indoorWayFindingFlag = false
                                    recursionFlag = true
                                    explorationFlag = true
                                }
                                isOnRoute = true
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
                            speakThis(sentence: "Rerouting")
                            if UIDevice.current.userInterfaceIdiom == .phone{
                                hapticVibration()
                            }
                            shortestPath = pathFinder(current: n, destination: shortestPath.last!)
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    func singleFire(check : Int?){
        let audioSession = AVAudioSession.sharedInstance()
        do
        {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.default)
            //try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        }
        catch
        {
            print("audioSession properties weren't set because of an error.")
        }
        
        voiceSearchFlag = true
        group.enter()
        if check == 1{
            DispatchQueue.main.async(group: group){
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    AudioServicesPlaySystemSound(1113)
                    if UIDevice.current.userInterfaceIdiom == .phone{
                        self.hapticVibration()
                    }
                    self.speechRecognizer.reset()
                    self.speechRecognizer.transcribe()
                    print("Transcription started...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4, qos: .default) {
                        self.speechRecognizer.stopTranscribing()
                        print("Transcription has stopped...")
                        print(self.speechRecognizer.transcript)
                        if(self.speechRecognizer.transcript.lowercased() == "yes" || self.speechRecognizer.transcript.lowercased() == "yup" || self.speechRecognizer.transcript.lowercased() == "confirmed"){
                            self.userResponse = true
                        }
                        self.group.leave()
                    }
                }
            }
        }
        else{
            speakThis(sentence: "Please say your destination after the indication.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                AudioServicesPlaySystemSound(1113)
                if UIDevice.current.userInterfaceIdiom == .phone{
                    self.hapticVibration()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6){
                    self.speechRecognizer.reset()
                    self.speechRecognizer.transcribe()
                    print("Transcription started...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, qos: .default) {
                        self.speechRecognizer.stopTranscribing()
                        print("Transcription has stopped...")
                        print(self.speechRecognizer.transcript)
                        self.checkForDistination(userDes: self.speechRecognizer.transcript)
                        self.group.leave()
                    }
                }
            }
        }
    }
    
    func checkForDistination(userDes : String){
        var dest = ""
        var range = 0
        var similarToDest = ""
        var userDestination = userDes
        
        //wh308 -> w h 308
        let decimalChars = CharacterSet.decimalDigits
        let decimalRange = userDestination.rangeOfCharacter(from: decimalChars)
        var temp = ""
        if decimalRange != nil{
            for i in Array(userDestination.lowercased()){
                if i.isLetter{
                    temp.append(i)
                    temp.append(" ")
                }
                else{
                    temp.append(i)
                }
            }
            userDestination = temp
        }

        for k in destinations{
            var testRange = 0
            if k.lowercased() == userDestination.lowercased(){
                dest = k
                break
            }
            else{
                let words = userDestination.lowercased()
                let destWords = k.lowercased()
                for l in words.components(separatedBy: " "){
                    if destWords.contains(l){
                        testRange+=2
                    }
//                    else{
//                        for o in destWords.components(separatedBy: " "){
//                            if l != "" && o != ""{
//                                let check = levenshtein(aStr: l, bStr: o)
//                                if(check < 3){
//                                    testRange += 1
//                                }
//                            }
//                        }
//                    }
                }
                if range < testRange{
                    range = testRange
                    similarToDest = k
                    testRange = 0
                }
            }
        }
        
        if similarToDest != ""{
            speakThis(sentence: "Did you mean " + similarToDest + "? Please confirm or say no after the indication.")
            singleFire(check: 1)            // here is the problem
            group.notify(queue: .main){
                if self.userResponse{
                    dest = similarToDest
                }
                else{
                    self.speakThis(sentence: "Search cancelled.")
                    self.voiceSearchFlag = false
                    return
                }
                var currNode = -1
                for i in dArray{
                    if i["beacon_id"] as! Int == self.CURRENT_NODE{
                        if let checkerForHub = i["locname"] as? String{
                            if checkerForHub.contains("Hub "){
                                currNode = i["node"] as! Int
                                break
                            }
                        }
                    }
                }
                for i in dArray{
                    if i["locname"] as? String == dest && currNode != -1{
                        let desNode = Int(truncating: i["node"] as! NSNumber)
                        self.indoorKeyIgnition()
                        self.voiceSearchFlag = false
                        shortestPath = pathFinder(current: currNode, destination: desNode)
                        break
                    }
                }
            }
        }
        else if dest != ""{
            var currNode = -1
            for i in dArray{
                if i["beacon_id"] as! Int == self.CURRENT_NODE{
                    if let checkerForHub = i["locname"] as? String{
                        if checkerForHub.contains("Hub "){
                            currNode = i["node"] as! Int
                            break
                        }
                    }
                }
            }
            for i in dArray{
                if i["locname"] as? String == dest && currNode != -1{
                    let desNode = Int(truncating: i["node"] as! NSNumber)
                    self.indoorKeyIgnition()
                    self.voiceSearchFlag = false
                    shortestPath = pathFinder(current: currNode, destination: desNode)
                    break
                }
            }
        }
        else{
            self.speakThis(sentence: "Sorry, no destination was found.")
            self.voiceSearchFlag = false
            return
        }
    }
    
    func indoorKeyIgnition(){
        speechFlag = true
        recursionFlag = false
        indoorWayFindingFlag = true
        explorationFlag = false
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
    
    func speakThis(sentence : String){
        let audioSession = AVAudioSession.sharedInstance()
        do
        {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.default)
            //try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        }
        catch
        {
            print("audioSession properties weren't set because of an error.")
        }
        
        var user = 1
        let userProfile = UserDefaults.standard.value(forKey: "checkmarks") as? [String:Int]
        if userProfile == nil{
            user = 0
        }
        else if !userProfile!.isEmpty{
            user = userProfile!["User Category"]!
        }
        
        let utterance = AVSpeechUtterance(string: sentence)
        if user == 0{
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.7
        }
        else{
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.55
        }
        
        if(narator.isSpeaking && explorationFlag && voiceSearchFlag){
            narator.stopSpeaking(at: .immediate)
        }
        
        if !muteFlag{
            narator.speak(utterance)
        }
        else{
            narator.stopSpeaking(at: .immediate)
        }
    }
    
    @IBAction func switchMuteTo(_ sender: Any) {
        if(!muteFlag){
            self.naratorMute.setImage(UIImage(systemName: "volume.slash.fill"), for: .normal)
            if narator.isSpeaking{
                narator.stopSpeaking(at: .immediate)
            }
            muteFlag = true
            self.naratorMute.accessibilityLabel = "Unmute button"
        }
        else{
            self.naratorMute.setImage(UIImage(systemName: "volume.fill"), for: .normal)
            if narator.isSpeaking{
                narator.stopSpeaking(at: .immediate)
            }
            muteFlag = false
            self.naratorMute.accessibilityLabel = "Mute button"
        }
    }
    @objc func doubleTapped() {
        // do something here
        print("*********** Speak Again Command Detected ***********")
        if explorationFlag && !muteFlag{
            speechFlag = true
            recursionFlag = false
        }
        if indoorWayFindingFlag && !muteFlag{
            if !stopRepeatsFlag{
                speakThis(sentence: "Please move closer to a recognizable beacon")
            }
            else{
                for i in dArray{
                    if i["beacon_id"] as! Int == CURRENT_NODE{
                        if let checkerForHub = i["locname"] as? String{
                            if checkerForHub.contains("Hub "){
                                let n = i["node"] as! Int
                                speakThis(sentence: atBeaconInstr[n]!)
                                break
                            }
                        }
                    }
                }
            }
        }
    }
}
