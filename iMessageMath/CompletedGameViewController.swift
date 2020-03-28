//
//  CompletedGameViewController.swift
//  iMessageMath
//
//  Created by Alex Wong on 2/23/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit

class CompletedGameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static let storyboardIdentifier = "completedGameStoryboardIdentifier"
    
    weak var delegate: CompletedGameViewControllerDelegate?

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MessagesViewController: CompletedGameViewControllerDelegate {
    
}

protocol CompletedGameViewControllerDelegate: class {
    
}
