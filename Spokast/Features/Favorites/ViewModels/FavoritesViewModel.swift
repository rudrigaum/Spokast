//
//  FavoritesViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/12/25.
//

import Foundation
import Combine

enum FavoritesViewState: Equatable {
    case loading
    case empty
    case loaded([SavedPodcast])
    case error(String)
}

@MainActor
protocol FavoritesViewModelProtocol: AnyObject {
    var statePublisher: Published<FavoritesViewState>.Publisher { get }
    func loadFavorites()
    // func removePodcast(at index: Int) // TODO
}

@MainActor
final class FavoritesViewModel: FavoritesViewModelProtocol {
    
    // MARK: - Dependencies
    private let service: LibraryServiceProtocol
    
    // MARK: - Outputs
    @Published private(set) var state: FavoritesViewState = .loading
    
    var statePublisher: Published<FavoritesViewState>.Publisher { $state }
    
    // MARK: - Init
    init(service: LibraryServiceProtocol? = nil) {
        self.service = service ?? LibraryService()
    }
    
    // MARK: - Methods
    func loadFavorites() {
        state = .loading
        
        do {
            let items = try service.fetchPodcasts()
            
            if items.isEmpty {
                state = .empty
            } else {
                state = .loaded(items)
            }
        } catch {
            print("❌ Error fetching library: \(error)")
            state = .error("Failed to load library.")
        }
    }
}
