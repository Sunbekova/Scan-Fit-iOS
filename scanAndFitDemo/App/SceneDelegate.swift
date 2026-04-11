//
//  SceneDelegate.swift
//  scanFit
//
//

import UIKit
import SwiftUI
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let authViewModel = BackendAuthViewModel()
    let trackerViewModel = TrackerViewModel()
    var modelContainer: ModelContainer!


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        do {modelContainer = try ModelContainer(for: FavoriteProductEntity.self, RecentProductEntity.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
        let rootView = RootView()
            .environmentObject(authViewModel)
            .environmentObject(trackerViewModel)
            .modelContainer(modelContainer)

        let hostingController = UIHostingController(rootView: rootView)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = hostingController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }


}

