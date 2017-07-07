//
//  CalendarViewController.swift
//  AHFM
//
//  Created by Marilyn on 5/23/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CalendarViewController: SongsViewController {

    let calendar = NSCalendar(calendarIdentifier: .gregorian)
    
    var day = Date()
  
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    class func newCalendarVC(context: CoreDataStack) -> CalendarViewController {
        let calendar = UIStoryboard(name: "CalendarAHFM", bundle: nil).instantiateInitialViewController() as! CalendarViewController
        calendar.context = context
        return calendar
    }
    
    override var requestSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "beginsAt", ascending: true)]
    }
    
    override var requestPredicate: NSPredicate {
        calendar?.timeZone = .current
        let newDate = calendar?.startOfDay(for: day as Date)
        let newNSDate = newDate! as NSDate
        let nextDay = calendar?.date(byAdding: .day, value: 1, to: newDate!)
        let nextNSDay = nextDay as NSDate!
        
        return NSPredicate(format: "(beginsAt >= %@) AND (beginsAt < %@)", newNSDate, nextNSDay!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.scope = .week
    }
    
    @IBAction func didPressCloseCalendarButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension CalendarViewController : FSCalendarDelegate, FSCalendarDataSource {
    
    func minimumDate(for calendar: FSCalendar) -> Date {
        let current = Calendar.current
        let date = Date()
        return current.date(from: current.dateComponents([.year, .month], from: current.startOfDay(for: date)))!
    }
    
    func maximumDate(for calendar: FSCalendar) -> Date {
        let current = Calendar.current
        let date = Date()
        let components = current.dateComponents([.year, .month], from: date)
        let startOfMonth = current.date(from: components)
        return current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth!)!
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        guard let selectedDate = calendar.selectedDate else { return }
        day = selectedDate
        requestUpdateFromDataSource()
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
}
