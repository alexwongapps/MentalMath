//
//  StartGameViewController.swift
//  iMessageMath
//
//  Created by Alex Wong on 2/23/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit

class StartGameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static let storyboardIdentifier = "startGameStoryboardIdentifier"
    
    weak var delegate: StartGameViewControllerDelegate?
    
    @IBAction func startGame(_ sender: UIButton) {
        
        switch sender.tag {
        
        case Difficulty.easy.rawValue:
            delegate?.didStartGame(difficulty: Difficulty.easy)
        
        case Difficulty.normal.rawValue:
            delegate?.didStartGame(difficulty: Difficulty.normal)
            
        case Difficulty.hard.rawValue:
            delegate?.didStartGame(difficulty: Difficulty.hard)
            
        default:
            delegate?.didStartGame(difficulty: Difficulty.normal)
        }
    }
    
}

extension MessagesViewController: StartGameViewControllerDelegate {
    
    func didStartGame(difficulty: Difficulty) {
        
        let conversation = activeConversation
        let session = conversation?.selectedMessage?.session
        
        var components = URLComponents()
        let
        
        requestPresentationStyle(.expanded)
    }
}

protocol StartGameViewControllerDelegate: class {
    
    func didStartGame(difficulty: Difficulty)
}
