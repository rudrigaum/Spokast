//
//  FavoriteCellTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 03/05/26.
//

import XCTest
@testable import Spokast

final class FavoriteCellTests: XCTestCase {

    var sut: FavoriteCell!

    override func setUp() {
        super.setUp()
        sut = FavoriteCell(style: .default, reuseIdentifier: FavoriteCell.reuseIdentifier)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_configure_withValidArtworkUrl_setsLabelsAndImage() {
        let expectedTitle = "NerdCast"
        let expectedAuthor = "Jovem Nerd"
        let podcast = SavedPodcast(
            collectionId: 100,
            artistName: expectedAuthor,
            collectionName: expectedTitle,
            feedUrl: "https://feed.com",
            artworkUrl600: "https://image.com/cover.jpg"
        )

        sut.configure(with: podcast)

        let (titleLabel, authorLabel) = extractLabels(from: sut)

        XCTAssertEqual(titleLabel?.text, expectedTitle)
        XCTAssertEqual(authorLabel?.text, expectedAuthor)
    }

    func test_configure_withoutArtworkUrl_setsFallbackImage() {
        let podcast = SavedPodcast(
            collectionId: 101,
            artistName: "No Image Artist",
            collectionName: "No Image Podcast",
            feedUrl: "https://feed.com",
            artworkUrl600: nil
        )

        sut.configure(with: podcast)
        let (titleLabel, authorLabel) = extractLabels(from: sut)

        XCTAssertEqual(titleLabel?.text, "No Image Podcast")
        XCTAssertEqual(authorLabel?.text, "No Image Artist")
    }

    func test_prepareForReuse_clearsData() {
        let podcast = SavedPodcast(
            collectionId: 102,
            artistName: "Artist",
            collectionName: "Podcast",
            feedUrl: "https://feed.com",
            artworkUrl600: nil
        )
        sut.configure(with: podcast)
        sut.prepareForReuse()
        let (titleLabel, authorLabel) = extractLabels(from: sut)

        XCTAssertNil(titleLabel?.text)
        XCTAssertNil(authorLabel?.text)
    }

    // MARK: - Helpers
    private func extractLabels(from cell: FavoriteCell) -> (title: UILabel?, author: UILabel?) {
        guard let stackView = cell.contentView.subviews.compactMap({ $0 as? UIStackView }).first else {
            return (nil, nil)
        }

        let labels = stackView.arrangedSubviews.compactMap { $0 as? UILabel }
        let titleLabel = labels.first
        let authorLabel = labels.dropFirst().first

        return (titleLabel, authorLabel)
    }
}
