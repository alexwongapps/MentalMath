//
//  GroupModeInstructionsViewController.swift
//  MentalMath
//
//  Created by Alex Wong on 2/11/19.
//  Copyright © 2019 Kids Can Code. All rights reserved.
//

import UIKit

class GroupModeInstructionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func dontShowAgain(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "skipInstructions")
        performSegue(withIdentifier: "groupModeSelectSegue", sender: nil)
    }
    
    @IBAction func `continue`(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "skipInstructions")
        performSegue(withIdentifier: "groupModeSelectSegue", sender: nil)
    }

}
