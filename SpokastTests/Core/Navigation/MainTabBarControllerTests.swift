//
//  MainTabBarControllerTests.swift
//  SpokastTests
//
//  Created by Rodrigo Cerqueira Reis on 03/05/26.
//

import XCTest
@testable import Spokast

@MainActor
final class MainTabBarControllerTests: XCTestCase {

    var sut: MainTabBarController!

    override func setUp() {
        super.setUp()
        let vc1 = UIViewController()
        let vc2 = UIViewController()
        sut = MainTabBarController(viewControllers: [vc1, vc2])
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_viewDidLoad_configuresTabBarAndMiniPlayer() {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.viewControllers?.count, 2)
        XCTAssertEqual(sut.tabBar.tintColor, .systemPurple)
        XCTAssertNotNil(sut.tabBar.standardAppearance.backgroundEffect)

        let miniPlayerView = sut.view.subviews.compactMap { $0 as? MiniPlayerView }.first
        XCTAssertNotNil(miniPlayerView, "A MiniPlayerView deveria ter sido instanciada e adicionada à tela")
    }

    func test_miniPlayerTap_withoutEpisode_doesNotPresentPlayer() {
        AudioPlayerService.shared.currentEpisode = nil

        sut.loadViewIfNeeded()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = sut
        window.makeKeyAndVisible()

        guard let miniPlayerView = sut.view.subviews.compactMap({ $0 as? MiniPlayerView }).first else {
            XCTFail("MiniPlayerView não encontrada na hierarquia de views")
            return
        }

        miniPlayerView.onTap?()

        XCTAssertNil(sut.presentedViewController,
                     "Não deve apresentar o PlayerViewController se não houver episódio tocando")
    }
}
