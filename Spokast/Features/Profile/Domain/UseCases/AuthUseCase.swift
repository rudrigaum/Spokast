//
//  AuthUseCase.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/02/26.
//

import Foundation

// MARK: - Protocol
protocol AuthUseCaseProtocol {
    func signIn(email: String, password: String) async throws -> UserProfile
    func signUp(email: String, password: String) async throws -> UserProfile
}

// MARK: - Errors
enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case emptyFields

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email format or password must be at least 6 characters."
        case .emptyFields:
            return "Please fill in all fields."
        }
    }
}

// MARK: - UseCase
final class AuthUseCase: AuthUseCaseProtocol {
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func signIn(email: String, password: String) async throws -> UserProfile {
        try validate(email: email, password: password)
        return try await authService.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> UserProfile {
        try validate(email: email, password: password)
        return try await authService.signUp(email: email, password: password)
    }

    private func validate(email: String, password: String) throws {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.emptyFields
        }

        guard email.contains("@"), password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
    }
}
