//
//  Category.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var name: String
    var id: UUID
    var createdAt: Date
    @Relationship(deleteRule: .nullify, inverse: \SavedPodcast.category)
    var podcasts: [SavedPodcast]? = []
    
    init(name: String, id: UUID = UUID()) {
        self.name = name
        self.id = id
        self.createdAt = Date()
    }
}
