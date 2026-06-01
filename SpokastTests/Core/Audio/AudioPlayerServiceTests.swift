//
//  AudioPlayerServiceTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 27/04/26.
//

import Foundation
import XCTest
import Combine
@testable import Spokast

@MainActor
final class AudioPlayerServiceTests: XCTestCase {

    // MARK: - Properties
    private var sut: AudioPlayerService!
    private var mockPersistence: PlaybackPersistenceMock!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        sut = AudioPlayerService.shared
        mockPersistence = PlaybackPersistenceMock()
        sut.persistence = mockPersistence
        cancellables = []
    }

    override func tearDown() {
        sut.stop()
        mockPersistence.clear()
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_playURL_updatesStateToPlaying() throws {
        let testURL = try XCTUnwrap(URL(string: "https://test.com/audio.mp3"))
        sut.play(url: testURL)
        XCTAssertEqual(sut.playerStatePublisher.value, .playing(url: testURL))
    }

    func test_pause_updatesStateToPaused() throws {
        let testURL = try XCTUnwrap(URL(string: "https://test.com/audio.mp3"))
        sut.play(url: testURL)
        sut.pause()
        XCTAssertEqual(sut.playerStatePublisher.value, .paused(url: testURL))
    }

    func test_stop_updatesStateToStopped() throws {
        let testURL = try XCTUnwrap(URL(string: "https://test.com/audio.mp3"))
        sut.play(url: testURL)
        sut.stop()
        XCTAssertEqual(sut.playerStatePublisher.value, .stopped)
    }

    func test_toggle_whenPlaying_pausesAudio() throws {
        let testURL = try XCTUnwrap(URL(string: "https://test.com/audio.mp3"))
        sut.play(url: testURL)
        sut.toggle(url: testURL)
        XCTAssertEqual(sut.playerStatePublisher.value, .paused(url: testURL))
    }

    func test_toggle_whenPaused_resumesAudio() throws {
        let testURL = try XCTUnwrap(URL(string: "https://test.com/audio.mp3"))
        sut.play(url: testURL)
        sut.pause()
        sut.toggle(url: testURL)
        XCTAssertEqual(sut.playerStatePublisher.value, .playing(url: testURL))
    }

    func test_toggle_withDifferentURL_startsNewAudio() throws {
        let firstURL = try XCTUnwrap(URL(string: "https://test.com/audio1.mp3"))
        let secondURL = try XCTUnwrap(URL(string: "https://test.com/audio2.mp3"))
        sut.play(url: firstURL)
        sut.toggle(url: secondURL)
        XCTAssertEqual(sut.playerStatePublisher.value, .playing(url: secondURL))
    }

    func test_setPlaybackRate_updatesPublisher() {
        let expectedRate: Float = 1.5
        sut.setPlaybackRate(expectedRate)
        XCTAssertEqual(sut.playbackRatePublisher.value, expectedRate)
    }

    // MARK: - Integration Tests
    func test_playEpisode_whenStreamUrlExists_extractsUrlAndPlays() {
        let expectedUrl = "https://spokast.com/stream.mp3"

        let episode = Episode(
            trackId: 1,
            trackName: "Test Episode",
            description: "Desc",
            releaseDate: Date(),
            trackTimeMillis: nil,
            previewUrl: nil,
            episodeUrl: expectedUrl,
            artworkUrl160: nil,
            collectionName: "Collection",
            collectionId: 1,
            artworkUrl600: nil,
            artistName: "Artist"
        )

        let podcast = Podcast(
            trackId: nil,
            collectionId: 1,
            artistName: "Artist",
            collectionName: "Collection",
            artworkUrl100: nil,
            feedUrl: "feed",
            artworkUrl600: "https://image.com",
            primaryGenreName: "Tech"
        )

        sut.play(episode: episode, from: podcast)

        XCTAssertEqual(sut.currentEpisode?.trackId, 1)
        XCTAssertEqual(sut.currentPodcastImageURL?.absoluteString, "https://image.com")

        if case .playing(let playingUrl) = sut.playerStatePublisher.value {
            XCTAssertEqual(playingUrl.absoluteString, expectedUrl)
        } else {
            XCTFail("Player should be playing the stream URL")
        }
    }

    func test_saveCurrentState_whenConditionsAreMet_savesToCheckpoint() {
        let mockPersistence = PlaybackPersistenceMock()
        sut = AudioPlayerService()
        sut.persistence = mockPersistence 

        let expectedUrl = "https://spokast.com/stream.mp3"
        let episode = Episode(
            trackId: 1,
            trackName: "Test Episode",
            description: "Desc",
            releaseDate: Date(),
            trackTimeMillis: nil,
            previewUrl: nil,
            episodeUrl: expectedUrl,
            artworkUrl160: nil,
            collectionName: "Collection",
            collectionId: 1,
            artworkUrl600: nil,
            artistName: "Artist"
        )

        let podcast = Podcast(
            trackId: nil,
            collectionId: 1,
            artistName: "Artist",
            collectionName: "Collection",
            artworkUrl100: nil,
            feedUrl: "feed",
            artworkUrl600: "https://image.com",
            primaryGenreName: "Tech"
        )

        sut.play(episode: episode, from: podcast)
        sut.saveCurrentState()
        XCTAssertNil(mockPersistence.savedCheckpoint)
    }

    func test_restoreLastState_whenCheckpointExists_restoresEpisodeAndState() {
        let mockPersistence = PlaybackPersistenceMock()
        sut = AudioPlayerService()
        sut.persistence = mockPersistence

        let episode = Episode(
            trackId: 1,
            trackName: "Saved Episode",
            description: "Desc",
            releaseDate: Date(),
            trackTimeMillis: nil,
            previewUrl: "https://spokast.com/preview.mp3",
            episodeUrl: nil,
            artworkUrl160: nil,
            collectionName: "Collection",
            collectionId: 1,
            artworkUrl600: nil,
            artistName: "Artist"
        )

        let checkpoint = PlaybackCheckpoint(
            episode: episode,
            podcastTitle: "Saved Podcast",
            podcastArtWorkURL: URL(string: "https://image.com"),
            timestamp: 10.0,
            savedAt: Date()
        )
        mockPersistence.mockCheckpoint = checkpoint

        sut.restoreLastState()

        XCTAssertEqual(sut.currentEpisode?.trackName, "Saved Episode")
        XCTAssertEqual(sut.currentPodcastImageURL?.absoluteString, "https://image.com")

        if case .paused(let pausedUrl) = sut.playerStatePublisher.value {
            XCTAssertEqual(pausedUrl.absoluteString, "https://spokast.com/preview.mp3")
        } else {
            XCTFail("Player should be paused at the restored URL")
        }
    }
}
