//
//  SearchViewModelTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 04/09/26.
//

import Foundation
import XCTest
import Combine
@testable import Spokast

@MainActor
final class SearchViewModelTests: XCTestCase {

    // MARK: - Properties
    private var serviceMock: PodcastServiceMock!
    private var sut: SearchViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()

        serviceMock = PodcastServiceMock()
        sut = SearchViewModel(service: serviceMock)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        serviceMock = nil

        super.tearDown()
    }

    // MARK: - Tests
    func test_initialState_whenViewModelIsCreated_thenStateIsIdleAndPodcastsAreEmpty() {
        XCTAssertTrue(sut.podcasts.isEmpty)

        guard case .idle = sut.state else {
            return XCTFail("Expected initial state to be idle.")
        }
    }

    func test_validQuery_whenSearchReturnsResults_thenStateIsSuccess() async {
        // Given
        let expectedPodcast = makePodcast(
            id: 1,
            name: "Swift by Sundell"
        )

        serviceMock.podcastsToReturnFromSearch = [
            expectedPodcast
        ]

        let expectation = expectation(
            description: "Wait for search success"
        )

        observeState {
            if case .success = $0 {
                expectation.fulfill()
            }
        }

        // When
        sut.executeSearch(for: "Swift")

        await fulfillment(
            of: [expectation],
            timeout: 1.0
        )

        // Then
        XCTAssertEqual(sut.podcasts.count, 1)
        XCTAssertEqual(sut.podcasts.first?.id, expectedPodcast.id)
        XCTAssertEqual(
            sut.podcasts.first?.collectionName,
            expectedPodcast.collectionName
        )

        guard case .success = sut.state else {
            return XCTFail("Expected state to be success.")
        }
    }

    func test_validQuery_whenSearchReturnsNoResults_thenStateIsEmpty() async {
        // Given
        serviceMock.podcastsToReturnFromSearch = []

        let expectation = expectation(
            description: "Wait for empty state"
        )

        observeState {
            if case .empty = $0 {
                expectation.fulfill()
            }
        }

        // When
        sut.executeSearch(for: "Unknown Podcast")

        await fulfillment(
            of: [expectation],
            timeout: 1.0
        )

        // Then
        XCTAssertTrue(sut.podcasts.isEmpty)

        guard case .empty = sut.state else {
            return XCTFail("Expected state to be empty.")
        }
    }

    func test_validQuery_whenServiceThrowsError_thenStateIsErrorAndPodcastsAreEmpty() async {
        // Given
        serviceMock.shouldThrowError = true

        let expectation = expectation(
            description: "Wait for error state"
        )

        observeState {
            if case .error = $0 {
                expectation.fulfill()
            }
        }

        // When
        sut.executeSearch(for: "Swift")

        await fulfillment(
            of: [expectation],
            timeout: 1.0
        )

        // Then
        XCTAssertTrue(sut.podcasts.isEmpty)

        guard case .error = sut.state else {
            return XCTFail("Expected state to be error.")
        }
    }

    func test_emptyQuery_whenSearchExecutes_thenStateResetsToIdle() async {
        // Given
        serviceMock.podcastsToReturnFromSearch = [
            makePodcast(
                id: 1,
                name: "Swift Podcast"
            )
        ]

        let successExpectation = expectation(
            description: "Wait for initial search"
        )

        observeState {
            if case .success = $0 {
                successExpectation.fulfill()
            }
        }

        sut.executeSearch(for: "Swift")

        await fulfillment(
            of: [successExpectation],
            timeout: 1.0
        )

        // When
        sut.executeSearch(for: "   ")

        // Then
        XCTAssertTrue(sut.podcasts.isEmpty)

        guard case .idle = sut.state else {
            return XCTFail("Expected state to reset to idle.")
        }
    }

    func test_resetSearch_whenRequestIsRunning_thenLateResponseIsIgnored() async {
        // Given
        let stalePodcast = makePodcast(
            id: 1,
            name: "Stale Result"
        )

        serviceMock.fetchPodcastsHandler = { _, _ in
            try? await Task.sleep(
                nanoseconds: 200_000_000
            )

            return [stalePodcast]
        }

        sut.executeSearch(for: "Swift")

        // When
        sut.resetSearch()

        try? await Task.sleep(
            nanoseconds: 300_000_000
        )

        // Then
        XCTAssertTrue(sut.podcasts.isEmpty)

        guard case .idle = sut.state else {
            return XCTFail(
                "Expected reset state to remain idle after the cancelled request finishes."
            )
        }
    }

    func test_newSearch_whenPreviousRequestIsRunning_thenOnlyLatestResultIsPublished() async {
        // Given
        let stalePodcast = makePodcast(
            id: 1,
            name: "Old Result"
        )

        let latestPodcast = makePodcast(
            id: 2,
            name: "Latest Result"
        )

        serviceMock.fetchPodcastsHandler = { term, _ in
            if term == "old" {
                try? await Task.sleep(
                    nanoseconds: 300_000_000
                )

                return [stalePodcast]
            }

            return [latestPodcast]
        }

        let successExpectation = expectation(
            description: "Wait for latest search"
        )

        observeState {
            if case .success = $0 {
                successExpectation.fulfill()
            }
        }

        // When
        sut.executeSearch(for: "old")
        sut.executeSearch(for: "new")

        await fulfillment(
            of: [successExpectation],
            timeout: 1.0
        )

        try? await Task.sleep(
            nanoseconds: 400_000_000
        )

        // Then
        XCTAssertEqual(sut.podcasts.count, 1)
        XCTAssertEqual(
            sut.podcasts.first?.id,
            latestPodcast.id
        )

        XCTAssertEqual(
            sut.podcasts.first?.collectionName,
            "Latest Result"
        )

        guard case .success = sut.state else {
            return XCTFail("Expected state to remain success.")
        }
    }

    // MARK: - Helpers

    private func observeState(
        _ handler: @escaping (SearchViewState) -> Void
    ) {
        sut.$state
            .dropFirst()
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }

    private func makePodcast(
        id: Int,
        name: String
    ) -> Podcast {
        Podcast(
            trackId: id,
            collectionId: id,
            artistName: "Test Artist",
            collectionName: name,
            artworkUrl100: nil,
            feedUrl: nil,
            artworkUrl600: nil,
            primaryGenreName: "Technology"
        )
    }
}
