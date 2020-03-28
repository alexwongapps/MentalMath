//
//  GroupModeStudentViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 1/8/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit
import CoreBluetooth

let READ_SERVICE_UUID = CBUUID(string: "B8A573B4-DB3B-403C-BC75-90407C23EA8A")
let NAME_UUID = CBUUID(string: "1111") // name|score|time
let STUDENT_QUIT_UUID = CBUUID(string: "2222")
let WRITE_SERVICE_UUID = CBUUID(string: "49EDA010-D027-4882-9E44-6E7174CAA2B1")
let ROUND_UUID = CBUUID(string: "4444") // round number
let PLACE_UUID = CBUUID(string: "5555")
let ROUND_DATA_UUID = CBUUID(string: "6666") // round data
let DIFFICULTY_UUID = CBUUID(string: "7777")
let UNIQUE_NAME_UUID = CBUUID(string: "8888") // 0 is not unique name, 1 is unique name
let QUIT_UUID = CBUUID(string: "9999") // 0 is not unique name, 1 is unique name

var groupModeName: String = ""
var groupModeGameStarted: Bool = false
var groupModeTime: Double = 0.0

var readCharacteristics: [CBMutableCharacteristic] = []
var writeCharacteristics: [CBMutableCharacteristic] = []

var globalStudentVC: GroupModeStudentViewController?

class GroupModeStudentViewController: UIViewController, UITextFieldDelegate {

    var peripheralManager = CBPeripheralManager()
    var timer = Timer()
    var place = 0
    
    var didManagerQuit: Bool = false
    var lastName = "" // don't enter the same name twice in a row...

    @IBOutlet weak var enterNameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField?.addDoneToolbar(onDone: (target: self, action: #selector(doneButtonTappedForNameTextField))) }
    }
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var pairingMessageLabel: UILabel!
    @IBOutlet weak var quitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        globalStudentVC = self
        
        score = 0 // initialize score
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        enterNameLabel.isHidden = false
        nameTextField.isEnabled = true
        nameTextField.becomeFirstResponder()
        nameTextField.text = ""
        
        waitingLabel.isHidden = true
        pairingMessageLabel.isHidden = true
        
        didManagerQuit = false
        lastName = ""
        
        groupModeTime = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        nameTextField.delegate = self
    }
    
    func updateAdvertisingData(name: String) {
        
        // todo: can't send same name twice in a row, even if it was delete in the teacher
        if (peripheralManager.isAdvertising) {
            peripheralManager.stopAdvertising()
        }
        
        let advertisementData = "\(name)|\(Date.timeIntervalSinceReferenceDate)"
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[READ_SERVICE_UUID], CBAdvertisementDataLocalNameKey: advertisementData])
        
        print("sending")
    }
    
    // called during gameplay
    
    func sendScore(score: Int, alive: Bool) {
        let scoreStr = String(score)
        let timeStr = String(format: "%f", groupModeTime)
        let aliveStr = alive ? "1" : "0"
        
        let sendStr = "\(groupModeName)|\(scoreStr)|\(timeStr)|\(aliveStr)"
        
        peripheralManager.updateValue(sendStr.data(using: .utf8)!, for: readCharacteristics[0], onSubscribedCentrals: nil)
        print("sent score")
    }
    
    func getPlace() -> Int {
        return place
    }
    
    // text field
    
    @objc func doneButtonTappedForNameTextField() {
        if nameTextField.text != lastName {
            if nameTextField.text != "" { // make sure there is an answer entered in
                
                groupModeName = nameTextField.text!
                updateAdvertisingData(name: nameTextField.text!)
                
                waitingLabel.isHidden = false
                pairingMessageLabel.isHidden = false
                quitButton.isHidden = true
                
                var timerCount = 0
                
                timer.invalidate()
                
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    
                    switch timerCount % 4 {
                    case 0:
                        self.waitingLabel.text = "Looking for manager."
                    case 1:
                        self.waitingLabel.text = "Looking for manager.."
                    case 2:
                        self.waitingLabel.text = "Looking for manager..."
                    case 3:
                        self.waitingLabel.text = "Looking for manager"
                    default:
                        self.waitingLabel.text = "Looking for manager"
                    }
                    
                    self.quitButton.isHidden = false
                    
                    
                    timerCount += 1
                }
                
                view.endEditing(true)
                nameTextField.isEnabled = false
            }
        } else {
            createAlert(title: "Please enter a new name", message: "")
            nameTextField.text = ""
        }
    }
    
    // quit
    @IBAction func quitGame(_ sender: Any) {
        peripheralManager.stopAdvertising()
        peripheralManager.updateValue("1".data(using: .utf8)!, for: readCharacteristics[1], onSubscribedCentrals: nil)
        timer.invalidate()
        performSegue(withIdentifier: "studentQuitSegue", sender: nil)
    }
    
    // text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButtonTappedForNameTextField()
        return true
    }
}

extension GroupModeStudentViewController : CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        print("did update state")
        
        if (peripheral.state == .poweredOn){
            
            print("peripheral on")
            
            let readService = CBMutableService(type: READ_SERVICE_UUID, primary: true)
            let nameCharacteristic = CBMutableCharacteristic(type: NAME_UUID, properties: .notify, value: nil, permissions: .readable)
            let studentQuitCharacteristic = CBMutableCharacteristic(type: STUDENT_QUIT_UUID, properties: .notify, value: nil, permissions: .readable)
            
            readCharacteristics = [nameCharacteristic, studentQuitCharacteristic]
            readService.characteristics = readCharacteristics
            
            let writeService = CBMutableService(type: WRITE_SERVICE_UUID, primary: true)
            let roundCharacteristic = CBMutableCharacteristic(type: ROUND_UUID, properties: .write, value: nil, permissions: .writeable)
            let placeCharacteristic = CBMutableCharacteristic(type: PLACE_UUID, properties: .write, value: nil, permissions: .writeable)
            let roundDataCharacteristic = CBMutableCharacteristic(type: ROUND_DATA_UUID, properties: .write, value: nil, permissions: .writeable)
            let difficultyCharacteristic = CBMutableCharacteristic(type: DIFFICULTY_UUID, properties: .write, value: nil, permissions: .writeable)
            let uniqueNameCharacteristic = CBMutableCharacteristic(type: UNIQUE_NAME_UUID, properties: .write, value: nil, permissions: .writeable)
            let quitCharacteristic = CBMutableCharacteristic(type: QUIT_UUID, properties: .write, value: nil, permissions: .writeable)
            
            writeCharacteristics = [roundCharacteristic, placeCharacteristic, roundDataCharacteristic, difficultyCharacteristic, uniqueNameCharacteristic, quitCharacteristic]
            writeService.characteristics = writeCharacteristics
            
            peripheralManager.add(readService)
            peripheralManager.add(writeService)
        } else {
            createAlert(title: "Bluetooth not powered on", message: "Make sure Bluetooth is turned on and your device can allow new connections")
        }
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
        for request in requests {
            print("write request to \(request.characteristic.uuid)")
            switch request.characteristic.uuid {
            
            case ROUND_UUID:
                if let value = request.value {
                    let round = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                        return ptr.pointee
                    }
                    
                    if(round == 1) { // start game
                        print("performing segue")
                        performSegue(withIdentifier: "startGroupGameSegue", sender: nil)
                        mode = .group_player
                        groupModeGameStarted = true
                        timer.invalidate()
                        peripheralManager.stopAdvertising()
                    }
                    
                    peripheral.respond(to: request, withResult: .success)
                    
                    print("round: \(round)")
                }
                
            case PLACE_UUID:
                if let value = request.value {
                    place = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                        return ptr.pointee
                    }
                    
                    print("place: \(place)")
                    
                    globalAnswerVC?.updatePlace(place: place)
                    
                    peripheral.respond(to: request, withResult: .success)
                }
 
            case DIFFICULTY_UUID:
                if let value = request.value {
                    difficulty = value.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
                        return ptr.pointee
                    }
                    print("difficulty: \(difficulty)")
                    
                    peripheral.respond(to: request, withResult: .success)
                }
            case ROUND_DATA_UUID:
                if let value = request.value {
                    
                    groupModeRounds = stringToTwoDArray(string: String(decoding: value, as: UTF8.self))
                    
                    print("round data uuid")
                    print("rounds: \(groupModeRounds)")
                    
                    globalAnswerVC?.updateContinueButton()
                    
                    peripheral.respond(to: request, withResult: .success)
                } else {
                    print("round data bad value")
                }
                
            case UNIQUE_NAME_UUID:
                if let value = request.value {
                    
                    let uniqueName = String(decoding: value, as: UTF8.self) == "1"
                    
                    print(uniqueName)
                    
                    if !uniqueName {
                        peripheralManager.stopAdvertising()
                        lastName = nameTextField.text! // don't enter the same name twice in a row...
                        nameTextField.text = ""
                        nameTextField.isEnabled = true
                        waitingLabel.isHidden = true
                        nameTextField.becomeFirstResponder()
                        createAlert(title: "Name already taken", message: "Please enter a new name")
                    } else {
                        
                        var timerCount = 0
                        
                        timer.invalidate()
                        
                        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                            
                            switch timerCount % 4 {
                            case 0:
                                self.waitingLabel.text = "Waiting for start."
                                print("Waiting for start.")
                            case 1:
                                self.waitingLabel.text = "Waiting for start.."
                                print("Waiting for start..")
                            case 2:
                                self.waitingLabel.text = "Waiting for start..."
                                print("Waiting for start...")
                            case 3:
                                self.waitingLabel.text = "Waiting for start"
                                print("Waiting for start")
                            default:
                                self.waitingLabel.text = "Waiting for start"
                            }
                            
                            // make sure characteristics are discovered before being able to quit
                            if timerCount >= 2 {
                                self.quitButton.isHidden = false
                            } else {
                                self.quitButton.isHidden = true
                            }
                            
                            timerCount += 1
                        }
                    }
                    
                    peripheral.respond(to: request, withResult: .success)
                }
                
            case QUIT_UUID:
                didManagerQuit = true
                print("manager quit")
                peripheral.respond(to: request, withResult: .success)
            default:
                print("incorrect uuid")
            }
        }
    }
}

// break down string
func stringToTwoDArray(string: String) -> [[String]] {
    var ret = [[String]]()
    for arr in string.components(separatedBy: ";") {
        ret.append(arr.components(separatedBy: ","))
    }
    
    return ret
}
