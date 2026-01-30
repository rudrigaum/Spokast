//
//  FavoriteItem.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 30/01/26.
//

import Foundation

// MARK: - Display Models (DTOs)
struct FavoriteItem: Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let artworkUrl: String?
    let feedUrl: String?
    let genre: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FavoritesSection: Hashable, Sendable {
    let title: String
    let items: [FavoriteItem]
    var id: String { title }
}
