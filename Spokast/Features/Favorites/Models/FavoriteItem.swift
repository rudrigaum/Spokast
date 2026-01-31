//
//  FavoriteItem.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 30/01/26.
//

import Foundation

// MARK: - Display Models (DTOs)
struct FavoriteItem: Hashable, Sendable, Identifiable {
    let collectionId: Int
    let title: String
    let artist: String
    let artworkUrl: String?
    let feedUrl: String?
    let genre: String
    
    // MARK: - Identifiable Compliance
    var id: String {
        let urlKey = feedUrl ?? "no-url"
        return "\(collectionId)-\(urlKey)-\(title)"
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    static func == (lhs: FavoriteItem, rhs: FavoriteItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FavoritesSection: Hashable, Sendable, Identifiable {
    let title: String
    let items: [FavoriteItem]
    
    var id: String { title }
}
