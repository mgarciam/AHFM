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

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, SongInfoDelegate {
    
    let calendar = NSCalendar(calendarIdentifier: .gregorian)
    
    private var context: CoreDataStack!
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    lazy var songDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
  
    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    class func newCalendarVC(context: CoreDataStack) -> CalendarViewController {
        let calendar = UIStoryboard(name: "CalendarAHFM", bundle: nil).instantiateInitialViewController() as! CalendarViewController
        calendar.context = context
        return calendar
    }
    
    private func fetchSongsFor(day: NSDate) {
        calendar?.timeZone = .current
        guard let newDate = calendar?.startOfDay(for: day as Date) else { return }
        let newNSDate = newDate as NSDate
        let nextDay = calendar?.date(byAdding: .day, value: 1, to: newDate as Date)
        let nextNSDay = nextDay as NSDate!
        
        let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")
        fetchRequest.predicate = NSPredicate(format: "(beginsAt >= %@) AND (beginsAt < %@)", newNSDate, nextNSDay!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "beginsAt", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: context.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            fatalError()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestUpdateFromDataSource),
                                               name: Notification.Name(schedule: .didUpdate),
                                               object: nil)

    }
    
    func requestUpdateFromDataSource() {
        try? fetchedResultsController?.performFetch()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.scope = .week
    
        guard let today = calendarView.today else { return }
        fetchSongsFor(day: today as NSDate)
    }
    
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
        fetchSongsFor(day: selectedDate as NSDate)
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController?.sections else {
            return 0
        }
        
        return sections[section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongCell
        let song = self.fetchedResultsController?.object(at: indexPath) as! SongInfo
        let beginHour = songDateFormatter.string(from: song.beginsAt! as Date)
        let endHour = songDateFormatter.string(from: song.endsAt! as Date)
        
        cell.nameLabel.text = song.name!
        cell.beginHourLabel.text = beginHour
        cell.endHourLabel.text = endHour
        cell.infoDelegate = self
        return cell
    }
    
    func songInfo(for cell: SongCell) -> SavedSong? {
        guard let indexPath = tableView.indexPath(for: cell) else { return nil }
        
        return SavedSong(song: self.fetchedResultsController?.object(at: indexPath) as! SongInfo)
    }
}

extension CalendarViewController {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
