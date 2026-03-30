//
//  AuthUseCaseMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 24/03/26.
//

import Foundation
@testable import Spokast

final class AuthUseCaseMock: AuthUseCaseProtocol {

    // MARK: - Call Trackers & Stubs for SignIn
    private(set) var invokedSignIn = false
    private(set) var signInParameters: (email: String, password: String)?
    var stubbedSignInResult: Result<UserProfile, Error>!

    func signIn(email: String, password: String) async throws -> UserProfile {
        invokedSignIn = true
        signInParameters = (email, password)
        return try stubbedSignInResult.get()
    }

    // MARK: - Call Trackers & Stubs for SignUp
    private(set) var invokedSignUp = false
    private(set) var signUpParameters: (email: String, password: String)?
    var stubbedSignUpResult: Result<UserProfile, Error>!

    func signUp(email: String, password: String) async throws -> UserProfile {
        invokedSignUp = true
        signUpParameters = (email, password)
        return try stubbedSignUpResult.get()
    }
}
