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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var authMode: AuthMode = .signIn
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    
    // MARK: - Init
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // MARK: - Actions
    func toggleAuthMode() {
        authMode = (authMode == .signIn) ? .signUp : .signIn
        errorMessage = nil
    }
    
    func submit() {
        guard validateFields() else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if authMode == .signIn {
                    _ = try await authService.signIn(email: email, password: password)
                } else {
                    _ = try await authService.signUp(email: email, password: password)
                }
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func validateFields() -> Bool {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters long."
            return false
        }
        return true
    }
}
