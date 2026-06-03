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
            progress: Double = 0,
            fileSize: Int64? = nil,
            rating: Int = 0
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
                fileSize: fileSize,
                playbackProgress: progress,
                rating: rating
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
    
    // MARK: - Episode Sorting Domain Tests
    func test_sorting_dateNewestAndOldest() {
        let oldDate = Date().addingTimeInterval(-86400)
        let newDate = Date()
        
        let oldEp = makeEpisode(id: 1, date: oldDate)
        let newEp = makeEpisode(id: 2, date: newDate)
        
        XCTAssertTrue(EpisodeSorting.dateNewest.comparator(newEp, oldEp), "Date Newest failed")
        XCTAssertTrue(EpisodeSorting.dateOldest.comparator(oldEp, newEp), "Date Oldest failed")
    }
    
    func test_sorting_downloadDate() {
        let oldDownload = Date().addingTimeInterval(-3600)
        let newDownload = Date()

        let ep1 = makeEpisode(id: 1, downloadDate: oldDownload)
        let ep2 = makeEpisode(id: 2, downloadDate: newDownload)
        let epSemDownload = makeEpisode(id: 3, downloadDate: nil)

        XCTAssertTrue(
            EpisodeSorting.downloadDate.comparator(ep2, ep1),
            "Download Date failed to prioritize newer"
        )
        XCTAssertTrue(
            EpisodeSorting.downloadDate.comparator(ep1, epSemDownload),
            "Download Date failed to prioritize downloaded"
        )
    }
    
    func test_sorting_durationLongestAndShortest() {
        let shortEp = makeEpisode(id: 1, duration: 60)
        let longEp = makeEpisode(id: 2, duration: 3600)
        
        XCTAssertTrue(EpisodeSorting.durationLongest.comparator(longEp, shortEp), "Duration Longest failed")
        XCTAssertTrue(EpisodeSorting.durationShortest.comparator(shortEp, longEp), "Duration Shortest failed")
    }
    
    func test_sorting_timeRemaining() {
        let lessTimeEp = makeEpisode(id: 1, duration: 100, progress: 90)
        let moreTimeEp = makeEpisode(id: 2, duration: 100, progress: 10)
        
        XCTAssertTrue(EpisodeSorting.timeRemaining.comparator(lessTimeEp, moreTimeEp), "Time Remaining failed")
    }
    
    func test_sorting_fileSize() {
        let smallEp = makeEpisode(id: 1, fileSize: 1024)
        let largeEp = makeEpisode(id: 2, fileSize: 5048)
        
        XCTAssertTrue(EpisodeSorting.fileSize.comparator(largeEp, smallEp), "File Size failed")
    }
    
    func test_sorting_titleAZandZA() {
        let epA = makeEpisode(id: 1, title: "Apple")
        let epZ = makeEpisode(id: 2, title: "Zebra")
        
        XCTAssertTrue(EpisodeSorting.titleAZ.comparator(epA, epZ), "Title A-Z failed")
        XCTAssertTrue(EpisodeSorting.titleZA.comparator(epZ, epA), "Title Z-A failed")
    }
    
    func test_sorting_ratingHigh() {
        let lowRatingEp = makeEpisode(id: 1, rating: 2)
        let highRatingEp = makeEpisode(id: 2, rating: 5)
        
        XCTAssertTrue(EpisodeSorting.ratingHigh.comparator(highRatingEp, lowRatingEp), "Rating High failed")
    }
}
