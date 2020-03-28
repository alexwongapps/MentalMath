//
//  GameViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 1/1/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit

var finalAnswer: Int = 0

var groupModeRounds: [[String]] = [[]]

var answering: Bool = true // is this answering a question or coming back from steps?

class GameViewController: UIViewController {

    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    
    var runningCountdown = true
    var usableNumbers: [[Int]] = [] // holder for each operation, what numbers are usable
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // make sure screen doesn't lock out
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        beginLabel.isHidden = false
        numberLabel.isHidden = false
        
        numberLabel.text = "3"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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

func factors(of n: Int) -> [Int] {
    precondition(n > 0, "n must be positive")
    let sqrtn = Int(Double(n).squareRoot())
    var factors: [Int] = []
    factors.reserveCapacity(2 * sqrtn)
    for i in 1...sqrtn {
        if n % i == 0 {
            factors.append(i)
        }
    }
    var j = factors.count - 1
    if factors[j] * factors[j] == n {
        j -= 1
    }
    while j >= 0 {
        factors.append(n / factors[j])
        j -= 1
    }
    return factors
}

func getUsableNumbers(answer: Int, maxAnswer: Int, highestNumber: Int) -> [[Int]] {
    var addUsableNumbers: [Int] = []
    var subtractUsableNumbers: [Int] = []
    var multiplyUsableNumbers: [Int] = []
    var divideUsableNumbers: [Int] = []
    
    for i in 1...highestNumber {
        addUsableNumbers.append(i)
        subtractUsableNumbers.append(i)
        multiplyUsableNumbers.append(i)
        divideUsableNumbers.append(i)
    }
    
    let fac = factors(of: answer) // for dividing
    
    for i in (0..<addUsableNumbers.count).reversed() {
        
        // adding
        if(answer + addUsableNumbers[i] > maxAnswer) {
            addUsableNumbers.remove(at: i)
        }
        
        // subtracting
        if(answer - subtractUsableNumbers[i] < 1) {
            subtractUsableNumbers.remove(at: i)
        }
        
        // multiplying (don't want to multiply by 1)
        if((answer * multiplyUsableNumbers[i] > maxAnswer) || i == 0) {
            multiplyUsableNumbers.remove(at: i)
        }
        
        // dividing (don't want to divide by 1)
        if(!fac.contains(divideUsableNumbers[i]) || i == 0 || divideUsableNumbers[i] == answer) {
            divideUsableNumbers.remove(at: i)
        }
    }
    
    return [addUsableNumbers, subtractUsableNumbers, multiplyUsableNumbers, divideUsableNumbers]
}

func getGroupModeSteps(roundArray: [String]) -> String {
    var ret = ""
    var answer = Int(roundArray[0])!
    for i in 0..<roundArray.count / 2 - 1 {
        
        ret += "\(answer) \(roundArray[2 * i + 1]) \(roundArray[2 * i + 2]) = "
        
        switch roundArray[2 * i + 1] {
        case "+":
            answer += Int(roundArray[2 * i + 2])!
        case "-":
            answer -= Int(roundArray[2 * i + 2])!
        case "×":
            answer *= Int(roundArray[2 * i + 2])!
        case "÷":
            answer /= Int(roundArray[2 * i + 2])!
        default:
            answer += Int(roundArray[2 * i + 2])!
        }
        
        ret += "\(answer)\n\n"
    }
    
    return ret
}
