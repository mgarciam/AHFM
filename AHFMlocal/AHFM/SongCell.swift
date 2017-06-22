//
//  SongCell.swift
//  AHFM
//
//  Created by Marilyn on 6/8/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit

protocol SongInfoDelegate {
    func showInfo(_ cell: SongCell)
    func songInfo(for cell: SongCell) -> SavedSong?
}

class SongCell: UITableViewCell {
    
    @IBOutlet weak var beginHourLabel: UILabel!
    @IBOutlet weak var endHourLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var leadingHoursSeparatorConstraint: NSLayoutConstraint!
    var panGesture: UIPanGestureRecognizer!
    var infoDelegate: SongInfoDelegate!
    
    var beginningLocationX: CGFloat = 0
    
    override func awakeFromNib() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureInCell(gesture:)))
        addGestureRecognizer(panGesture)
    }
    
    func panGestureInCell(gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            beginningLocationX = gesture.location(in: self).x
            
        case .changed:
                let dx = gesture.location(in: self).x - self.beginningLocationX
                var frameChange = (120*dx-3000)/(dx+1)-2
                if frameChange < -10 {
                    frameChange = -10
                }
                self.leadingHoursSeparatorConstraint.constant = frameChange
            
        case .ended:
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.layoutIfNeeded()
                self.leadingHoursSeparatorConstraint.constant = -10
                UIView.animate(withDuration: 0.33) {
                    self.layoutIfNeeded()
                }
            }
        default:
            break
            
        }
    }
    
    @IBAction func didPressInfoButton(_ sender: Any) {
        infoDelegate.showInfo(self)
    }
}

