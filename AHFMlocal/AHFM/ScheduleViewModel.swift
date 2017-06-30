//
//  Parser.swift
//  AHFM
//
//  Created by Marilyn on 6/13/17.
//  Copyright © 2017 Marilyn. All rights reserved.
//

import Foundation

struct ParsedSong {
    let beginsAt: Date
    let endsAt: Date
    let name: String
}

class ScheduleViewModel {
    
    enum DownloadStatus {
        case success(String)
        case failureNetworkError(NSError)
        case failureDataIsNil
        case failureDataIsNotString
    }
    
    class func download(_ url: URL, completion: @escaping (DownloadStatus) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { (possibleData, possibleResponse, possibleError) in
            
            guard possibleError == nil else {
                DispatchQueue.main.async {
                    completion(.failureNetworkError(possibleError! as NSError))
                }
                return
            }
            
            guard let data = possibleData else {
                DispatchQueue.main.async {
                    completion(.failureDataIsNil)
                }
                return
            }
            
            guard let parsedString = String(data: data, encoding: String.Encoding.utf8) else {
                DispatchQueue.main.async {
                    completion(.failureDataIsNotString)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(parsedString))
            }
        }
        
        task.resume()
    }
    
    class func parse(schedule: NSString) throws -> [ParsedSong] {
        
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
        
        let hourTriple = hourMatches.map { hourMatchRange -> ParsedSong in
            
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
            
            return ParsedSong(beginsAt: formattedInitialDate,
                              endsAt: formattedEndDate,
                              name: setName)
        }
        
        var incrementedEndDate: Date?
        let fixedDatesTriples = hourTriple.map { triple -> ParsedSong in
            // In the case where the initial date is higher than the end date, for example:
            // 23:00-00:00
            guard triple.beginsAt < triple.endsAt else {
                // The end date must be fixed, so a day is added to it.
                let fixedEndDate = triple.endsAt.addingTimeInterval(86400)
                incrementedEndDate = fixedEndDate
                return ParsedSong(beginsAt: triple.beginsAt,
                                  endsAt: fixedEndDate,
                                  name: triple.name)
            }
            // If it is lower, no change is made.
            guard let existingEndDate = incrementedEndDate else {
                incrementedEndDate = triple.endsAt
                return triple
            }
            // If the initialDate is lower than the end date
            guard triple.beginsAt >= existingEndDate else {
                // The initial date must be fixed by adding a day to it
                let fixedInitialDate = triple.beginsAt.addingTimeInterval(86400)
                // If the corrected initial date is higher than the end date
                guard fixedInitialDate < triple.endsAt else {
                    // The end date must be fixed by adding a day to it.
                    let fixedEndDate = triple.endsAt.addingTimeInterval(86400)
                    incrementedEndDate = fixedEndDate
                    
                    return ParsedSong(beginsAt: fixedInitialDate,
                                      endsAt: fixedEndDate,
                                      name: triple.name)
                }
                // If the initial date is lower, a day is added to the initial date
                incrementedEndDate = triple.endsAt
                return ParsedSong(beginsAt: fixedInitialDate,
                                  endsAt: triple.endsAt,
                                  name: triple.name)
            }
            // If the initial date is lower, no change is made
            incrementedEndDate = triple.endsAt
            
            return triple
        }
        
        return fixedDatesTriples
    }
}
