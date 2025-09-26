//
//  HomeViewModel.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation

protocol HomeViewModelDelegate: AnyObject {
    
}

final class HomeViewModel {

    weak var delegate: HomeViewModelDelegate?

    init() {
        
    }
}
