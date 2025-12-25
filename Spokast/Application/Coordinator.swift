//
//  Coordinator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import Foundation
import UIKit

@MainActor
protocol Coordinator: AnyObject {
    func start()
}

@MainActor
protocol NavigationCoordinator: Coordinator {
    var navigationController: UINavigationController { get }
    func presentAlert(title: String, message: String)
}

extension NavigationCoordinator {
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        navigationController.present(alertController, animated: true)
    }
}
