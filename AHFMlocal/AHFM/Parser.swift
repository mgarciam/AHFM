//
//  Parser.swift
//  AHFM
//
//  Created by Marilyn on 6/13/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation
import CoreData

class Parser {
    
    var context: CoreDataStack!
    
    class func newParser(context: CoreDataStack) -> Parser {
        let parser = Parser()
        parser.context = context
        return parser
    }
    
    func parseFile() {
        
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
                    }
                    
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
                        return (triple.0, fixedEndDate, triple.2)
                    }
                    // If it is lower, no change is made.
                    guard let existingEndDate = incrementedEndDate else {
                        incrementedEndDate = triple.1
                        return triple
                    }
                    // If the initialDate is lower than the end date
                    guard triple.0 >= existingEndDate else {
                        // The initial date must be fixed by adding a day to it
                        let fixedInitialDate = triple.0.addingTimeInterval(86400)
                        // If the corrected initial date is higher than the end date
                        guard fixedInitialDate < triple.1 else {
                            // The end date must be fixed by adding a day to it.
                            let fixedEndDate = triple.1.addingTimeInterval(86400)
                            incrementedEndDate = fixedEndDate
                            
                            return (fixedInitialDate, fixedEndDate, triple.2)
                        }
                        // If the initial date is lower, a day is added to the initial date
                        incrementedEndDate = triple.1
                        return (fixedInitialDate, triple.1, triple.2)
                    }
                    // If the initial date is lower, no change is made
                    incrementedEndDate = triple.1
                    
                    return triple
                }
                
                self.context.mainContext.perform {
                    let fetchRequest = NSFetchRequest<SongInfo>(entityName: "SongInfo")
                    fetchRequest.predicate = NSPredicate(format: "favorite == true")
                    let results = try! self.context.mainContext.fetch(fetchRequest)
                    
                    let favoriteSongs = results.map { (savedSong) -> String? in
                        return savedSong.name
                        }.flatMap { $0 }
                    
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<SongInfo>(entityName: "SongInfo") as! NSFetchRequest<NSFetchRequestResult>)
                    let _ = try? self.context.mainContext.execute(deleteRequest)
                    try? self.context.mainContext.save()
                    
                    for song in fixedDatesTriples {
                        let newSong = try! SongInfo.newSong(name: song.2, initialDate: song.0, endDate: song.1, context: self.context.mainContext)
                        newSong.favorite = favoriteSongs.contains(song.2)
                    }
                    
                    try? self.context.mainContext.save()
                }
                
            } catch {
                print("Invalid regex")
            }
        }
        task.resume()
    }
}
