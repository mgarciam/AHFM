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
    
    var context: NSManagedObjectContext!
    
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
                let dayRegex = try NSRegularExpression(pattern: "---- \\w+, [0-9]{2}-[0-9]{2}-[0-9]{4} ----")
                let dayMatches = dayRegex.matches(in: schedule as String, range: NSRange(location: 0, length: schedule.length))
                let dayTuples = dayMatches.map { dayMatch -> (String, NSRange) in
                    let dayMatchRange = dayMatch.range
                    let dayMatchSubstring = schedule.substring(with: dayMatchRange)
                    return (dayMatchSubstring, dayMatchRange)
                }
                
                var setName = ""
                var formattedInitialDate = Date()
                var formattedEndDate = Date()
                let hourRegex = try NSRegularExpression(pattern: "[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2} .+")
                let hourMatches = hourRegex.matches(in: schedule as String, range: NSRange(location: 0, length: schedule.length))
                let hourTriple = hourMatches.map { hourMatchRange -> (Date, Date, String) in
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
                    print(formattedInitialDate.timeIntervalSince1970, formattedEndDate.timeIntervalSince1970, setName)
                    self.context.perform {
                        try? SongInfo.init(name: setName.trimmingCharacters(in: CharacterSet.whitespaces), initialDate: formattedInitialDate, endDate: formattedEndDate, context: self.context)
                        //try? self.context.save()
                    }
                    return (formattedInitialDate, formattedEndDate, setName)
                }
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
