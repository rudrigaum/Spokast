//
//  ProfileViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import Combine

enum ProfileViewState: Equatable {
    case idle
    case loading
    case success(message: String)
    case error(message: String)
}

@MainActor
protocol ProfileViewModelProtocol: AnyObject {
    var statePublisher: Published<ProfileViewState>.Publisher { get }
    func importOPML(from url: URL)
}

@MainActor
final class ProfileViewModel: ProfileViewModelProtocol {
    
    // MARK: - Dependencies
    private let importService: OPMLImportService
    
    // MARK: - Outputs
    @Published private(set) var state: ProfileViewState = .idle

    var statePublisher: Published<ProfileViewState>.Publisher { $state }
    
    // MARK: - Init
    init(importService: OPMLImportService? = nil) {
        self.importService = importService ?? OPMLImportService()
    }
    
    // MARK: - Actions
    func importOPML(from url: URL) {
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
                self.state = .success(message: "Successfully imported \(count) podcasts from OPML.")
                
            } catch {
                self.state = .error(message: "Import failed: \(error.localizedDescription)")
            }
        }
    }
}
