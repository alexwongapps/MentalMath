//
//  AnswerViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 1/1/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit
import GameKit

var globalAnswerVC: AnswerViewController?

class AnswerViewController: UIViewController, GKGameCenterControllerDelegate, UITextFieldDelegate {
    
    let LEADERBOARD_IDS = ["com.mentalmath.easy", "com.mentalmath.normal", "com.mentalmath.hard"]
    
    var correct: Bool = false
    var gameOver: Bool = false
    
    // group mode
    var groupModeRoundStartTime = 0.0
    var timer = Timer()
    var timerDone: Bool = false
    var groupModeRoundDone = false

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var answerTextField: UITextField! {
        didSet {
            answerTextField?.addDoneToolbar(onDone: (target: self, action: #selector(doneButtonTappedForAnswerTextField))) }
    }
    @IBOutlet weak var correctAnswerLabel: UILabel!
    @IBOutlet weak var groupModeCountdownLabel: UILabel!
    @IBOutlet weak var seeStepsButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var stepsScrollView: UIScrollView!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highScoreLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton! // also doubles as main menu button
    @IBOutlet weak var playAgainButton: UIButton!
    @IBOutlet weak var leaderboardButton: UIButton! // also doubles as quit button
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        globalAnswerVC = self
        
        // make sure screen doesn't lock out
        UIApplication.shared.isIdleTimerDisabled = false
        answerTextField.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        resultLabel.isHidden = true
        correctAnswerLabel.isHidden = true
        seeStepsButton.isHidden = true
        scoreLabel.isHidden = true
        highScoreLabel.isHidden = true
        highScoreLabel.text = ""
        continueButton.isHidden = true
        playAgainButton.isHidden = true
        leaderboardButton.isHidden = true
        
        if mode == .group_player || mode == .group_manager {
            groupModeRoundDone = false
            groupModeCountdownLabel.isHidden = false
            groupModeCountdownLabel.text = "Time left: 5"
            timerDone = false
        } else {
            groupModeCountdownLabel.isHidden = true
        }
        
        answerTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
    
        answerTextField.becomeFirstResponder()
        
        if mode == .group_player || mode == .group_manager {
            groupModeRoundStartTime = Date.timeIntervalSinceReferenceDate
            
            var runCount = 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                
                runCount += 1
                
                if runCount < 5 {
                    self.timerDone = false
                    
                    if self.correct && !self.gameOver {
                        self.groupModeCountdownLabel.text = "Next round in \(5 - runCount)"
                    } else if !self.gameOver { // waiting for answer
                        self.groupModeCountdownLabel.text = "Time left: \(5 - runCount)"
                    } else {
                        self.groupModeCountdownLabel.text = ""
                    }
                } else if !self.groupModeRoundDone && self.answerTextField.text! == "" { // out of time
                    self.timerDone = true
                    
                    self.groupModeRoundDone = true
                    self.groupModeCountdownLabel.isHidden = true
                    self.answerTextField.text = "Out of time"
                    self.doneButtonTappedForAnswerTextField()
                    
                    timer.invalidate()
                } else if !self.groupModeRoundDone { // something answered, timer out
                    self.doneButtonTappedForAnswerTextField()
                } else { // correct, continue
                    if groupModeRounds.count > score && !self.gameOver { // automatically continue
                        self.pressButton(self.continueButton)
                    }
                    
                    timer.invalidate()
                }
            }
        }
    }

    @objc func doneButtonTappedForAnswerTextField() {
        if(answerTextField.text != "") { // make sure there is an answer entered in
            
            let answerString = String(finalAnswer)
            answerTextField.isEnabled = false
            
            if(answerString == answerTextField.text) { // correct
                correct = true
                
                score += 1
                
                resultLabel.text = "Correct!"
                correctAnswerLabel.isHidden = true
                scoreLabel.text = "Score: \(score)"
                continueButton.setTitle("Continue", for: .normal)
                continueButton.setTitle("Continue", for: .selected)
                
                leaderboardButton.setTitle("Quit", for: .normal)
                leaderboardButton.setTitle("Quit", for: .selected)
                
                numbers += NUMBER_INCREMENT
                maxAnswer += MAX_INCREMENT
                
            } else { // incorrect
                correct = false
                
                resultLabel.text = "Incorrect"
                correctAnswerLabel.isHidden = false
                correctAnswerLabel.text = "The answer was \(finalAnswer)"
                
                endGame()
            }
            
            if mode == .solo {
                continueButton.isHidden = false
            }
            
            // group mode
            
            if mode == .group_player {
                groupModeRoundDone = true
                
                if correct {
                    groupModeTime += Date.timeIntervalSinceReferenceDate - groupModeRoundStartTime // add time
                }
                
                globalStudentVC?.sendScore(score: score, alive: correct)
                
                highScoreLabel.isHidden = false
            } else if mode == .group_manager {
                groupModeRoundDone = true
                
                if correct {
                    groupModeTime += Date.timeIntervalSinceReferenceDate - groupModeRoundStartTime // add time
                }
                
                globalManagerVC?.updateManagerScore(name: groupModeName, score: score, alive: correct)
                
                highScoreLabel.isHidden = false
            }
        
            seeStepsButton.isHidden = false
        
            resultLabel.isHidden = false
            scoreLabel.isHidden = false
            leaderboardButton.isHidden = false
            answerTextField.resignFirstResponder()
        }
    }
    
    @IBAction func seeSteps(_ sender: Any) {
        stepsLabel.text = steps
        backButton.isHidden = false
        stepsScrollView.isHidden = false
    }
    
    @IBAction func hideSteps(_ sender: Any) {
        backButton.isHidden = true
        stepsScrollView.isHidden = true
    }
    
    // continue/main menu button
    @IBAction func pressButton(_ sender: Any) {
        
        if(!gameOver) { // correct
            
            // if playing in group mode and manager quit, exit game
            if mode == .group_player && globalStudentVC?.didManagerQuit ?? false {
                // create alert
                
                let alert = UIAlertController(title: "Game over", message: "The manager ended the game", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    
                    self.gameOver = false // reset game over variable
                    self.performSegue(withIdentifier: "menuSegue", sender: nil)
                }))
                
                self.present(alert, animated: true, completion: nil)
            } else {
                self.performSegue(withIdentifier: "playAgainSegue", sender: nil)
            }
        } else {
            gameOver = false // reset game over variable
            self.performSegue(withIdentifier: "menuSegue", sender: nil)
        }
    }
    
    @IBAction func playAgain(_ sender: Any) {
        resetGame()
    }
    
    @IBAction func viewLeaderboard(_ sender: Any) {
        
        if(leaderboardButton.titleLabel?.text == "Quit") { // quit button
            endGame()
            if mode == .group_player  {
                globalStudentVC?.sendScore(score: score, alive: false)
            }
        } else { // view leaderboard
            let gcVC = GKGameCenterViewController()
            gcVC.gameCenterDelegate = self
            gcVC.viewState = .leaderboards
            gcVC.leaderboardIdentifier = LEADERBOARD_IDS[difficulty]
            present(gcVC, animated: true, completion: nil)
        }
    }
    
    // ends game and submits score to game center
    func endGame() {
        gameOver = true
        
        scoreLabel.text = "Final score: \(score)"
        continueButton.setTitle("Main Menu", for: .normal)
        continueButton.setTitle("Main Menu", for: .selected)
        
        continueButton.isHidden = false
        
        leaderboardButton.setTitle("Leaderboard", for: .normal)
        leaderboardButton.setTitle("Leaderboard", for: .selected)
        
        // save if high score
        
        let defaults = UserDefaults.standard
        
        var keyName = ""
        
        if(difficulty == EASY) { keyName = "highScoreEasy" }
        else if(difficulty == NORMAL) { keyName = "highScoreNormal" }
        else if(difficulty == HARD) { keyName = "highScoreHard" }
        
        var highScore = defaults.integer(forKey: keyName)
        
        if(score > highScore) {
            highScore = score
            defaults.set(highScore, forKey: keyName)
        }
        
        if mode == .solo {
            highScoreLabel.text = "High score: \(highScore)"
            highScoreLabel.isHidden = false
        }
        
        // hide button in group mode, show it in solo mode
        playAgainButton.isHidden = !(mode == .solo)
        
        groupModeCountdownLabel.isHidden = true
        
        // game center
        
        // Submit score to GC leaderboard
        let scoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_IDS[difficulty])
        scoreInt.value = Int64(score)
        GKScore.report([scoreInt]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Score submitted to Game Center Leaderboard!")
            }
        }
    }
    
    // called from other vc
    
    func updatePlace(place: Int) {
        
        if place == 0 {
            highScoreLabel.text = ""
        } else if (place % 100 == 11) || (place % 100 == 12) || (place % 100 == 13) {
            highScoreLabel.text = "You are in \(place)th place"
        } else if place % 10 == 1 {
            highScoreLabel.text = "You are in \(place)st place"
        } else if place % 10 == 2 {
            highScoreLabel.text = "You are in \(place)nd place"
        } else if place % 10 == 3 {
            highScoreLabel.text = "You are in \(place)rd place"
        } else {
            highScoreLabel.text = "You are in \(place)th place"
        }
    }
    
    func updateContinueButton() {
        if groupModeRounds.count > score && timerDone && !gameOver { // automatically continue
            pressButton(continueButton)
        }
    }
    
    // text field
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButtonTappedForAnswerTextField()
        return true
    }
    
    // game center
    
    // Delegate to dismiss the GC controller
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
}
