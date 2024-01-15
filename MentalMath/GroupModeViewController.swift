//
//  GroupModeViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 1/8/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit
import CoreBluetooth

var globalManagerVC: GroupModeViewController?

class GroupModeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var isManagerPlaying = false // is manager playing group mode
    
    var tmpPeripheralNames: [UUID : String] = [:]
    var tablePeripheralIDs: [UUID] = [] // list of peripherals in table
    var peripheralNames: [String] = [] // names right now
    
    var peripherals: [CBPeripheral] = [] // list of all found peripherals
    
    var players: [Player] = []
    var sortedPlayers: [Player] = []
    
    var rounds = [[String]]()
    
    // bluetooth
    var centralManager: CBCentralManager!
    
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField?.addDoneToolbar(onDone: (target: self, action: #selector(doneButtonTappedForNameTextField))) }
    }
    @IBOutlet weak var visiblePlayersLabel: UILabel!
    @IBOutlet weak var playersTableView: UITableView!
    
    @IBOutlet weak var leaderboardView: UIView!
    @IBOutlet weak var leaderboardTableView: UITableView!
    @IBOutlet weak var leaderboardQuitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        globalManagerVC = self
        mode = .solo
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        tmpPeripheralNames.removeAll()
        tablePeripheralIDs.removeAll()
        peripheralNames.removeAll()
        peripherals.removeAll()
        playersTableView.reloadData()
        
        isManagerPlaying = false
        leaderboardView.isHidden = true
        
        if self.view.traitCollection.horizontalSizeClass == .regular && self.view.traitCollection.verticalSizeClass == .regular {
            
            leaderboardTableView.rowHeight = 90
        } else {
            leaderboardTableView.rowHeight = 60
        }
        
        groupModeTime = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        nameTextField.delegate = self
    }
    
    // table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView.tag == 0) {
            return peripheralNames.count
        } else {
            return sortedPlayers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(tableView.tag == 0) {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "playerCell")
            let device = peripheralNames[indexPath.row]
            cell.textLabel?.text = device
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont(name: "Thonburi", size: 30)
            cell.textLabel?.textColor = UIColor.white
            
            cell.backgroundColor = UIColor.aqua
            
            return cell
        } else { // leaderboard
            let cell = leaderboardTableView.dequeueReusableCell(withIdentifier: "leaderboardCell", for: indexPath) as! LeaderboardTableViewCell
            let player = sortedPlayers[indexPath.row]
            cell.placeLabel.text = "\(indexPath.row + 1)."
            cell.nameLabel.text = "\(player.name)"
            cell.scoreLabel.text = "\(player.score)"
            
            let timeMins = Int(player.time) / 60
            let timeSecs = player.time - Double(60 * timeMins)
            
            if(timeSecs < 9.95) {
                cell.timeLabel.text = "\(timeMins):0\(round(number: timeSecs, places: 1))"
            } else {
                cell.timeLabel.text = "\(timeMins):\(round(number: timeSecs, places: 1))"
            }
            
            var color: UIColor = UIColor.white
            
            if(!player.alive) {
                color = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
            }
            
            cell.placeLabel.textColor = color
            cell.nameLabel.textColor = color
            cell.scoreLabel.textColor = color
            cell.timeLabel.textColor = color
            
            cell.backgroundColor = UIColor.aqua
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(tableView.tag == 0) {
            if(editingStyle == .delete) {
                tablePeripheralIDs.remove(at: indexPath.row)
                peripheralNames.remove(at: indexPath.row)
                playersTableView.deleteRows(at: [indexPath], with: .automatic)
                
                visiblePlayersLabel.text = "Visible Players (\(peripheralNames.count))"
                let indexPath = IndexPath(row: peripheralNames.count - 1, section: 0)
                playersTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    // text field
    @objc func doneButtonTappedForNameTextField() {
        if nameTextField.text != "" {
            // unique name
            if !peripheralNames.contains(nameTextField.text!) {
                tmpPeripheralNames[UIDevice.current.identifierForVendor!] = nameTextField.text!
                
                    tablePeripheralIDs.append(UIDevice.current.identifierForVendor!)
                    peripheralNames.append(nameTextField.text!)
                    visiblePlayersLabel.text = "Visible Players (\(self.peripheralNames.count))"
                    playersTableView.reloadData()
                    let indexPath = IndexPath(row: peripheralNames.count - 1, section: 0)
                    playersTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                
                nameTextField.isEnabled = false
                nameTextField.textColor = UIColor.white
                nameTextField.borderStyle = .none
                view.endEditing(true)
                
                isManagerPlaying = true
                
            } else { // not unique name
                createAlert(title: "Name already taken", message: "Please enter a new name")
                nameTextField.isEnabled = true
                nameTextField.text = ""
                nameTextField.becomeFirstResponder()
            }
        }
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // start game
    @IBAction func startGame(_ sender: UIButton) {
        
        rounds.removeAll()
        
        difficulty = sender.tag
        resetGame()
        
        rounds.append(generateNewRound(numbers: numbers, maxAnswer: maxAnswer, difficulty: difficulty))
        
        groupModeRounds = rounds
        
        for peripheral in centralManager.retrieveConnectedPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID]) {
            
            if peripheral.services == nil {
                continue
            }
            
            for service in peripheral.services! {
                
                if service.characteristics == nil {
                    continue
                }
                
                for characteristic in service.characteristics! {
                    
                    switch characteristic.uuid {
                    case ROUND_UUID:
                        
                        var round = 1 // starting round 1
                        peripheral.writeValue(Data(bytes: &round, count: MemoryLayout.size(ofValue: round)), for: characteristic, type: .withResponse)
                        print("setting round")
                        
                    case DIFFICULTY_UUID:
                        var diff = sender.tag
                        peripheral.writeValue(Data(bytes: &diff, count: MemoryLayout.size(ofValue: diff)), for: characteristic, type: .withResponse)
                        print("setting \(diff) to \(characteristic.uuid.uuidString)")
                    case ROUND_DATA_UUID:
                       print("starting game")
                       
                       /*
                       _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        
                            let roundNum = STARTING_NUMBERS + (self.rounds.count * NUMBER_INCREMENT)
                            let maxNum = STARTING_MAX_ANSWER + (self.rounds.count * MAX_INCREMENT)
                        
                            self.rounds.append(self.generateNewRound(numbers: roundNum, maxAnswer: maxNum, difficulty: difficulty))
                            print(self.rounds)
                        // peripheral.writeValue(NSKeyedArchiver.archivedData(withRootObject: self.rounds), for: characteristic, type: .withResponse)
                        */
                    let roundsString = twoDArrayToString(array: self.rounds)
                    print(roundsString)
                    
                    peripheral.writeValue(roundsString.data(using: .utf8)!, for: characteristic, type: .withResponse)
                        // }
                    default:
                        print("unhandled characteristic")
                    }
                }
            }
        }
        
        centralManager.stopScan() // stop scanning
        
        leaderboardView.isHidden = false
        
        if isManagerPlaying {
            mode = .group_manager
            performSegue(withIdentifier: "managerPlaySegue", sender: nil)
        }
    }
    
    // quit
    @IBAction func leaderboardQuit(_ sender: Any) {
        
        // create alert
        
        let alert = UIAlertController(title: "Are you sure?", message: "This will disconnect all players", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            
            for peripheral in self.centralManager.retrieveConnectedPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID]) {
                
                if peripheral.services == nil {
                    continue
                }
                
                for service in peripheral.services! {
                    
                    if service.characteristics == nil {
                        continue
                    }
                    
                    for characteristic in service.characteristics! {
                        if characteristic.uuid == QUIT_UUID {
                            peripheral.writeValue("1".data(using: .utf8)!, for: characteristic, type: .withResponse)
                        }
                    }
                }
            }
            self.performSegue(withIdentifier: "leaderboardQuitSegue", sender: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
            
            print("quit canceled")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension GroupModeViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            print("central.state is .poweredOn")
            
            // clear slate before scanning
            for peripheral in centralManager.retrieveConnectedPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID]) {
                centralManager.cancelPeripheralConnection(peripheral)
            }
            
            centralManager.scanForPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID])
        } else {
            createAlert(title: "Bluetooth not powered on", message: "Make sure Bluetooth is turned on and your device can allow new connections")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripherals)
        
        if !peripherals.contains(peripheral) {
            peripheral.delegate = self
            peripherals.append(peripheral)
            
            print("appending")
            
            if let data = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                
                let advertisementName = data.components(separatedBy: "|")[0]
                
                tmpPeripheralNames[peripheral.identifier] = advertisementName
            }
            
            centralManager.connect(peripheral)
        } else {
            print("already found")
            
            if let data = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                
                let advertisementName = data.components(separatedBy: "|")[0]
                
                tmpPeripheralNames[peripheral.identifier] = advertisementName
                
                if peripheral.services != nil {
                    
                    for service in peripheral.services! {
                        
                        if service.characteristics == nil {
                            continue
                        }
                        
                        for characteristic in service.characteristics! {
                            if characteristic.uuid == UNIQUE_NAME_UUID {
                                let uniqueName = isUniqueName(name: advertisementName, peripheral: peripheral, dict: tmpPeripheralNames)
                                
                                if !uniqueName { // not unique name
                                    peripheral.writeValue("0".data(using: .utf8)!, for: characteristic, type: .withResponse)
                                    print("sent alert")
                                } else {
                                    peripheral.writeValue("1".data(using: .utf8)!, for: characteristic, type: .withResponse)
                                    print("sent alert for one already found")
                                    
                                    addPeripheralNameToTable(peripheral)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func isUniqueName(name: String, peripheral: CBPeripheral, dict: [UUID : String]) -> Bool {
        
        for (uuid, n) in dict {
            if uuid != peripheral.identifier && n == name {
                return false
            }
        }
        return true
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        
        peripheral.discoverServices(nil)
    }
    
    // text field
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButtonTappedForNameTextField()
        return true
    }
}

extension GroupModeViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("discovered services")
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == UNIQUE_NAME_UUID {
                if let name = self.tmpPeripheralNames[peripheral.identifier] {
                    
                    let uniqueName = isUniqueName(name: name, peripheral: peripheral, dict: tmpPeripheralNames)
                    
                    if !uniqueName { // not unique name
                        peripheral.writeValue("0".data(using: .utf8)!, for: characteristic, type: .withResponse)
                        print("sent alert")
                    } else {
                        peripheral.writeValue("1".data(using: .utf8)!, for: characteristic, type: .withResponse)
                    }
                }
            }
        }
        
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
            
            if let name = self.tmpPeripheralNames[peripheral.identifier] {
                
                let uniqueName = !self.peripheralNames.contains(name)
            
                if uniqueName {
                // add name to table
                    self.addPeripheralNameToTable(peripheral)
                }
            }
        }
    }
    
    func addPeripheralNameToTable(_ peripheral: CBPeripheral) {
        if let name = self.tmpPeripheralNames[peripheral.identifier] {
            var newPeripheral = true
            
            for i in 0..<self.tablePeripheralIDs.count {
                if peripheral.identifier == self.tablePeripheralIDs[i] {
                    self.peripheralNames[i] = name
                    self.playersTableView.reloadData()
                    newPeripheral = false
                }
            }
            
            if newPeripheral {
                self.tablePeripheralIDs.append(peripheral.identifier)
                self.peripheralNames.append(name)
                self.visiblePlayersLabel.text = "Visible Players (\(self.peripheralNames.count))"
                self.playersTableView.reloadData()
                let indexPath = IndexPath(row: self.peripheralNames.count - 1, section: 0)
                self.playersTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        print("updating value for \(characteristic.uuid.uuidString)")
        
        switch characteristic.uuid {
        case NAME_UUID: // update all
            
            print("updating name")
            
            if characteristic.value == nil {
                fallthrough
            }
            
            let tmp = String(decoding: characteristic.value!, as: UTF8.self)
            
            let playerInfo = tmp.components(separatedBy: "|")
            let playerName = playerInfo[0]
            let playerScore = Int(playerInfo[1])!
            let playerTime = Double(playerInfo[2])!
            let playerAlive = playerInfo[3] == "1"
            
            if(!leaderboardView.isHidden) {
                var newPlayer = true
                
                for player in players {
                    if(playerName == player.name) {
                        newPlayer = false
                        player.score = playerScore
                        player.alive = playerAlive
                        player.time = playerTime
                    }
                }
                
                if(newPlayer && playerAlive) {
                    players.append(Player(n: playerName, s: playerScore, t: playerTime, a: playerAlive))
                }
            }
            
            let round = playerScore + 1
            
            if(round > rounds.count) {
            
                let roundNum = STARTING_NUMBERS + ((round - 1) * NUMBER_INCREMENT)
                let maxNum = STARTING_MAX_ANSWER + ((round - 1) * MAX_INCREMENT)
            
                rounds.append(generateNewRound(numbers: roundNum, maxAnswer: maxNum, difficulty: difficulty))
                print(rounds)
            }
            
            // sort players
            
            sortedPlayers = players.sorted {
                if $0.score != $1.score { // first, compare by last names
                    return $0.score > $1.score
                } else { // All other fields are tied, break ties by last name
                    return $0.time < $1.time
                }
            }
            
            leaderboardTableView.reloadData()
            
            if mode == .group_manager {
                globalAnswerVC?.updatePlace(place: getPlace(name: groupModeName))
                groupModeRounds = rounds
            }
            
            for sendPeripheral in centralManager.retrieveConnectedPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID]) {
                
                var pName = ""
                
                if sendPeripheral.services == nil {
                    continue
                }
                
                // get name
                for service in sendPeripheral.services! {
                    
                    if service.characteristics == nil {
                        continue
                    }
                    
                    for sendCharacteristic in service.characteristics! {
                        
                        switch sendCharacteristic.uuid {
                            
                        case NAME_UUID:
                            pName = String(decoding: sendCharacteristic.value ?? "".data(using: .utf8)!, as: UTF8.self).components(separatedBy: "|")[0]
                        default:
                            print("getting name")
                        }
                    }
                }
                
                for service in sendPeripheral.services! {
                    
                    if service.characteristics == nil {
                        continue
                    }
                    
                    for sendCharacteristic in service.characteristics! {
                        
                        switch sendCharacteristic.uuid {
                            
                        case ROUND_DATA_UUID:
                            
                            let roundsString = twoDArrayToString(array: rounds)
                            sendPeripheral.writeValue(roundsString.data(using: .utf8)!, for: sendCharacteristic, type: .withResponse)
                            
                        case PLACE_UUID:
                            var place = getPlace(name: pName)
                            sendPeripheral.writeValue(Data(bytes: &place, count: MemoryLayout.size(ofValue: place)), for: sendCharacteristic, type: .withResponse)
                        default:
                            print("sending")
                        }
                    }
                }
            }
            
        case STUDENT_QUIT_UUID:
            
            // remove from peripherals
            for i in (0..<peripherals.count).reversed() {
                if peripherals[i].identifier == peripheral.identifier {
                    centralManager.cancelPeripheralConnection(peripherals[i])
                    peripherals.remove(at: i)
                }
            }
            
        default:
            print("Fellthrough or Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    // function called when manager is playing
    
    func updateManagerScore(name: String, score: Int, alive: Bool) {
        
        var newPlayer = true
        
        for player in players {
            if name == player.name {
                newPlayer = false
                player.score = score
                player.alive = alive
                player.time = groupModeTime
            }
        }
        
        if newPlayer && alive {
            players.append(Player(n: name, s: score, t: groupModeTime, a: alive))
        }
        
        let round = score + 1
        
        if(round > rounds.count) {
            
            let roundNum = STARTING_NUMBERS + ((round - 1) * NUMBER_INCREMENT)
            let maxNum = STARTING_MAX_ANSWER + ((round - 1) * MAX_INCREMENT)
            
            rounds.append(generateNewRound(numbers: roundNum, maxAnswer: maxNum, difficulty: difficulty))
            print(rounds)
            
            groupModeRounds = rounds
        }
        
        // sort players
        
        sortedPlayers = players.sorted {
            if $0.score != $1.score { // first, compare by last names
                return $0.score > $1.score
            } else { // All other fields are tied, break ties by last name
                return $0.time < $1.time
            }
        }
        
        // update place
        globalAnswerVC?.updatePlace(place: getPlace(name: groupModeName))
        
        leaderboardTableView.reloadData()
        
        for sendPeripheral in centralManager.retrieveConnectedPeripherals(withServices: [READ_SERVICE_UUID, WRITE_SERVICE_UUID]) {
            
            var pName = ""
            
            if sendPeripheral.services == nil {
                continue
            }
            
            // get name
            for service in sendPeripheral.services! {
                
                if service.characteristics == nil {
                    continue
                }
                
                for sendCharacteristic in service.characteristics! {
                    
                    switch sendCharacteristic.uuid {
                        
                    case NAME_UUID:
                        pName = String(decoding: sendCharacteristic.value ?? "".data(using: .utf8)!, as: UTF8.self).components(separatedBy: "|")[0]
                    default:
                        print("getting name")
                    }
                }
            }
            
            for service in sendPeripheral.services! {
                
                if service.characteristics == nil {
                    continue
                }
                
                for sendCharacteristic in service.characteristics! {
                    
                    switch sendCharacteristic.uuid {
                        
                    case ROUND_DATA_UUID:
                        
                        let roundsString = twoDArrayToString(array: rounds)
                        sendPeripheral.writeValue(roundsString.data(using: .utf8)!, for: sendCharacteristic, type: .withResponse)
                        
                    case PLACE_UUID:
                        var place = getPlace(name: pName)
                        sendPeripheral.writeValue(Data(bytes: &place, count: MemoryLayout.size(ofValue: place)), for: sendCharacteristic, type: .withResponse)
                    default:
                        print("sending")
                    }
                }
            }
        }
    }
    
    // returns 0 if name not found
    func getPlace(name: String) -> Int {
        for i in 0..<sortedPlayers.count {
            if sortedPlayers[i].name == name {
                return i + 1
            }
        }
        return 0
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("writing to \(characteristic.uuid.uuidString)")
    }
    
    // generate new round
    
    func generateNewRound(numbers: Int, maxAnswer: Int, difficulty: Int) -> [String] {
        
        var usableNumbers: [[Int]] = [] // holder for each operation, what numbers are usable
        
        var retArray: [String] = []
        
        // operation constants
        let ADD: Int = 0
        let SUBTRACT: Int = 1
        let MULTIPLY: Int = 2
        let DIVIDE: Int = 3
        
        var answer: Int = 0
        
        var operation: Int = ADD
        
        let highestNumber = HIGHEST_NUMBERS[difficulty]
        
        for gameRunCount in 0..<(numbers * 2) {
            if(gameRunCount == 0) {
                answer = Int.random(in: 2...highestNumber)
                retArray.append(String(answer))
            } else if(gameRunCount >= numbers * 2 - 1) {
                retArray.append("=")
                retArray.append(String(answer))
            } else if(gameRunCount % 2 == 1) { // operations
                
                steps += "\(answer)"
                
                // get usable numbers for each operation
                usableNumbers = getUsableNumbers(answer: answer, maxAnswer: maxAnswer, highestNumber: highestNumber)
                
                // decide which operation to use
                var usableOperations = [ADD, SUBTRACT, MULTIPLY, DIVIDE]
                
                // remove operations that can't be done
                for i in (0..<usableOperations.count).reversed() {
                    if(usableNumbers[i].count == 0) {
                        usableOperations.remove(at: i)
                    }
                }
                
                let opSum = opProbs[ADD] + opProbs[SUBTRACT] + opProbs[MULTIPLY] + opProbs[DIVIDE]
                var opTmp = 0
                
                repeat {
                    opTmp = Int.random(in: 0..<opSum)
                    
                    if(opTmp < opProbs[ADD]) {
                        operation = ADD
                    } else if(opTmp < opProbs[ADD] + opProbs[SUBTRACT]) {
                        operation = SUBTRACT
                    } else if(opTmp < opProbs[ADD] + opProbs[SUBTRACT] + opProbs[MULTIPLY]) {
                        operation = MULTIPLY
                    } else {
                        operation = DIVIDE
                    }
                } while(!usableOperations.contains(operation))
                
                switch operation {
                    
                case ADD:
                    retArray.append("+")
                    steps += " +"
                break
                    
                case SUBTRACT:
                    retArray.append("-")
                    steps += " -"
                break
                    
                case MULTIPLY:
                    retArray.append("×")
                    steps += " ×"
                break
                    
                case DIVIDE:
                    retArray.append("÷")
                    steps += " ÷"
                break
                    
                default:
                    retArray.append("+")
                    steps += " +"
                break
                    
                }
                
            } else { // numbers
                
                // get number
                let newNumberIndex = Int.random(in: 0..<usableNumbers[operation].count)
                let newNumber = usableNumbers[operation][newNumberIndex]
                
                switch operation {
                    
                case ADD:
                    answer += newNumber
                break
                    
                case SUBTRACT:
                    answer -= newNumber
                break
                    
                case MULTIPLY:
                    answer *= newNumber
                break
                    
                case DIVIDE:
                    answer /= newNumber
                break
                    
                default:
                    answer += newNumber
                break
                    
                }
                
                retArray.append(String(newNumber))
                print("\(operation) \(newNumber) = \(answer)")
                
                steps += " \(newNumber) = \(answer)\n\n"
            }
        }
        
        
        
        print(retArray)
        return retArray
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("did modify services")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("writing \(descriptor.characteristic?.uuid.uuidString)")
    }
}

class Player {
    var name: String
    var score: Int
    var time: Double
    var alive: Bool
    
    init(n: String, s: Int, t: Double, a: Bool) {
        name = n
        score = s
        time = t
        alive = a
    }
}

func round(number: Double, places: Int) -> Double {
    let multiplier: Double = Double(truncating: pow(10, places) as NSNumber)
    
    return Double(round(number * multiplier) / multiplier)
}

// generates string; arrays separated by semicolons, items separated by commas
func twoDArrayToString(array: [[String]]) -> String {
    var ret = ""
    for i in 0..<array.count {
        for j in 0..<array[i].count {
            ret += array[i][j]
            if(j < array[i].count - 1) {
                ret += ","
            }
        }
        if(i < array.count - 1) {
            ret += ";"
        }
    }
    
    return ret
}
