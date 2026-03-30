//
//  ProfileViewModelTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 26/03/26.
//

import Foundation
import XCTest
import Combine
@testable import Spokast

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private var mockAuthService: AuthServiceMock!
    private var mockImportService: OPMLImportServiceMock!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAuthService = AuthServiceMock()
        mockImportService = OPMLImportServiceMock()
        cancellables = []
    }

    override func tearDown() {
        mockAuthService = nil
        mockImportService = nil
        cancellables = nil
        super.tearDown()
    }

    private func makeSUT() -> ProfileViewModel {
        return ProfileViewModel(authService: mockAuthService, importService: mockImportService)
    }

    // MARK: - Init & checkAuthStatus Tests
    func test_init_whenUserIsAuthenticated_setsStateToAuthenticated() {
        let expectation = XCTestExpectation(description: "State changes to authenticated")
        let expectedUser = UserProfile(id: "1", email: "test@spokast.com", displayName: "Test", photoURL: nil)

        mockAuthService.stubbedGetCurrentUserResult = .success(expectedUser)
        let sut = makeSUT()

        sut.$state
            .dropFirst()
            .sink { state in
                if case .authenticated(let user, _) = state, user.id == expectedUser.id {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAuthService.invokedGetCurrentUser)
    }

    func test_init_whenAuthServiceThrows_setsStateToError() {
        let expectation = XCTestExpectation(description: "State changes to error")
        mockAuthService.stubbedGetCurrentUserResult = .failure(NSError(domain: "test", code: 1))

        let sut = makeSUT()

        sut.$state
            .dropFirst()
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - handleAccountAction Tests

    func test_handleAccountAction_whenUnauthenticated_callsOnLoginRequest() {
        mockAuthService.stubbedGetCurrentUserResult = .success(nil)
        let sut = makeSUT()

        let expectation = XCTestExpectation(description: "onLoginRequest called")
        sut.onLoginRequest = { isSignUp in
            XCTAssertTrue(isSignUp)
            expectation.fulfill()
        }

        let dispatchExpectation = XCTestExpectation(description: "Wait for state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sut.handleAccountAction(isSignUp: true)
            dispatchExpectation.fulfill()
        }

        wait(for: [expectation, dispatchExpectation], timeout: 1.0)
    }

    // MARK: - Logout Tests
    func test_logout_success_setsStateToUnauthenticated() {
        let expectation = XCTestExpectation(description: "State changes to unauthenticated")
        mockAuthService.stubbedGetCurrentUserResult = .success(UserProfile(id: "1", email: "test@test.com"))
        let sut = makeSUT()

        sut.$state
            .dropFirst(2)
            .sink { state in
                if case .unauthenticated = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.logout()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAuthService.invokedSignOut)
    }

    // MARK: - OPML Import Tests
    func test_importOPML_success_updatesStateWithSuccessMessage() {
        let expectation = XCTestExpectation(description: "State changes to authenticated with message")
        let expectedUser = UserProfile(id: "1", email: "test@spokast.com")
        mockAuthService.stubbedGetCurrentUserResult = .success(expectedUser)
        mockImportService.stubbedImportOPMLResult = .success(5)

        let sut = makeSUT()
        let url = URL(string: "file://test.opml")!
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sut.$state
                .dropFirst()
                .sink { state in
                    if case .authenticated(_, let message) = state, message == "Successfully imported 5 podcasts." {
                        expectation.fulfill()
                    }
                }
                .store(in: &self.cancellables)

            sut.importOPML(from: url)
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockImportService.invokedImportOPML)
        XCTAssertEqual(mockImportService.importOPMLURL, url)
    }
}
