//
//  TransitionContextMock.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 06/06/26.
//

import Foundation
import UIKit

final class TransitionContextMock: NSObject, UIViewControllerContextTransitioning {
    var containerView: UIView = UIView()
    var isAnimated: Bool = true
    var isInteractive: Bool = false
    var transitionWasCancelled: Bool = false
    var presentationStyle: UIModalPresentationStyle = .custom
    var targetTransform: CGAffineTransform = .identity

    var viewControllers: [UITransitionContextViewControllerKey: UIViewController] = [:]
    var views: [UITransitionContextViewKey: UIView] = [:]

    var completeTransitionCalled = false
    var onComplete: (() -> Void)?

    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    func pauseInteractiveTransition() {}

    func completeTransition(_ didComplete: Bool) {
        completeTransitionCalled = true
        onComplete?()
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return viewControllers[key]
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return views[key]
    }

    func initialFrame(for viewController: UIViewController) -> CGRect { return .zero }
    func finalFrame(for viewController: UIViewController) -> CGRect { return .zero }
}
