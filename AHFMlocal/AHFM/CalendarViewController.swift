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

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, UITableViewDelegate, UITableViewDataSource {
    
    private var context: CoreDataStack!
  
    @IBOutlet weak var calendarView: FSCalendar!
    
    class func newCalendarVC(context: CoreDataStack) -> CalendarViewController {
        let calendar = UIStoryboard(name: "CalendarAHFM", bundle: nil).instantiateInitialViewController() as! CalendarViewController
        calendar.context = context
        return calendar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dowloadFile()
        calendarView.scope = .week
    }
    
    func dowloadFile(){
        
        let requestURL = URL(string: "http://ah.fm/stats/mobileschedule.txt")!
        let task = URLSession.shared.dataTask(with: requestURL) { (possibleData, possibleResponse, possibleError) in
            guard let data = possibleData, possibleError == nil else {
                print("Invalid URL")
                return
            }
            
            let parsedString = String(data: data, encoding: String.Encoding.utf8)!
            let schedule = parsedString as NSString
            do {
                // Begin parsing the text file into triples.
                let dayRegex = try NSRegularExpression(pattern: "---- \\w+, [0-9]{2}-[0-9]{2}-[0-9]{4} ----")
                let dayMatches = dayRegex.matches(in: schedule as String, range: NSRange(location: 0, length: schedule.length))
                let dayTuples = dayMatches.map { dayMatch -> (String, NSRange) in
                    let dayMatchRange = dayMatch.range
                    let dayMatchSubstring = schedule.substring(with: dayMatchRange)
                    return (dayMatchSubstring, dayMatchRange)
                }
                
                let hourRegex = try NSRegularExpression(pattern: "[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2} .+")
                let hourMatches = hourRegex.matches(in: schedule as String, range: NSRange(location: 0, length: schedule.length))
                
                let hourTriple = hourMatches.map { hourMatchRange -> (Date, Date, String) in
                    
                    var formattedInitialDate = Date()
                    var formattedEndDate = Date()
                    var setName = ""
                    let hourRange = hourMatchRange.range
                    let hourMatchSubstring = schedule.substring(with: hourRange)
                    
                    for dayTuple in dayTuples {
                        guard dayTuple.1.location < hourRange.location else { continue }
                        
                        var separatedHourMatchSubstring = hourMatchSubstring.components(separatedBy: " ")
                        let setHours = separatedHourMatchSubstring.removeFirst()
                        setName = separatedHourMatchSubstring.joined(separator: " ")
                        var separatedHours = setHours.components(separatedBy: "-")
                        let setEndHour = separatedHours.remove(at: 1)
                        let setInitialHour = separatedHours.removeFirst()
                        let setInitialDateAndHour = dayTuple.0 + setInitialHour
                        let setEndDateAndHour = dayTuple.0 + setEndHour
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = TimeZone(secondsFromGMT: 3600*2)
                        dateFormatter.dateFormat = "---- EEEE, dd-MM-yyyy ----kk:mm"
                        formattedInitialDate = dateFormatter.date(from: setInitialDateAndHour)!
                        formattedEndDate = dateFormatter.date(from: setEndDateAndHour)!
//                        if formattedEndDate < formattedInitialDate {
//                            formattedEndDate = formattedEndDate.addingTimeInterval(86400)
//                        }
                    }
                    
                    //print(formattedInitialDate, formattedEndDate, setName)
                    return (formattedInitialDate, formattedEndDate, setName)
                }
                
                var incrementedEndDate: Date?
                let fixedDatesTriples = hourTriple.map { triple -> (Date, Date, String) in
                    // In the case where the initial date is higher than the end date, for example:
                    // 23:00-00:00 Ellicit Radio
                    guard triple.0 < triple.1 else {
                        // The end date must be fixed, so a day is added to it.
                        let fixedEndDate = triple.1.addingTimeInterval(86400)
                        incrementedEndDate = fixedEndDate
                        print (triple.0, fixedEndDate, triple.2)
                        return (triple.0, fixedEndDate, triple.2)
                    }
                    // If the initial date is lower, then check the next case,
                    // In the case where the initial date is higher than the incrementedEndDate, after the correction is made
                    guard let existingEndDate = incrementedEndDate else {
                        incrementedEndDate = triple.1
                        print(triple)
                        return triple
                    }
                    
                    guard triple.0 >= existingEndDate else {
                        // The initial date must be fixed by adding a day to it
                        let fixedInitialDate = triple.0.addingTimeInterval(86400)
                        // If the corrected initial date is higher than the end date
                        guard fixedInitialDate < triple.1 else {
                            // The end date must be fixed by adding a day to it.
                            let fixedEndDate = triple.1.addingTimeInterval(86400)
                            incrementedEndDate = fixedEndDate
                            print (fixedInitialDate, fixedEndDate, triple.2)
                            return (fixedInitialDate, fixedEndDate, triple.2)
                        }
                        // If the initial date is lower, a day is added to the initial date
                        incrementedEndDate = triple.1
                        print (fixedInitialDate, triple.1, triple.2)
                        return (fixedInitialDate, triple.1, triple.2)
                    }
                    // If the initial date is lower, no change is made
                    incrementedEndDate = triple.1
                    print(triple)
                    return triple
                }
                
                var songsDictionary = [String : [(Date, Date)]]()
                fixedDatesTriples.forEach { (initial, end, name) in
                    if let existingDates = songsDictionary[name] {
                        var allDates = existingDates
                        allDates.append((initial, end))
                        songsDictionary[name] = allDates
                    } else {
                        songsDictionary[name] = [(initial, end)]
                    }
                }
                
//                let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")
//                fetchRequest.predicate = NSPredicate(format: "name IN %@", Array(songsDictionary.keys))
//                let duplicates = try self.context.mainContext.fetch(fetchRequest)
//                
//                duplicates.forEach { savedSong in
//                    
//                    guard let savedSongName = savedSong.name else {
//                        // FIXME: Why is a song saved in CoreData without a name? We should delete it.
//                        return
//                    }
//                    
//                    guard let airDates = songsDictionary[savedSongName] else {
//                        // This should never happen.
//                        return
//                    }
                
//                    let newAirDateClosure = {
//                        guard let newAirDate = AirDate(initialDate: airDates.0, endDate: airDates.1, context: self.context.mainContext) else { return }
//                        
//                        savedSong.addToAirDates(newAirDate)
//                        songsDictionary.removeValue(forKey: savedSongName)
//                    }
//                    
//                    guard let savedAirDates = savedSong.airDates, let savedAirDatesSet = savedAirDates as? Set<AirDate> else {
//                        // FIXME: Why is a song saved in CoreData without airDates?
//                        newAirDateClosure()
//                        return
//                    }
//                    
//                    guard savedAirDatesSet.count <= 0 else {
//                        newAirDateClosure()
//                        return
//                    }
//                    
//                    for savedAirDate in savedAirDatesSet {
//                        guard let savedInitialDate = savedAirDate.initialDate as Date? else { return }
//                        guard savedInitialDate == airDates.0 else {
//                            // FIXME: Why is a song saved in CoreData without an InitialDate?
//                            return
//                        }
//                    }
//                    
//                    newAirDateClosure()
//                }
//                
                let _ = songsDictionary.map { keyValuePair -> [NSManagedObject?] in
                    return keyValuePair.value.map { (initial, end) -> NSManagedObject? in
                        return try? SongInfo.newSong(name: keyValuePair.key, initialDate: initial, endDate: end, context: self.context.mainContext)
                    }
                }
                
               self.context.save()
                
            } catch {
                print("Invalid regex")
            }
        }
        task.resume()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        guard let selectedDate = calendar.selectedDate else { return }
        let calendar = NSCalendar(calendarIdentifier: .gregorian)
        calendar?.timeZone = .current
        guard let newSelectedDate = calendar?.startOfDay(for: selectedDate) else { return }
        let newSelectedNSDate = newSelectedDate as NSDate
        let nextDay = calendar?.date(byAdding: .day, value: 1, to: newSelectedNSDate as Date)
        let nextNSDay = nextDay as NSDate!
        print(newSelectedDate)

        let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")//  AND
        fetchRequest.predicate = NSPredicate(format: "(ANY airDates.initialDate >= %@) AND (ANY airDates.initialDate < %@)", newSelectedNSDate, nextNSDay!)
        //fetchRequest.sortDescriptors = [NSSortDescriptor(key: "airDates.initialDate", ascending: true)]
        let results = try! self.context.mainContext.fetch(fetchRequest)
        results.forEach { song in
            song.airDates?.forEach{ (airDateAny) in
                let airDate = airDateAny as! AirDate
                print(song.name!, airDate.initialDate!)
            }
        }

//        let fetchedResultsController = NSFetchedResultsController<NSFetchRequestResult>(entityName: "SongInfo")
//        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SongInfo")
//        let nameSort = NSSortDescriptor(key: "name", ascending: true)
//        request.sortDescriptors = [nameSort]
//        
//        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context.mainContext, sectionNameKeyPath: "name", cacheName: nil)
//        fetchedResultsController.delegate = self
//        
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            fatalError()
//        }
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        let calendarHeightConstraint = NSLayoutConstraint()
        calendarHeightConstraint.constant = bounds.size.height
        self.view.layoutIfNeeded()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell")
        return cell!
    }
    
    @IBAction func didPressCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
