//
//  OPMLItem.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 24/01/26.
//

import Foundation

struct OPMLItem {
    let title: String
    let rssURL: String?
    let siteURL: String?
    var categoryName: String?
    var isFeed: Bool {
        return rssURL != nil
    }
}
