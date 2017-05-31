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

class CalendarViewController: UIViewController {
    
    private var context: CoreDataStack!
    private var resultsArr: [NSPersistentStoreResult] = []
    
    class func newCalendarVC(context: CoreDataStack) -> CalendarViewController {
        let calendar = UIStoryboard(name: "CalendarAHFM", bundle: nil).instantiateInitialViewController() as! CalendarViewController
        calendar.context = context
        return calendar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dowloadFile()
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
                        dateFormatter.dateFormat = "---- EEEE, dd-MM-yyyy ----kk:mm"
                        formattedInitialDate = dateFormatter.date(from: setInitialDateAndHour)!
                        formattedEndDate = dateFormatter.date(from: setEndDateAndHour)!
                    }
                    
                    return (formattedInitialDate, formattedEndDate, setName)
                }
                
                var songsDictionary = [String : (Date, Date)]()
                hourTriple.forEach { (initial, end, name) in
                    songsDictionary[name] = (initial, end)
                }
                
                let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")
                fetchRequest.predicate = NSPredicate(format: "name IN %@", Array(songsDictionary.keys))
                let duplicates = try self.context.mainContext.fetch(fetchRequest)
                
                duplicates.forEach { savedSong in
                    
                    guard let savedSongName = savedSong.name else {
                        // FIXME: Why is song saved in CoreData without a name? We should delete it.
                        return
                    }
                    
                    guard let airDates = songsDictionary[savedSongName] else {
                        // This should never happen.
                        return
                    }
                    
                    let newAirDateClosure = {
                        guard let newAirDate = AirDate(initialDate: airDates.0, endDate: airDates.1, context: self.context.mainContext) else { return }
                        
                        savedSong.addToAirDates(newAirDate)
                        songsDictionary.removeValue(forKey: savedSongName)
                    }
                    
                    guard let savedAirDates = savedSong.airDates, let savedAirDatesSet = savedAirDates as? Set<AirDate> else {
                        // FIXME: Why is song saved in CoreData without airDates?
                        newAirDateClosure()
                        return
                    }
                    
                    guard savedAirDatesSet.count <= 0 else {
                        newAirDateClosure()
                        return
                    }
                    
                    for savedAirDate in savedAirDatesSet {
                        guard let savedInitialDate = savedAirDate.initialDate as Date? else { return }
                        guard savedInitialDate == airDates.0 else {
                            // FIXME: Why is song saved in CoreData without an InitialDate?
                            return
                        }
                    }
                    
                    newAirDateClosure()
                }
                
                let _ = songsDictionary.map { keyValuePair -> NSManagedObject? in
                    return try? SongInfo.newSong(name: keyValuePair.key, initialDate: keyValuePair.value.0, endDate: keyValuePair.value.1, context: self.context.mainContext)
                }
                
               self.context.save()
                
            } catch {
                print("Invalid regex")
            }
        }
        task.resume()
    }
    
    @IBAction func didPressCloseButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
