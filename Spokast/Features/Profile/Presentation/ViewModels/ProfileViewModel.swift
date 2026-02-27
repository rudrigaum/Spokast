//
//  ProfileViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import Combine

enum ProfileViewState: Equatable {
    case loading
    case unauthenticated
    case authenticated(user: UserProfile, message: String? = nil)
    case error(message: String)
}

@MainActor
protocol ProfileViewModelProtocol: AnyObject {
    var state: ProfileViewState { get }
    var onLoginRequest: (() -> Void)? { get set }
    var statePublisher: Published<ProfileViewState>.Publisher { get }
    func handleAccountAction()
    func checkAuthStatus()
    func importOPML(from url: URL)
    func logout()
}

@MainActor
final class ProfileViewModel: ProfileViewModelProtocol {
    
    // MARK: - Dependencies
    private let authService: AuthServiceProtocol
    private let importService: OPMLImportService
    
    // MARK: - Outputs
    @Published private(set) var state: ProfileViewState = .loading
    var statePublisher: Published<ProfileViewState>.Publisher { $state }
    
    var onLoginRequest: (() -> Void)?
    
    
    // MARK: - Init
    init(authService: AuthServiceProtocol,
         importService: OPMLImportService? = nil) {
        
        self.authService = authService
        self.importService = importService ?? OPMLImportService()
        checkAuthStatus()
    }
    
    // MARK: - Authentication Actions
    func checkAuthStatus() {
        Task {
            do {
                if let user = try await authService.getCurrentUser() {
                    state = .authenticated(user: user)
                } else {
                    state = .unauthenticated
                }
            } catch {
                state = .error(message: "Failed to verify session.")
            }
        }
    }
    
    func handleAccountAction() {
        if case .unauthenticated = state {
            onLoginRequest?()
        } else {
            logout()
        }
    }
    
    func logout() {
        state = .loading
        Task {
            do {
                try await authService.signOut()
                state = .unauthenticated
            } catch {
                state = .error(message: "Logout failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - OPML Actions
    func importOPML(from url: URL) {
        let currentUser = getCurrentUserFromState()
        state = .loading
        
        Task {
            do {
                let accessGranted = url.startAccessingSecurityScopedResource()
                defer {
                    if accessGranted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let count = try await importService.importOPML(from: url)
                let successMessage = "Successfully imported \(count) podcasts."
                
                if let user = currentUser {
                    state = .authenticated(user: user, message: successMessage)
                } else {
                    state = .unauthenticated
                }
                
            } catch {
                state = .error(message: "Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helpers
    private func getCurrentUserFromState() -> UserProfile? {
        if case let .authenticated(user, _) = state {
            return user
        }
        return nil
    }
}
