//
//  EpisodeCellTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 03/05/26.
//

import Foundation
import XCTest
@testable import Spokast

final class EpisodeCellTests: XCTestCase {

    var sut: EpisodeCell!

    override func setUp() {
        super.setUp()
        sut = EpisodeCell(style: .default, reuseIdentifier: EpisodeCell.reuseIdentifier)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_configure_withShortDurationAndNotPlayed_setsUI() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let episode = Episode(
            trackId: 1,
            trackName: "Short Ep",
            description: nil,
            releaseDate: date,
            trackTimeMillis: 1800000,
            previewUrl: nil,
            episodeUrl: nil,
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 1,
            artworkUrl600: "https://episode.com/image.jpg",
            artistName: nil
        )

        sut.configure(
            with: episode,
            downloadStatus: .notDownloaded,
            podcastArtURL: URL(string: "https://pod.com/image.jpg"),
            isPlaying: true,
            isPlayed: false
        )

        let (titleLabel, descriptionLabel) = extractLabels(from: sut)

        XCTAssertEqual(titleLabel?.text, "Short Ep")
        XCTAssertTrue(descriptionLabel?.text?.contains("30 min") ?? false)
        XCTAssertEqual(sut.contentView.alpha, 1.0)
        XCTAssertEqual(sut.accessoryType, .none)
    }

    func test_configure_withLongDurationAndPlayed_setsUI() {
        let episode = Episode(
            trackId: 2,
            trackName: "Long Ep",
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: 4500000,
            previewUrl: nil,
            episodeUrl: nil,
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 1,
            artworkUrl600: nil,
            artistName: nil
        )

        sut.configure(
            with: episode,
            downloadStatus: .notDownloaded,
            podcastArtURL: URL(string: "https://pod.com/fallback.jpg"),
            isPlaying: false,
            isPlayed: true
        )

        let (_, descriptionLabel) = extractLabels(from: sut)

        XCTAssertTrue(descriptionLabel?.text?.contains("1h 15m") ?? false)
        XCTAssertEqual(sut.contentView.alpha, 0.5)
        XCTAssertEqual(sut.accessoryType, .checkmark)
    }

    func test_configure_withNilDuration_showsFallbackText() {
        let episode = Episode(
            trackId: 3,
            trackName: "Nil Ep",
            description: nil,
            releaseDate: Date(),
            trackTimeMillis: nil,
            previewUrl: nil,
            episodeUrl: nil,
            artworkUrl160: nil,
            collectionName: nil,
            collectionId: 1,
            artworkUrl600: nil,
            artistName: nil
        )

        sut.configure(
            with: episode,
            downloadStatus: .notDownloaded,
            podcastArtURL: nil,
            isPlaying: false,
            isPlayed: false
        )

        let (_, descriptionLabel) = extractLabels(from: sut)
        XCTAssertTrue(descriptionLabel?.text?.contains("-- min") ?? false)
    }

    func test_prepareForReuse_clearsData() {
        sut.didTapDownloadAction = {}
        sut.onPlayTap = {}
        sut.prepareForReuse()

        XCTAssertNil(sut.didTapDownloadAction)
        let (titleLabel, descriptionLabel) = extractLabels(from: sut)
        XCTAssertNil(titleLabel?.text)
        XCTAssertNil(descriptionLabel?.text)
    }

    func test_actions_triggerClosures() {
        var downloadTapped = false
        var playTapped = false

        sut.didTapDownloadAction = { downloadTapped = true }
        sut.onPlayTap = { playTapped = true }
        sut.downloadButton.sendActions(for: .touchUpInside)
        sut.perform(NSSelectorFromString("didTapPlayContainer"))

        XCTAssertTrue(downloadTapped)
        XCTAssertTrue(playTapped)
    }

    // MARK: - Helpers
    private func extractLabels(from cell: EpisodeCell) -> (title: UILabel?, description: UILabel?) {
        guard let stackView = cell.contentView.subviews.compactMap({ $0 as? UIStackView }).first else {
            return (nil, nil)
        }

        let labels = stackView.arrangedSubviews.compactMap { $0 as? UILabel }
        let titleLabel = labels.first
        let descriptionLabel = labels.dropFirst().first

        return (titleLabel, descriptionLabel)
    }
}
