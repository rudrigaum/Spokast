//
//  FullscreenTransitionManager.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 02/06/26.
//

import Foundation
import UIKit

final class FullscreenTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    
    private let originFrame: CGRect
    private let image: UIImage?
    
    init(originFrame: CGRect, image: UIImage?) {
        self.originFrame = originFrame
        self.image = image
        super.init()
    }
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return CoverTransitionAnimator(originFrame: originFrame, isPresenting: true, image: image)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CoverTransitionAnimator(originFrame: originFrame, isPresenting: false, image: image)
    }
}
