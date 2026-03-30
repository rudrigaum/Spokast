//
//  AuthServiceProtocol.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/02/26.
//

import Foundation

protocol AuthServiceProtocol {
    func getCurrentUser() async throws -> UserProfile?
    func signIn(email: String, password: String) async throws -> UserProfile
    func signUp(email: String, password: String) async throws -> UserProfile
    func signOut() async throws
}
