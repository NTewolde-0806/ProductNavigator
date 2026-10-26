import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            productProvider: SampleProductProvider()
        )

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController

        self.window = window
        self.coordinator = coordinator
        coordinator.start()
        window.makeKeyAndVisible()
    }
}
