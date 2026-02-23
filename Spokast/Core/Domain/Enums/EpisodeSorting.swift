//
//  EpisodeSorting.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 16/02/26.
//

import Foundation

enum EpisodeSorting: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case downloadDate = "Download Date"
    case durationShortest = "Duration (Shortest)"
    case durationLongest = "Duration (Longest)"
    case timeRemaining = "Time Remaining"
    case fileSize = "File Size"
    case titleAZ = "Title (A-Z)"
    case titleZA = "Title (Z-A)"
    case ratingHigh = "Rating (Highest)"
    
    var id: String { rawValue }
    
    var comparator: (Episode, Episode) -> Bool {
        switch self {
        case .dateNewest:
            return { $0.releaseDate > $1.releaseDate }
        case .dateOldest:
            return { $0.releaseDate < $1.releaseDate }
            
        case .downloadDate:
            return { lhs, rhs in
                guard let lhsDate = lhs.downloadDate, let rhsDate = rhs.downloadDate else {
                    return lhs.downloadDate != nil
                }
                return lhsDate > rhsDate
            }
            
        case .durationShortest:
            return { $0.durationInSeconds < $1.durationInSeconds }
        case .durationLongest:
            return { $0.durationInSeconds > $1.durationInSeconds }
            
        case .timeRemaining:
            return { $0.timeRemaining < $1.timeRemaining }
            
        case .fileSize:
            return { ($0.fileSize ?? 0) > ($1.fileSize ?? 0) }
            
        case .titleAZ:
            return { $0.trackName.localizedCaseInsensitiveCompare($1.trackName) == .orderedAscending }
        case .titleZA:
            return { $0.trackName.localizedCaseInsensitiveCompare($1.trackName) == .orderedDescending }
            
        case .ratingHigh:
            return { $0.rating > $1.rating }
        }
    }
}
