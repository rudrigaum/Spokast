//
//  AuthUseCaseTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 24/03/26.
//

import Foundation
import XCTest
@testable import Spokast

final class AuthUseCaseTests: XCTestCase {

    // MARK: - Properties
    private var sut: AuthUseCase!
    private var mockAuthService: AuthServiceMock!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockAuthService = AuthServiceMock()
        sut = AuthUseCase(authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockAuthService = nil
        super.tearDown()
    }

    // MARK: - Tests: Validation Failures
    func test_execute_withEmptyEmail_throwsEmptyFieldsError() async {
        let emptyEmail = "   "
        let validPassword = "password123"

        do {
            _ = try await sut.signIn(email: emptyEmail, password: validPassword)
            XCTFail("Expected emptyFields error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emptyFields)
            XCTAssertEqual(error.errorDescription, "Please fill in all fields.")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertFalse(mockAuthService.invokedSignIn)
    }

    func test_execute_withEmptyPassword_throwsEmptyFieldsError() async {
        let validEmail = "test@domain.com"
        let emptyPassword = ""

        do {
            _ = try await sut.signIn(email: validEmail, password: emptyPassword)
            XCTFail("Expected emptyFields error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emptyFields)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertFalse(mockAuthService.invokedSignIn)
    }

    func test_execute_withInvalidEmailFormat_throwsInvalidCredentialsError() async {
        let invalidEmail = "testdomain.com"
        let validPassword = "password123"

        do {
            _ = try await sut.signIn(email: invalidEmail, password: validPassword)
            XCTFail("Expected invalidCredentials error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertFalse(mockAuthService.invokedSignIn)
    }

    func test_execute_withShortPassword_throwsInvalidCredentialsError() async {
        let validEmail = "test@domain.com"
        let shortPassword = "12345"

        do {
            _ = try await sut.signIn(email: validEmail, password: shortPassword)
            XCTFail("Expected invalidCredentials error, but succeeded.")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertFalse(mockAuthService.invokedSignIn)
    }

    // MARK: - Tests: Success
    func test_signIn_withValidCredentials_callsAuthServiceAndReturnsUser() async throws {
        let validEmail = "test@domain.com"
        let validPassword = "password123"
        let expectedUser = UserProfile(id: "123", email: validEmail, displayName: "Spokast User", photoURL: nil)
        mockAuthService.stubbedSignInResult = .success(expectedUser)

        let returnedUser = try await sut.signIn(email: validEmail, password: validPassword)

        XCTAssertTrue(mockAuthService.invokedSignIn)
        XCTAssertEqual(mockAuthService.signInParameters?.email, validEmail)
        XCTAssertEqual(mockAuthService.signInParameters?.password, validPassword)

        XCTAssertEqual(returnedUser.id, expectedUser.id)
        XCTAssertEqual(returnedUser.email, expectedUser.email)
    }
}
