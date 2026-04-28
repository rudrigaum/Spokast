//
//  AudioPlayerServiceTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 27/04/26.
//

import Foundation
//
//  AudioPlayerServiceTests.swift
//  SpokastTests
//

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
}
