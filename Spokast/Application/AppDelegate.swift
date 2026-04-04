//
//  AppDelegate.swift
//  Spokast
//
//  Created by Rodrigo Cerqueira Reis on 26/09/25.
//

import UIKit
import Kingfisher
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {

            if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
                FirebaseApp.configure()
            } else {
                let options = FirebaseOptions(
                    googleAppID: "1:123456789012:ios:a1b2c3d4e5f67890",
                    gcmSenderID: "123456789012"
                )
                options.apiKey = "AIzaSyDummyKeyForTests1234567890"
                options.projectID = "dummy-project-id"
                FirebaseApp.configure(options: options)
            }

            setupImageCache()
            return true
        }

    // MARK: UISceneSession Lifecycle
    func application(
            _ application: UIApplication,
            configurationForConnecting connectingSceneSession: UISceneSession,
            options: UIScene.ConnectionOptions
        ) -> UISceneConfiguration {
            // Called when a new scene session is being created.
            // Use this method to select a configuration to create the new scene with.
            return UISceneConfiguration(
                name: "Default Configuration",
                sessionRole: connectingSceneSession.role
            )
        }

        func application(
            _ application: UIApplication,
            didDiscardSceneSessions sceneSessions: Set<UISceneSession>
        ) {
            // Called when the user discards a scene session.
            // If any sessions were discarded while the application was not running,
            // this will be called shortly after application:didFinishLaunchingWithOptions.
            // Use this method to release any resources that were specific to the
            // discarded scenes, as they will not return.
        }

    func setupImageCache() {
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 50
        ImageCache.default.memoryStorage.config.expiration = .seconds(300)
    }
}
