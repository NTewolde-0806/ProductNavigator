import UIKit

@MainActor
final class AppCoordinator: ProductListViewControllerDelegate {
    private let navigationController: UINavigationController
    private let productProvider: any ProductProviding

    init(
        navigationController: UINavigationController,
        productProvider: any ProductProviding
    ) {
        self.navigationController = navigationController
        self.productProvider = productProvider
    }

    func start() {
        let listViewController = ProductListViewController(productProvider: productProvider)
        listViewController.delegate = self
        navigationController.setViewControllers([listViewController], animated: false)
    }

    func productListViewController(
        _ controller: ProductListViewController,
        didSelect product: Product
    ) {
        let detailViewController = ProductDetailViewController(product: product)
        navigationController.pushViewController(detailViewController, animated: true)
    }
}
