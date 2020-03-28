//
//  Game.swift
//  iMessageMath
//
//  Created by Alex Wong on 2/23/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import Foundation

class Game {
    var rounds: [Round]
    var player1: Player
    var player2: Player
    var difficulty: Difficulty
    
    init(difficulty: Difficulty) {
        self.rounds = []
        self.player1 = Player()
        self.player2 = Player()
        self.difficulty = difficulty
    }
}

class Round: CustomStringConvertible {
    var array: [String]
    var answer: Int
    
    init() {
        self.array = []
        self.answer = 0
    }
    
    init(array: [String], answer: Int) {
        self.array = array
        self.answer = answer
    }
    
    var description: String {
        
    }
}

class Player: CustomStringConvertible {
    var score: Int
    var alive: Bool
    
    init() {
        self.score = 0
        self.alive = true
    }
    
    var description: String {
        return "\(score)|\(alive)"
    }
}

enum Difficulty: Int {
    case easy = 0, normal, hard
}
