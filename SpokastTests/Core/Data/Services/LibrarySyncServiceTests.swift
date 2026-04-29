//
//  LibrarySyncServiceTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 28/04/26.
//

import Foundation
import XCTest
import SwiftData
@testable import Spokast

@MainActor
final class LibrarySyncServiceTests: XCTestCase {

    private var sut: LibrarySyncService!
    private var mockPodcastService: PodcastServiceMock!
    private var modelContainer: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        super.setUp()

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: SavedPodcast.self, configurations: config)
        context = modelContainer.mainContext

        mockPodcastService = PodcastServiceMock()
        sut = LibrarySyncService(context: context, podcastService: mockPodcastService)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockPodcastService = nil
        modelContainer = nil
        context = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_syncMissingMetadata_whenNoPodcastsAreMissingArtwork_returnsZero() async throws {
        let completePodcast = SavedPodcast(
            collectionId: 1,
            artistName: "Artista Completo",
            collectionName: "Completo",
            feedUrl: "url",
            artworkUrl600: "https://image.com"
        )

        context.insert(completePodcast)
        try context.save()

        let updatedCount = try await sut.syncMissingMetadata()
        XCTAssertEqual(updatedCount, 0)
    }

    func test_syncMissingMetadata_whenApiSucceedsByURL_updatesPodcast() async throws {
        let incompletePodcast = SavedPodcast(
            collectionId: 2,
            artistName: "Artista Incompleto",
            collectionName: "Incompleto",
            feedUrl: "https://feed.com",
            artworkUrl600: nil
        )

        context.insert(incompletePodcast)
        try context.save()

        let remotePodcast = Podcast(
            trackId: nil,
            collectionId: 2,
            artistName: "Artista",
            collectionName: "Novo Titulo",
            artworkUrl100: nil,
            feedUrl: "https://feed.com",
            artworkUrl600: "https://nova-image.com",
            primaryGenreName: "Tech"
        )

        mockPodcastService.podcastToReturnFromURL = remotePodcast

        let updatedCount = try await sut.syncMissingMetadata()
        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(incompletePodcast.artworkUrl600, "https://nova-image.com")
        XCTAssertEqual(incompletePodcast.artistName, "Artista")
    }

    func test_syncMissingMetadata_whenApiFailsURLButSucceedsSearch_updatesPodcast() async throws {
        let incompletePodcast = SavedPodcast(
            collectionId: 3,
            artistName: "Artista Busca",
            collectionName: "Busca Podcast",
            feedUrl: "https://broken-feed.com",
            artworkUrl600: nil
        )
        context.insert(incompletePodcast)
        try context.save()

        let remotePodcast = Podcast(
            trackId: nil,
            collectionId: 3,
            artistName: "Artista",
            collectionName: "Novo Titulo",
            artworkUrl100: nil,
            feedUrl: "https://feed.com",
            artworkUrl600: "https://nova-image.com",
            primaryGenreName: "Tech"
        )

        mockPodcastService.shouldThrowError = false
        mockPodcastService.podcastToReturnFromURL = nil // Força a falha pela URL
        mockPodcastService.podcastsToReturnFromSearch = [remotePodcast] // Sucesso na busca

        let updatedCount = try await sut.syncMissingMetadata()

        XCTAssertEqual(updatedCount, 1)
        XCTAssertEqual(incompletePodcast.artworkUrl600, "https://busca-image.com")
    }
}
