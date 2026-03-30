//
//  AuthServiceMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 21/03/26.
//

import Foundation
@testable import Spokast

final class AuthServiceMock: AuthServiceProtocol {

    // MARK: - Call Trackers & Stubs for getCurrentUser
    private(set) var invokedGetCurrentUser = false
    private(set) var invokedGetCurrentUserCount = 0
    var stubbedGetCurrentUserResult: Result<UserProfile?, Error> = .success(nil)

    func getCurrentUser() async throws -> UserProfile? {
        invokedGetCurrentUser = true
        invokedGetCurrentUserCount += 1
        return try stubbedGetCurrentUserResult.get()
    }

    // MARK: - Call Trackers & Stubs for signIn
    private(set) var invokedSignIn = false
    private(set) var invokedSignInCount = 0
    private(set) var signInParameters: (email: String, password: String)?
    var stubbedSignInResult: Result<UserProfile, Error>!

    func signIn(email: String, password: String) async throws -> UserProfile {
        invokedSignIn = true
        invokedSignInCount += 1
        signInParameters = (email, password)
        return try stubbedSignInResult.get()
    }

    // MARK: - Call Trackers & Stubs for signUp
    private(set) var invokedSignUp = false
    private(set) var invokedSignUpCount = 0
    private(set) var signUpParameters: (email: String, password: String)?
    var stubbedSignUpResult: Result<UserProfile, Error>!

    func signUp(email: String, password: String) async throws -> UserProfile {
        invokedSignUp = true
        invokedSignUpCount += 1
        signUpParameters = (email, password)
        return try stubbedSignUpResult.get()
    }

    // MARK: - Call Trackers & Stubs for signOut
    private(set) var invokedSignOut = false
    private(set) var invokedSignOutCount = 0
    var stubbedSignOutError: Error?

    func signOut() async throws {
        invokedSignOut = true
        invokedSignOutCount += 1
        if let error = stubbedSignOutError {
            throw error
        }
    }
}
