//
//  Eddystone.swift
//  CityGuide
//
//  Created by Studentadm on 3/18/22.
//

import Foundation
import CoreBluetooth

///
/// BeaconID
///
/// Uniquely identifies an Eddystone compliant beacon.
///
class BeaconID : NSObject {
  enum BeaconType {
    case Eddystone              // 10 bytes namespace + 6 bytes instance = 16 byte ID
  }

  let beaconType: BeaconType

  ///
  /// The raw beaconID data. This is typically printed out in hex format.
  ///
  let beaconID: [UInt8]
    var bID : Int = -1
    
  fileprivate init(beaconType: BeaconType!, beaconID: [UInt8]) {
    self.beaconID = beaconID
    self.beaconType = beaconType
  }

  override var description: String {
    if self.beaconType == BeaconType.Eddystone {
      var hexid = hexBeaconID(beaconID: self.beaconID)
        if hexid.contains("ca1d78ea1f60b67a80ab"){
            hexid = String(hexid.suffix(5))
            bID = Int(hexid)!
        }
        return "BeaconID beacon: \(String(describing: Int(hexid)!))"
    } else {
      return "BeaconID with invalid type (\(beaconType))"
    }
  }

  private func hexBeaconID(beaconID: [UInt8]) -> String {
    var retval = ""
    for byte in beaconID {
      var s = String(byte, radix:16, uppercase: false)
      if s.count == 1 {
        s = "0" + s
      }
      retval += s
    }
    return retval
  }

}

func ==(lhs: BeaconID, rhs: BeaconID) -> Bool {
  if lhs == rhs {
    return true;
  } else if lhs.beaconType == rhs.beaconType
    && rhs.beaconID == rhs.beaconID {
      return true;
  }

  return false;
}

///
/// BeaconInfo
///
/// Contains information fully describing a beacon, including its beaconID, transmission power,
/// RSSI, and possibly telemetry information.
///
class BeaconInfo : NSObject {

  static let EddystoneUIDFrameTypeID: UInt8 = 0x00
    
  enum EddystoneFrameType {
    case UIDFrameType
    case UnknownFrameType

    var description: String {
      switch self {
      case .UIDFrameType:
        return "UID Frame"
      case .UnknownFrameType:
          return "Unknown Frame"
      }
    }
  }

  let beaconID: BeaconID
  let txPower: Int
  let RSSI: Int
  let telemetry: NSData?

  private init(beaconID: BeaconID, txPower: Int, RSSI: Int, telemetry: NSData?) {
    self.beaconID = beaconID
    self.txPower = txPower
    self.RSSI = RSSI
    self.telemetry = telemetry
  }

  class func frameTypeForFrame(advertisementFrameList: [NSObject : AnyObject]) -> EddystoneFrameType {
      let uuid = CBUUID(string: "FEAA")
      if let frameData = advertisementFrameList[uuid] as? NSData {
        if frameData.length > 1 {
          let count = frameData.length
          var frameBytes = [UInt8](repeating: 0, count: count)
          frameData.getBytes(&frameBytes, length: count)

          if frameBytes[0] == EddystoneUIDFrameTypeID {
            return EddystoneFrameType.UIDFrameType
          }
        }
    }

     return EddystoneFrameType.UnknownFrameType
  }

  class func telemetryDataForFrame(advertisementFrameList: [NSObject : AnyObject]!) -> NSData? {
    return advertisementFrameList[CBUUID(string: "FEAA")] as? NSData
  }

  ///
  /// Unfortunately, this can't be a failable convenience initialiser just yet because of a "bug"
  /// in the Swift compiler — it can't tear-down partially initialised objects, so we'll have to
  /// wait until this gets fixed. For now, class method will do.
  ///
  class func beaconInfoForUIDFrameData(frameData: NSData, telemetry: NSData?, RSSI: Int) -> BeaconInfo? {
      if frameData.length > 1 {
        let count = frameData.length
        var frameBytes = [UInt8](repeating: 0, count: count)
        frameData.getBytes(&frameBytes, length: count)

        if frameBytes[0] != EddystoneUIDFrameTypeID {
          NSLog("Unexpected non UID Frame passed to BeaconInfoForUIDFrameData.")
          return nil
        } else if frameBytes.count < 18 {
          NSLog("Frame Data for UID Frame unexpectedly truncated in BeaconInfoForUIDFrameData.")
        }

        let txPower = Int(Int8(bitPattern:frameBytes[1]))
        let beaconID: [UInt8] = Array(frameBytes[2..<18])
        let bid = BeaconID(beaconType: BeaconID.BeaconType.Eddystone, beaconID: beaconID)
        return BeaconInfo(beaconID: bid, txPower: txPower, RSSI: RSSI, telemetry: telemetry)
      }

      return nil
  }

  override var description: String {
    switch self.beaconID.beaconType {
    case .Eddystone:
        
        let userRssi : Float
        if let userInputs = UserDefaults.standard.value(forKey: "userInputItems") as? [String : Float]{
            userRssi = userInputs["Set Threshold"] ?? (-80.00)
            if self.RSSI >= Int(userRssi){
                return "Eddystone \(self.beaconID), txPower: \(self.txPower), RSSI: \(self.RSSI)"
            }
        }
        return ""
    }
  }
}
