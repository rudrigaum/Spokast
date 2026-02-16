//
//  EpisodeSortingTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 16/02/26.
//

import Foundation
import XCTest
@testable import Spokast

final class EpisodeSortingTests: XCTestCase {
    
    private func makeEpisode(
        id: Int = 1,
        title: String = "Test",
        date: Date = Date(),
        duration: Double = 100,
        downloadDate: Date? = nil,
        progress: Double = 0
    ) -> Episode {
        return Episode(
            trackId: id,
            trackName: title,
            description: nil,
            releaseDate: date,
            trackTimeMillis: Int(duration * 1000), 
            previewUrl: nil,
            episodeUrl: "http://test.com",
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 0,
            artworkUrl600: nil,
            artistName: nil,
            downloadDate: downloadDate,
            playbackProgress: progress
        )
    }
    
    func testSortByDateNewest() {
        let old = makeEpisode(date: Date().addingTimeInterval(-1000))
        let new = makeEpisode(date: Date())
        
        let sorted = [old, new].sorted(by: EpisodeSorting.dateNewest.comparator)
        
        XCTAssertEqual(sorted.first, new, "Should be ordered Newest -> Oldest")
    }
    
    func testSortByDownloadDate_PutsDownloadedFirst() {
        let notDownloaded = makeEpisode(downloadDate: nil)
        let downloaded = makeEpisode(downloadDate: Date())
        
        let sorted = [notDownloaded, downloaded].sorted(by: EpisodeSorting.downloadDate.comparator)
        
        XCTAssertEqual(sorted.first, downloaded, "Downloaded episodes should come first")
    }
    
    func testSortByTimeRemaining() {
        let epNearEnd = makeEpisode(duration: 100, progress: 90)
        let epNotStarted = makeEpisode(duration: 100, progress: 0)
        let sorted = [epNotStarted, epNearEnd].sorted(by: EpisodeSorting.timeRemaining.comparator)
        XCTAssertEqual(sorted.first, epNearEnd, "Episode with less time remaining should come first")
    }
    
    func testSortByTitle_IgnoresCase() {
        let epA = makeEpisode(title: "apple")
        let epB = makeEpisode(title: "Banana")
        
        let sorted = [epB, epA].sorted(by: EpisodeSorting.titleAZ.comparator)
        
        XCTAssertEqual(sorted.first, epA, "Apple comes before Banana")
    }
}
