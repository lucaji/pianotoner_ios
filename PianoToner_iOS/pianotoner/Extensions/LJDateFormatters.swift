//
//  LJDateFormatters.swift
//  MyTuna
//
//  Created by looka on 24/12/2017.
//  Copyright © 2017 themilletgrainfromouterspace.org. All rights reserved.
//

import UIKit

class LJDateFormatters: NSObject {
    lazy var mediumShortDateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

}
