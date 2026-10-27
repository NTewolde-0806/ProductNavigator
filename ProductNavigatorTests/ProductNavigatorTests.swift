import UIKit
import XCTest
@testable import ProductNavigator

@MainActor
final class ProductNavigatorTests: XCTestCase {
    func testViewModelLoadsAndReplacesProductsFromProvider() {
        let first = makeProduct(name: "First")
        let second = makeProduct(name: "Second")
        let provider = MutableProductProvider(items: [first])
        let viewModel = ProductListViewModel(productProvider: provider)

        XCTAssertTrue(viewModel.products.isEmpty)
        viewModel.load()
        XCTAssertEqual(viewModel.products, [first])

        provider.items = [second]
        viewModel.load()
        XCTAssertEqual(viewModel.products, [second])

        provider.items = []
        viewModel.load()
        XCTAssertTrue(viewModel.products.isEmpty)
    }

    func testListDisplaysInjectedProducts() throws {
        let product = makeProduct(name: "Test product")
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: [product])))
        list.loadViewIfNeeded()

        XCTAssertEqual(list.tableView(list.tableView, numberOfRowsInSection: 0), 1)
        let cell = list.tableView(list.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let content = try XCTUnwrap(cell.contentConfiguration as? UIListContentConfiguration)
        XCTAssertEqual(content.text, product.name)
        XCTAssertEqual(content.secondaryText, product.description)
    }

    func testEmptyProviderProducesNoRows() {
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: [])))
        list.loadViewIfNeeded()

        XCTAssertEqual(list.tableView(list.tableView, numberOfRowsInSection: 0), 0)
    }

    func testSelectionReportsProductWithoutNavigating() {
        let products = [makeProduct(name: "First"), makeProduct(name: "Second")]
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: products)))
        let delegate = SelectionSpy()
        list.delegate = delegate
        let navigation = UINavigationController(rootViewController: list)
        list.loadViewIfNeeded()

        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(delegate.selectedProduct, products[1])
        XCTAssertTrue(delegate.source === list)
        XCTAssertEqual(navigation.viewControllers.count, 1)
    }

    func testCoordinatorConnectsSelectionToCorrectDetail() throws {
        let products = [makeProduct(name: "First"), makeProduct(name: "Second")]
        let navigation = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigation,
            productProvider: StubProductProvider(items: products)
        )
        coordinator.start()
        let list = try XCTUnwrap(navigation.viewControllers.first as? ProductListViewController)
        list.loadViewIfNeeded()
        XCTAssertTrue(list.delegate === coordinator)

        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(navigation.viewControllers.count, 2)
        let detail = try XCTUnwrap(navigation.topViewController as? ProductDetailViewController)
        detail.loadViewIfNeeded()
        XCTAssertEqual(detail.title, products[1].name)
        XCTAssertTrue(labels(in: detail.view).contains { $0.text == products[1].description })
    }

    func testListDoesNotRetainItsDelegate() {
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: [])))
        var delegate: SelectionSpy? = SelectionSpy()
        list.delegate = delegate
        delegate = nil

        XCTAssertNil(list.delegate)
    }

    private func makeProduct(name: String) -> Product {
        Product(id: UUID(), name: name, description: "Description for \(name)")
    }

    private func labels(in view: UIView) -> [UILabel] {
        let ownLabels = (view as? UILabel).map { [$0] } ?? []
        return ownLabels + view.subviews.flatMap { labels(in: $0) }
    }
}

private struct StubProductProvider: ProductProviding {
    let items: [Product]

    func products() -> [Product] { items }
}

@MainActor
private final class MutableProductProvider: ProductProviding {
    var items: [Product]

    init(items: [Product]) {
        self.items = items
    }

    func products() -> [Product] { items }
}

@MainActor
private final class SelectionSpy: ProductListViewControllerDelegate {
    private(set) var selectedProduct: Product?
    private(set) weak var source: ProductListViewController?

    func productListViewController(_ controller: ProductListViewController, didSelect product: Product) {
        source = controller
        selectedProduct = product
    }
}
