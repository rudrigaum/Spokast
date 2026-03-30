//
//  FirebaseAuthService.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 25/02/26.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthServiceProtocol {
    
    // MARK: - AuthServiceProtocol Implementation
    func getCurrentUser() async throws -> UserProfile? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return mapFirebaseUser(firebaseUser)
    }
    
    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return mapFirebaseUser(result.user)
        } catch {
            throw mapError(error)
        }
    }
    
    func signUp(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return mapFirebaseUser(result.user)
        } catch {
            throw mapError(error)
        }
    }
    
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw error
        }
    }
    
    // MARK: - Private Helpers
    private func mapFirebaseUser(_ user: User) -> UserProfile {
        return UserProfile(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName,
            photoURL: user.photoURL
        )
    }
    
    /// Maps Firebase specific errors to our Domain errors (optional but recommended).
    private func mapError(_ error: Error) -> Error {
        // You can expand this to map specific Firebase codes to your AuthError enum
        return error
    }
}
