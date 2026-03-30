//
//  LoginViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 27/02/26.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - View State
    enum AuthMode {
        case signIn
        case signUp

        var title: String {
            self == .signIn ? "Sign In" : "Create Account"
        }

        var toggleTitle: String {
            self == .signIn ? "Don't have an account? Create one" : "Already have an account? Sign In"
        }
    }

    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authMode: AuthMode

    // MARK: - Dependencies
    private let authUseCase: AuthUseCaseProtocol

    var onSuccess: (() -> Void)?

    // MARK: - Init
    init(authUseCase: AuthUseCaseProtocol, initialMode: AuthMode = .signIn) {
        self.authUseCase = authUseCase
        self.authMode = initialMode
    }

    // MARK: - Actions
    func toggleAuthMode() {
        authMode = (authMode == .signIn) ? .signUp : .signIn
        errorMessage = nil
    }

    func submit() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if authMode == .signIn {
                    _ = try await authUseCase.signIn(email: email, password: password)
                } else {
                    _ = try await authUseCase.signUp(email: email, password: password)
                }
                isLoading = false
                onSuccess?()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
