//
//  FullscreenTransitionTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 05/06/26.
//

import Foundation
import XCTest
@testable import Spokast

@MainActor
final class FullscreenTransitionTests: XCTestCase {

    // MARK: - FullscreenTransitionManager Tests
    func test_transitionManager_returnsCorrectAnimatorForPresentation() {
        let sut = FullscreenTransitionManager(originFrame: .zero, image: nil)

        let animator = sut.animationController(
            forPresented: UIViewController(),
            presenting: UIViewController(),
            source: UIViewController()
        )

        XCTAssertTrue(animator is CoverTransitionAnimator, "Should return CoverTransitionAnimator on presentation")
    }

    func test_transitionManager_returnsCorrectAnimatorForDismissal() {
        let sut = FullscreenTransitionManager(originFrame: .zero, image: nil)
        let animator = sut.animationController(forDismissed: UIViewController())
        XCTAssertTrue(animator is CoverTransitionAnimator, "Should return CoverTransitionAnimator on dismissal")
    }

    // MARK: - CoverTransitionAnimator Tests
    func test_animator_transitionDuration_isCorrect() {
        let sut = CoverTransitionAnimator(originFrame: .zero, isPresenting: true, image: nil)
        let duration = sut.transitionDuration(using: nil)
        XCTAssertEqual(duration, 0.5, "Animation duration should be exactly 0.5 seconds")
    }

    func test_animateTransition_presenting_completesSuccessfully() {
        let originFrame = CGRect(x: 10, y: 10, width: 50, height: 50)
        let sut = CoverTransitionAnimator(originFrame: originFrame, isPresenting: true, image: UIImage())
        let context = TransitionContextMock()

        let toVC = FullscreenCoverViewController(image: nil)
        toVC.loadViewIfNeeded()

        context.viewControllers[.to] = toVC
        context.views[.to] = toVC.view

        let expectation = XCTestExpectation(description: "Wait for presentation animation completion")

        context.onComplete = {
            expectation.fulfill()
        }

        sut.animateTransition(using: context)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(
            context.completeTransitionCalled,
            "Transition should be completed at the end of presentation animation"
        )

        XCTAssertTrue(
            context.containerView.subviews.contains(toVC.view),
            "The toView should be added to the container view"
        )
    }

    func test_animateTransition_dismissing_completesSuccessfully() {
        let sut = CoverTransitionAnimator(originFrame: .zero, isPresenting: false, image: nil)
        let context = TransitionContextMock()

        let fromVC = FullscreenCoverViewController(image: nil)
        fromVC.loadViewIfNeeded()

        context.viewControllers[.from] = fromVC
        context.views[.from] = fromVC.view

        let expectation = XCTestExpectation(description: "Wait for dismissal animation completion")

        context.onComplete = {
            expectation.fulfill()
        }

        sut.animateTransition(using: context)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(
            context.completeTransitionCalled,
            "Transition should be completed at the end of dismissal animation"
        )
    }
    func test_animateTransition_presenting_failsGracefullyWhenVCMissing() {
        let sut = CoverTransitionAnimator(originFrame: .zero, isPresenting: true, image: nil)
        let context = TransitionContextMock()

        sut.animateTransition(using: context)

        XCTAssertTrue(
            context.completeTransitionCalled, "The guard let should fail gracefully and call completeTransition(false)"
        )
    }

    func test_animateTransition_dismissing_failsGracefullyWhenVCMissing() {
        let sut = CoverTransitionAnimator(originFrame: .zero, isPresenting: false, image: nil)
        let context = TransitionContextMock()

        sut.animateTransition(using: context)

        XCTAssertTrue(
            context.completeTransitionCalled, "The guard let should fail gracefully and call completeTransition(false)"
        )
    }
}
