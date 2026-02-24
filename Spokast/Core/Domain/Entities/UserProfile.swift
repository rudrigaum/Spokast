//
//  UserProfile.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 23/02/26.
//

import Foundation

struct UserProfile: Equatable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: URL?
    
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
    }
}
