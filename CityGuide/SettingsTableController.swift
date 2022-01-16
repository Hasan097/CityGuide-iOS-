//
//  SettingsTableController.swift
//  CityGuide
//
//  Created by Studentadm on 9/23/21.
//

import UIKit

class SettingsTableController: UITableViewController {
    
    public var items: [String] = ["Test Cell 1" , "Default Cell 2"]
    var checkmarks: [String : Int] = [
        "User Category" : 0,
        "Distance Unit" : 0,
        "Referece Distance Unit" : 0,
        "Orientation Preference" : 0
    ]
    var routePreviwState: Bool = false
    var monitoringState: Bool = false    
    var selectedRow : Int = 0
    
    let initialCells = [
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
    var userInputItems: [String: Float] = [
        "Step Size (ft)" : 1.25,
        "Weighted Moving Average" : 5,
        "Set Threshold" : -80,
        "Timer (Seconds)" : 5,
        "Searching Radius (Meters)" : 500,
        "GPS Accuracy" : 5000
    ]
    let itemDiscriptions = [
        "Users in each category are expected to have different information needs.",
        "At the start of the navigation, a route will be provided with a preview of the complete path from source to destination.",
        "Preferred unit of measurement. Step size will be based on this setting.",
        "This option helps you to have a better understanding about the distance between a location to another location.",
        "Set direction preference. " ,
        "Give details about surroundings while walking to destination. ",
        "Adjust the step size of the user based on step measurements. ",
        "Average must be between 3-5.",
        "Set the threshold of the RSSI for detection. Value must be a negative number with a range of (-50,-100) for best case detection.",
        "Change the time to search for and get location.",
        "Defines the convergance area to search for a destination.",
        "Define how much accuracy is prefered for outdoor navigations. "
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        
        if let value = UserDefaults.standard.value(forKey: "rPreview") as? Bool{
            routePreviwState = value
        }
        
        if let anotherVal = UserDefaults.standard.value(forKey: "monitoring") as? Bool{
            monitoringState = anotherVal
        }
        
        if let userInputs = UserDefaults.standard.value(forKey: "userInputItems") as? [String : Float]{
            userInputItems = userInputs
        }
        
        if let checks = UserDefaults.standard.value(forKey: "checkmarks") as? [String : Int]{
            checkmarks = checks
        }
        
        if checkmarks[self.title!] != nil{
            selectedRow = checkmarks[self.title!]!
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }
    
    @objc func switchChanged(_ sender : UISwitch){
        print("Table row switch changed \(sender.tag)")
        print("The switch is \(sender.isOn ? "ON" : "OFF")")
        if sender.tag == 1{
            routePreviwState = sender.isOn
        }
        else{
            monitoringState = sender.isOn
        }
        UserDefaults.standard.set(routePreviwState, forKey: "rPreview")
        UserDefaults.standard.set(monitoringState, forKey: "monitoring")
    }
    
    // Initialize and configure the cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = items[indexPath.row]
        
        if(cell.textLabel?.text == "Route Preview" || cell.textLabel?.text == "Monitoring"){
            let switchView = UISwitch(frame: .zero)
            if(cell.textLabel?.text == "Route Preview"){
                switchView.setOn(routePreviwState, animated: true)
            }
            else{
                switchView.setOn(monitoringState, animated: true)
            }
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }
        
        return cell
    }
    
    
    // Selected cell method
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let table = SettingsTableController()
        let userCategory = ["Difficulty Seeing" , "Genral User" , "Difficulty Moving"]
        let refDistUnit = ["Distance", "Number of Steps"]
        let distUnit = ["Meters" , "Feet"]
        let oriPref = ["Left, Right Method", "Clock Orientation Method"]
        
        table.title = selectedItem
        
        if (userCategory.contains(selectedItem!)    ||
            refDistUnit.contains(selectedItem!)     ||
            distUnit.contains(selectedItem!)        ||
            oriPref.contains(selectedItem!)){
            
            for cell in tableView.visibleCells{
                cell.accessoryType = .none
            }
            
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            checkmarks[self.title!] = indexPath.row
            UserDefaults.standard.set(checkmarks, forKey: "checkmarks")
        }
        
        var toString : String = ""
        if userInputItems[selectedItem!] != nil{
            toString = String(userInputItems[selectedItem!]!)
        }
    
        
        switch selectedItem {
            case "User Category":
                table.items = userCategory
                break
            case "Distance Unit":
                table.items = distUnit
                break
            case "Referece Distance Unit":
                table.items = refDistUnit
                break
            case "Orientation Preference":
                table.items = oriPref
                break
            case "Step Size (ft)":
                callAlert(selectedItem!, itemDiscriptions[6], toString)
                break
            case "Weighted Moving Average":
                callAlert(selectedItem!, itemDiscriptions[7], toString)
                break
            case "Set Threshold":
                callAlert(selectedItem!, itemDiscriptions[8], toString)
                break
            case "Timer (Seconds)":
                callAlert(selectedItem!, itemDiscriptions[9], toString)
                break
            case "Searching Radius (Meters)":
                callAlert(selectedItem!, itemDiscriptions[10], toString)
                break
            case "GPS Accuracy":
                callAlert(selectedItem!, itemDiscriptions[11], toString)
                break
            default:
                break
        }
        
        if (initialCells.contains(selectedItem!)){
            navigationController?.pushViewController(table, animated: true)
        }

    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(cell.textLabel?.text != nil){
            if(initialCells.contains(cell.textLabel?.text ?? "default value") == false){
                cell.accessoryType = indexPath.row == selectedRow ? .checkmark : .none
            }
        }
    }
    
    
    // Alert pop up for userInputItems
    func callAlert(_ title : String, _ message : String, _ defaultVal : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (UITextField) in
            UITextField.text = defaultVal
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            print("\(title): \(textField?.text ?? defaultVal)")
            if let value = textField?.text{
                self.userInputItems[title] = Float(value)
                UserDefaults.standard.set(self.userInputItems, forKey: "userInputItems")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
