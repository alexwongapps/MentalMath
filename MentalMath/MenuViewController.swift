
//
//  MenuViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 1/1/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit
import GameKit

let EASY = 0
let NORMAL = 1
let HARD = 2

var difficulty: Int = NORMAL

var score: Int = 0
var steps: String = ""

var mode: Mode = .solo

enum Mode: Int {
    case solo = 0, group_player = 1, group_manager = 2
}

// game mechanics
var numbers = 5 // number of numbers in the round
let STARTING_NUMBERS = 5
let NUMBER_INCREMENT = 1 // number of numbers to add per round
var maxAnswer = 25 // max answer in the round
let STARTING_MAX_ANSWER = 25
let MAX_INCREMENT = 5 // amount to increment max number per round
let opProbs = [3, 3, 5, 3] // odds of getting each operation

let HIGHEST_NUMBERS = [9, 12, 15]
let TIME_INTERVALS = [1.2, 0.8, 0.5]

var globalMenuVC: MenuViewController?

class MenuViewController: UIViewController, GKGameCenterControllerDelegate {
    
    // game center
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    
    let LEADERBOARD_IDS = ["com.mentalmath.easy", "com.mentalmath.normal", "com.mentalmath.hard"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Call the GC authentication controller
        authenticateLocalPlayer()
        
        globalMenuVC = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // reset game
        
        resetGame()
        mode = .solo
        
        if(segue.identifier == "easySegue") {
            difficulty = EASY
        } else if(segue.identifier == "normalSegue") {
            difficulty = NORMAL
        } else {
            difficulty = HARD
        }
    }
    
    // game center
    
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error!)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error!)
            }
        }
    }
    
    @IBAction func viewLeaderboard(_ sender: Any) {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_IDS[difficulty]
        present(gcVC, animated: true, completion: nil)
    }
    
    @IBAction func startGroupMode(_ sender: Any) {
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: "skipInstructions") {
            performSegue(withIdentifier: "groupModeSkipInstructionsSegue", sender: nil)
        } else {
            performSegue(withIdentifier: "groupModeShowInstructionsSegue", sender: nil)
        }
    }
    
    // Delegate to dismiss the GC controller
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}

extension UITextField {
    func addDoneToolbar(onDone: (target: Any, action: Selector)? = nil) {
        let onDone = onDone ?? (target: self, action: #selector(doneButtonTapped))
        
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()
        
        self.inputAccessoryView = toolbar
    }
    
    // Default actions:
    @objc func doneButtonTapped() { self.resignFirstResponder() }
}

func resetGame() {
    score = 0
    
    numbers = STARTING_NUMBERS
    maxAnswer = STARTING_MAX_ANSWER
}

extension UIColor {
    static let aqua = globalMenuVC?.view.backgroundColor
}
