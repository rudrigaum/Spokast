//
//  LoginViewModelTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 21/03/26.
//

import Foundation
import XCTest
import Combine
@testable import Spokast

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var sut: LoginViewModel!
    private var mockUseCase: AuthUseCaseMock! 
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockUseCase = AuthUseCaseMock()
        sut = LoginViewModel(authUseCase: mockUseCase)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockUseCase = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Tests: UI State

    func test_toggleAuthMode_switchesModeAndClearsError() {
        sut.authMode = .signIn
        sut.errorMessage = "Previous error"

        sut.toggleAuthMode()

        XCTAssertEqual(sut.authMode, .signUp)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Tests: Submit Success

    func test_submit_signInSuccess_stopsLoadingAndTriggersOnSuccess() {
        let expectation = XCTestExpectation(description: "onSuccess closure called")
        sut.email = "test@domain.com"
        sut.password = "123456"
        sut.authMode = .signIn

        let fakeUser = UserProfile(id: "123", email: "test@domain.com", displayName: "Test", photoURL: nil)
        mockUseCase.stubbedSignInResult = .success(fakeUser)

        sut.onSuccess = {
            expectation.fulfill()
        }

        sut.submit()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockUseCase.invokedSignIn)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Tests: Submit Failure

    func test_submit_failure_setsErrorMessageAndStopsLoading() {
        let expectation = XCTestExpectation(description: "Error message is updated")
        sut.authMode = .signIn

        let expectedError = NSError(
            domain: "AuthError",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "Invalid credentials."]
        )
        mockUseCase.stubbedSignInResult = .failure(expectedError)

        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage == "Invalid credentials." {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.submit()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Invalid credentials.")
    }
}
