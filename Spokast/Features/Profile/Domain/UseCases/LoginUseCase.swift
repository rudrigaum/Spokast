//
//  LoginUseCase.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/02/26.
//

import Foundation

protocol LoginUseCaseProtocol {
    func execute(email: String, password: String) async throws -> UserProfile
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case emptyFields
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email format or password too short."
        case .emptyFields: return "Email and password cannot be empty."
        }
    }
}

final class LoginUseCase: LoginUseCaseProtocol {
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func execute(email: String, password: String) async throws -> UserProfile {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.emptyFields
        }
        
        guard email.contains("@") && password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        return try await authService.signIn(email: email, password: password)
    }
}
