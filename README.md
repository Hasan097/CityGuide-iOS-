# CityGuide-iOS-
An iOS version of the CityGuide App


## AppDelegate and SceneDelegate
Default values of the application. Nothing was changed here. 


## ViewController
The main page of the application.

### viewDidLoad
- Initialize all the necessary variables when application starts and view is loaded

### motionEnded
- If we detect a shake, trigger the doubletap method which basically speaks the previous command.

### viewWillAppear
- Hide the stop button at start up as our default mode is exploration

### locationManager
- Used to determine the angle the user is facing
- Value will be used to determine compass direction of the user

### didFindBeacon and didLoseBeacon
- Used to implement any methods when finding a new beacon or losing beacon
- Currently is not used as there is no requirement

### didUpdateBeacon
- Implement methods when some values of the beacon change, for example RSSI value

### callOperations
- Used to set list of RSSI values of each recorded beacon
- Adds RSSI values based on beaconID if its greater than the threshold
- Adds a dummy -100 RSSI value if the beaconID in the record does not receive an updated RSSI value
- Calls the checkWindow method to determine which beacons can stay in the record

### checkWindow
- Checks which beacon can stay in the record
- record is passed to a screening window function to determine closed beacon

### screeningWindow
- Checks which beacon is the closest using the weight averaging equation
- Once closest beacon is determined it checks if the groupID and floor number match
- Calls methods to set groupID and floor plan if nil

### updateBeaconReading
- Updates various beacon values of the application
- Sets values for the floor plan, groupID, and adds beacons from the beacon file into a dictionary
- Calls the exploration and navigation methods when flags are met 
- Calls the rerouting function when flag is met
- Calls indoorKeyIgnition method to set the appropriate flags for navigation mode
- Sets values at beaconID from the instruction generator

### presentAlert
- Function to help with alerts

### didTapStop
- Stops navigation mode and switches to exploration when the stop icon is pressed 

### didTapSettingbtn
- Triggers the view for the settings screen when setting button is pressed

### searchTapped
- Triggers the view for search screen when search icon is tapped

### explorationMode
- Monitors which beacon is close to user for it to speak its POIs

### indoorWayFinding
- Monitors closest beacon and gives direction to the user
- Applies haptic feedback vibrations

### checkForReRoutes
- Check for any re-rerouting if necessary

### singleFire
- Function to transcribe a user's speech/responses
- Calls methods based on user's responses
- Used for speech based instructions

### checkForDestination
- Used to check if the destination requested is within the pool of available destinations
- Used for speech based instructions

### indoorKeyIgnition
- Set the appropriate flags to initiate navigation mode

### hapticVibration
- Function to trigger haptic vibration 

### speakThis
- Text To Speech method to say instructions/responses to the user

### switchMuteTo
- Switch the state of mute to on or off when user taps the volume button

### doubleTapped
- Speak the previous command when user double taps the screen


## Instruction Generator
Generate instructions based on user's orientation

### getDirection
- Get which direction the user is facing using the user's angle

### turnTowards
- Instruction to turn towards a certain direction

### distCalculator
- Use the meters unit or calculate and use the feet unit for instructions

### cardinalDirection
- Directions in relation to where the user is facing
- Used for POI information

### generatePOIDirections
- Set the directions of the relevant POIs using *cardinalDirection* method

### getOppositeDirection
- Get the opposite direction

### instructions
- Utilize the functions in this file and generate instructions
- Final result is a dictionary with key as beaconID and instructions when close to it as value


## SettingsTableController
- A table view controller for the settings page
- Display all relevant settings and records users inputs
- Mostly UI and memory based code. Nothing too complicated 
- The **UserDefaults** method is used to store user's settings in memory


## Routing
Generate the matrix and use the pathfinding algorithm to get shortest path

### groupChangeNoticed
- Clear out values inside of the matrix dictionary if new group is detected
- GroupID is based on what building we are in hence matrix changes based on that

### makeMatrix
- Make the matrix dictionary based on the values received
 
### checkForFloorChange
- Used to generate paths between floors 

### pathFinder
- Using Dijkstra's algorithm to generate the shortest path to the destination
- Uses the matrix dictionary to compute the path
 
### extractPath
- Extract the path formed from the pathFinder algorithm in array format


## DataBase
Functions to send and retrieve values from the server

### postToDB
- The main function of this file
- Determines which request to send to the server
- There are 3 versions of requests, *beacons, getBeacons, and getFloor*
- *beacons* is used to get values of a specific beacon
- *getBeacons* is used to get the beacon file related to the specific groupID
- *getFloor* is used to get the floor plan of the current beacon

### **dArray** 
- The dictionary that holds the values of a cluster of beacons
- This variable is important for many of the code's operations


## SearchResultsVC
- The view controller of the search results. Shows up when the user taps the search icon.  
- Mostly UI stuff and filtering list based on user's typed information


## SpeechRecognizer
- Transcription of the user's voice commands happens here
- Added this code via open source github 


## LevenshteinDistance
- Code used to find the closest match to a requested destination
- If the user said "axis lab" this function scores it against "access lab" 
- The score is returned and handled at the **checkForDestination** function in the main view


## BeaconScanner
- File used to help detect EddyStone Beacons
- Implements methods for detection
- Found via open source github


## FloorPlanManipulation
Code File to manipulate floor plan on the phone screen

### extractCoordinates
- Extracts coordinate values from the *others* column of the database
- Returns the coordinates as an array

### drawOnImage
- Draws the red dot on the floor plan indicating users location


