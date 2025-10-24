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
    var navigationController: UINavigationController { get set }
    func start()
    func presentAlert(title: String, message: String)
}

extension Coordinator {
    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        navigationController.present(alertController, animated: true)
    }
}
