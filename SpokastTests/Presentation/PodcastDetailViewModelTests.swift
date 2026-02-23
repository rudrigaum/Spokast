//
//  PodcastDetailViewModelTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 19/02/26.
//

import Foundation
import XCTest
import Combine
@testable import Spokast

@MainActor
final class PodcastDetailViewModelTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper
    private func makeSUT(episodes: [Episode]) -> PodcastDetailViewModel {
        let podcast = Podcast(trackId: 1, collectionId: 1, artistName: "Test", collectionName: "Test Pod", artworkUrl100: "", feedUrl: nil, artworkUrl600: nil, primaryGenreName: nil)
        
        let sut = PodcastDetailViewModel(
            podcast: podcast,
            repository: MockPodcastRepository(episodes: episodes),
            favoritesRepository: MockFavoritesRepository(),
            libraryService: MockLibraryService(),
            audioPlayerService: MockAudioPlayerService(),
            downloadService: MockDownloadService()
        )
        return sut
    }
    
    // MARK: - Tests
    func test_updateSorting_shouldReorderEpisodesByDuration() async {
        let epShort = createEpisode(id: 1, duration: 60)
        let epLong = createEpisode(id: 2, duration: 3600)
        let sut = makeSUT(episodes: [epLong, epShort])
        
        sut.fetchEpisodes()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        sut.updateSorting(.durationShortest)
        
        try? await Task.sleep(nanoseconds: 500_000_000)     
        
        XCTAssertEqual(sut.episodes.first?.id, epShort.id, "The shortest episode should be the first in the list.")
        XCTAssertEqual(sut.episodes.last?.id, epLong.id, "The longest episode should be the last.")
    }
    
    func test_updateSorting_shouldReorderEpisodesByTitle() async {
        let epZ = createEpisode(id: 1, title: "Zebra")
        let epA = createEpisode(id: 2, title: "Apple")
        let sut = makeSUT(episodes: [epZ, epA])
        
        sut.fetchEpisodes()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        sut.updateSorting(.titleAZ)
    
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertEqual(sut.episodes.first?.trackName, "Apple", "Alphabetical sorting (A-Z) failed.")
    }
    
    // MARK: - Factory Methods
    private func createEpisode(id: Int, title: String = "Test", duration: Double = 100) -> Episode {
        return Episode(
            trackId: id,
            trackName: title,
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: Int(duration * 1000),
            previewUrl: nil,
            episodeUrl: nil,
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 0,
            artworkUrl600: nil,
            artistName: nil
        )
    }
}
