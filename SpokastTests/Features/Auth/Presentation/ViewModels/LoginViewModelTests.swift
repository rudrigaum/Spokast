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

    // MARK: - Properties
    private var sut: LoginViewModel!
    private var mockAuthService: AuthServiceMock!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockAuthService = AuthServiceMock()
        sut = LoginViewModel(authService: mockAuthService)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Tests: AuthMode & Validation
    func test_toggleAuthMode_switchesModeAndClearsError() {
        sut.authMode = .signIn
        sut.errorMessage = "Previous error"
        sut.toggleAuthMode()

        XCTAssertEqual(sut.authMode, .signUp)
        XCTAssertNil(sut.errorMessage)
    }

    func test_submit_withEmptyFields_failsValidationAndSetsError() {
        sut.email = ""
        sut.password = ""
        sut.submit()

        XCTAssertEqual(sut.errorMessage, "Please fill in all fields.")
        XCTAssertFalse(mockAuthService.invokedSignIn)
        XCTAssertFalse(mockAuthService.invokedSignUp)
    }

    func test_submit_withShortPassword_failsValidationAndSetsError() {
        sut.email = "test@domain.com"
        sut.password = "12345"
        sut.submit()

        XCTAssertEqual(sut.errorMessage, "Password must be at least 6 characters long.")
        XCTAssertFalse(mockAuthService.invokedSignIn)
    }

    // MARK: - Tests: Submit Success
    func test_submit_signInSuccess_callsAuthServiceAndTriggersOnSuccess() {
        let expectation = XCTestExpectation(description: "onSuccess closure called")
        sut.email = "test@domain.com"
        sut.password = "123456"
        sut.authMode = .signIn

        let fakeUser = UserProfile(id: "123", email: "test@domain.com")
        mockAuthService.stubbedSignInResult = .success(fakeUser)

        sut.onSuccess = {
            expectation.fulfill()
        }

        sut.submit()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAuthService.invokedSignIn)
        XCTAssertEqual(mockAuthService.signInParameters?.email, "test@domain.com")
        XCTAssertEqual(mockAuthService.signInParameters?.password, "123456")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func test_submit_signUpSuccess_callsAuthServiceAndTriggersOnSuccess() {
        let expectation = XCTestExpectation(description: "onSuccess closure called")
        sut.email = "new@domain.com"
        sut.password = "password123"
        sut.authMode = .signUp

        let fakeUser = UserProfile(id: "123", email: "new@domain.com")
        mockAuthService.stubbedSignUpResult = .success(fakeUser)

        sut.onSuccess = {
            expectation.fulfill()
        }

        sut.submit()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockAuthService.invokedSignUp)
        XCTAssertEqual(mockAuthService.signUpParameters?.email, "new@domain.com")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Tests: Submit Failure
    func test_submit_failure_setsErrorMessageAndStopsLoading() {
        let expectation = XCTestExpectation(description: "Error message is updated")
        sut.email = "test@domain.com"
        sut.password = "wrongpass"
        sut.authMode = .signIn

        let expectedError = NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials."])
        mockAuthService.stubbedSignInResult = .failure(expectedError)

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
        XCTAssertTrue(mockAuthService.invokedSignIn)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Invalid credentials.")
    }
}
