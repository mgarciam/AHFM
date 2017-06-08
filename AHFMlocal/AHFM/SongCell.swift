//
//  SongCell.swift
//  AHFM
//
//  Created by Marilyn on 6/8/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet weak var beginHourLabel: UILabel!
    @IBOutlet weak var endHourLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var leadingHoursSeparatorConstraint: NSLayoutConstraint!
}
