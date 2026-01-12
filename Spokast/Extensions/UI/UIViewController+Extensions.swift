//
//  UIViewController+Extensions.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 09/01/26.
//

import Foundation
import UIKit

extension UIViewController {
    
    func presentDeleteConfirmation(for episode: Episode, sourceView: UIView?, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Remove Download?",
            message: "The episode \"\(episode.trackName)\" will be deleted from your device.",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Remove Download", style: .destructive) { _ in
            onConfirm()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let popover = alert.popoverPresentationController, let sourceView = sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        } else if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}
