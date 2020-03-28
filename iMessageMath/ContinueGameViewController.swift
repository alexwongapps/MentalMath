//
//  ContinueGameViewController.swift
//  iMessageMath
//
//  Created by Alex Wong on 2/23/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit

// game mechanics
let STARTING_NUMBERS = 5
let NUMBER_INCREMENT = 1 // number of numbers to add per round
let STARTING_MAX_ANSWER = 25
let MAX_INCREMENT = 5 // amount to increment max number per round
let opProbs = [3, 3, 5, 3] // odds of getting each operation

let HIGHEST_NUMBERS = [9, 12, 15]
let TIME_INTERVALS = [1.2, 0.8, 0.5]

class ContinueGameViewController: UIViewController {
    
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    static let storyboardIdentifier = "continueGameStoryboardIdentifier"
    
    weak var delegate: ContinueGameViewControllerDelegate?

    var game: Game?
    
    @IBAction func startRound(_ sender: Any) {
        
        beginLabel.isHidden = false
        numberLabel.isHidden = false
        numberLabel.text = "3"
        
        gameView.isHidden = false
        
        var runCount = 0
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            
            runCount += 1
            if(runCount != 3) {
                self.numberLabel.text = "\(3 - runCount)"
            } else {
                self.beginLabel.isHidden = true
                self.numberLabel.text = "Go"
            }
            
            if runCount == 3 {
                self.startGame()
                timer.invalidate()
            }
        }
    }
    
    func startGame() {
        
        // operation constants
        let ADD: Int = 0
        let SUBTRACT: Int = 1
        let MULTIPLY: Int = 2
        let DIVIDE: Int = 3
        
        var gameRunCount = 0
        var answer: Int = 0
        
        var operation: Int = ADD
        
        // difficulty stuff
        let timeInterval = TIME_INTERVALS[difficulty]
        let highestNumber = HIGHEST_NUMBERS[difficulty]
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { gameTimer in
            
            if(mode == .solo) {
                
                if(gameRunCount == 0) {
                    steps = "" // clear steps
                    
                    answer = Int.random(in: 2...highestNumber)
                    self.numberLabel.text = "\(answer)"
                } else if(gameRunCount >= numbers * 2 - 1) {
                    self.numberLabel.text = "="
                } else if(gameRunCount % 2 == 1) { // operations
                    
                    steps += "\(answer)"
                    
                    // get usable numbers for each operation
                    self.usableNumbers = getUsableNumbers(answer: answer, maxAnswer: maxAnswer, highestNumber: highestNumber)
                    
                    // decide which operation to use
                    var usableOperations = [ADD, SUBTRACT, MULTIPLY, DIVIDE]
                    
                    // remove operations that can't be done
                    for i in (0..<usableOperations.count).reversed() {
                        if(self.usableNumbers[i].count == 0) {
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
                        self.numberLabel.text = "+"
                        break
                        
                    case SUBTRACT:
                        self.numberLabel.text = "-"
                        break
                        
                    case MULTIPLY:
                        self.numberLabel.text = "×"
                        break
                        
                    case DIVIDE:
                        self.numberLabel.text = "÷"
                        break
                        
                    default:
                        self.numberLabel.text = "+"
                        break
                        
                    }
                    
                    steps += " \(self.numberLabel.text!)"
                    
                } else { // numbers
                    
                    // get number
                    let newNumberIndex = Int.random(in: 0..<self.usableNumbers[operation].count)
                    let newNumber = self.usableNumbers[operation][newNumberIndex]
                    
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
                    
                    self.numberLabel.text = "\(newNumber)"
                    print("\(operation) \(newNumber) = \(answer)")
                    
                    steps += " \(newNumber) = \(answer)\n\n"
                }
            } else { // group mode
                print("group mode")
                print(groupModeRounds)
                
                if score > groupModeRounds.count - 1 {
                    let alert = UIAlertController(title: "Group Mode error", message: "Group Mode encountered an error", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        alert.dismiss(animated: true, completion: nil)
                        self.performSegue(withIdentifier: "returnToMenuSegue", sender: nil)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                } else {
                    
                    if(gameRunCount < groupModeRounds[score].count - 1) {
                        self.numberLabel.text = groupModeRounds[score][gameRunCount]
                    }
                    answer = Int(groupModeRounds[score][groupModeRounds[score].count - 1])!
                    
                    steps = getGroupModeSteps(roundArray: groupModeRounds[score])
                }
            }
            
            gameRunCount += 1
            
            if gameRunCount == numbers * 2 + 1 {
                gameTimer.invalidate()
                self.performSegue(withIdentifier: "answerSegue", sender: nil)
                finalAnswer = answer
                answering = true
            }
        }
    }

}

extension MessagesViewController: ContinueGameViewControllerDelegate {
    
    
}

protocol ContinueGameViewControllerDelegate: class {
}
