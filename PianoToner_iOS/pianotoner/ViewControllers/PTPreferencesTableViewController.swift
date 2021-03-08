/*
 
 PianoToneriOS - piano tone generator
 Copyright (C) 2017-2021  Luca Cipressi lucaji()mail.ru

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>
 
 */

//
//  PTPreferencesTableViewController.swift
//  pianotoner
//
//  Created by Luca Cipressi on 21/11/2018 - lucaji()mail.ru
//

import UIKit

class PTPreferencesTableViewController: UITableViewController {
    
    @IBAction func saveSettingsButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func aboutThisAppButtonAction(_ sender: UIButton) {
        if let destUrl = URL(string: "https://lucaji.github.io/") {
            AppDelegate.goToUrl(destUrl: destUrl, from: self)
        }
    }
    
    
    
    @IBOutlet weak var sharpsSwitch: UISwitch!
    @IBAction func sharpsSwitchAction(_ sender: UISwitch) {
        PTNote.usingSharps = sender.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sharpsSwitch.isOn = PTNote.usingSharps
    }

}
