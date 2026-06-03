//
//  CoverTransitionAnimator.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 01/06/26.
//

import Foundation
import UIKit

final class CoverTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Properties
    private let originFrame: CGRect
    private let isPresenting: Bool
    private let image: UIImage?

    // MARK: - Init
    init(originFrame: CGRect, isPresenting: Bool, image: UIImage?) {
        self.originFrame = originFrame
        self.isPresenting = isPresenting
        self.image = image
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if isPresenting {
            animatePresentation(using: transitionContext, in: containerView)
        } else {
            animateDismissal(using: transitionContext, in: containerView)
        }
    }

    // MARK: - Presentation Animation
    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning, in containerView: UIView) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? FullscreenCoverViewController,
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        toView.frame = containerView.bounds
        containerView.addSubview(toView)
        toView.layoutIfNeeded()

        let destinationImageView = toVC.getImageView()
        let customCoverView = toVC.getCustomView()

        let destinationFrame = destinationImageView?.frame ?? .zero

        destinationImageView?.alpha = 0
        customCoverView?.setBlurAlpha(0)

        let flyingImageView = UIImageView(frame: originFrame)
        flyingImageView.image = image
        flyingImageView.contentMode = .scaleAspectFill
        flyingImageView.clipsToBounds = true
        flyingImageView.layer.cornerRadius = 10

        containerView.addSubview(flyingImageView)

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: .curveEaseInOut,
            animations: {
                customCoverView?.setBlurAlpha(1.0)
                flyingImageView.frame = destinationFrame
                flyingImageView.layer.cornerRadius = 12
            },
            completion: { _ in
                destinationImageView?.alpha = 1
                flyingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }

    // MARK: - Dismissal Animation
    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning, in containerView: UIView) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? FullscreenCoverViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let startImageView = fromVC.getImageView()
        let customCoverView = fromVC.getCustomView()

        let startFrame = startImageView?.frame ?? .zero

        startImageView?.alpha = 0

        let flyingImageView = UIImageView(frame: startFrame)
        flyingImageView.image = image
        flyingImageView.contentMode = .scaleAspectFill
        flyingImageView.clipsToBounds = true
        flyingImageView.layer.cornerRadius = 12

        containerView.addSubview(flyingImageView)

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.1,
            options: .curveEaseInOut,
            animations: {
                customCoverView?.setBlurAlpha(0)
                flyingImageView.frame = self.originFrame
                flyingImageView.layer.cornerRadius = 10
            },
            completion: { _ in
                flyingImageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}
