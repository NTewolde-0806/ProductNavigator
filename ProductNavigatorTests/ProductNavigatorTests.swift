import UIKit
import XCTest
@testable import ProductNavigator

@MainActor
final class ProductNavigatorTests: XCTestCase {
    func testFailedLoadCanBeRetriedSuccessfully() async {
        let provider = RecoverableProductProvider()
        let viewModel = ProductListViewModel(productProvider: provider)
        var states: [ProductListViewModel.State] = []
        viewModel.onStateChange = { states.append(viewModel.state) }
        defer { viewModel.onStateChange = nil }

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .failed(message: "Please try loading the products again."))
        XCTAssertTrue(viewModel.products.isEmpty)

        let product = makeProduct(name: "Recovered")
        provider.result = .success([product])
        await viewModel.load()

        XCTAssertEqual(states, [
            .loading, .failed(message: "Please try loading the products again."),
            .loading, .loaded([product])
        ])
        XCTAssertEqual(provider.requestCount, 2)
    }

    func testFailureButtonRetriesAndClearsErrorPresentation() async throws {
        let provider = RecoverableProductProvider()
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: provider))
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)
        let configuration = try XCTUnwrap(list.contentUnavailableConfiguration as? UIContentUnavailableConfiguration)
        XCTAssertEqual(configuration.text, "Couldn't load products")
        XCTAssertEqual(configuration.button.title, "Retry")
        let action = try XCTUnwrap(configuration.buttonProperties.primaryAction)
        let retryButton = UIButton(configuration: .plain(), primaryAction: action)

        provider.result = .success([makeProduct(name: "Recovered")])
        retryButton.sendActions(for: .primaryActionTriggered)
        let ready = NSPredicate { _, _ in list.tableView.numberOfRows(inSection: 0) == 1 }
        await fulfillment(of: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 3)

        XCTAssertEqual(provider.requestCount, 2)
        XCTAssertNil(list.contentUnavailableConfiguration)
    }

    func testLoadingStateAndDuplicateRequestGuard() async {
        let provider = SuspendedProductProvider()
        let viewModel = ProductListViewModel(productProvider: provider)
        let started = expectation(description: "Provider started")
        provider.onStart = { started.fulfill() }
        let request = Task { await viewModel.load() }
        await fulfillment(of: [started], timeout: 3)

        XCTAssertEqual(viewModel.state, .loading)
        await viewModel.load()
        XCTAssertEqual(provider.requestCount, 1)

        let product = makeProduct(name: "Delayed")
        provider.complete(with: [product])
        await request.value
        XCTAssertEqual(viewModel.state, .loaded([product]))
    }

    func testControllerDisplaysLoadingUntilRequestCompletes() async {
        let provider = SuspendedProductProvider()
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: provider))
        let started = expectation(description: "Provider started")
        provider.onStart = { started.fulfill() }
        list.loadViewIfNeeded()
        await fulfillment(of: [started], timeout: 3)

        let loading = list.contentUnavailableConfiguration as? UIContentUnavailableConfiguration
        XCTAssertEqual(loading?.text, "Loading products…")

        provider.complete(with: [makeProduct(name: "Delayed")])
        await waitForListToFinishLoading(list)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 1)
        XCTAssertNil(list.contentUnavailableConfiguration)
    }

    func testViewModelNotifiesAfterStateIsUpdated() async {
        let product = makeProduct(name: "Updated")
        let provider = MutableProductProvider(items: [product])
        let viewModel = ProductListViewModel(productProvider: provider)
        var snapshots: [ProductListViewModel.State] = []
        viewModel.onStateChange = {
            snapshots.append(viewModel.state)
        }
        defer { viewModel.onStateChange = nil }

        await viewModel.load()
        provider.items = []
        await viewModel.load()

        XCTAssertEqual(snapshots, [.loading, .loaded([product]), .loading, .empty])
    }

    func testListRendersEmptyStateAndRecoversWhenProductsArrive() async {
        let provider = MutableProductProvider(items: [makeProduct(name: "First")])
        let viewModel = ProductListViewModel(productProvider: provider)
        let list = ProductListViewController(viewModel: viewModel)
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 1)
        XCTAssertNil(list.contentUnavailableConfiguration)

        provider.items = []
        await viewModel.load()

        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 0)
        let emptyConfiguration = list.contentUnavailableConfiguration as? UIContentUnavailableConfiguration
        XCTAssertEqual(emptyConfiguration?.text, "No products available")

        provider.items = [makeProduct(name: "Returned")]
        await viewModel.load()
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 1)
        XCTAssertNil(list.contentUnavailableConfiguration)
    }

    func testViewModelCallbackDoesNotKeepListAlive() async {
        let viewModel = ProductListViewModel(productProvider: StubProductProvider(items: []))
        weak var releasedList: ProductListViewController?
        autoreleasepool {
            let list = ProductListViewController(viewModel: viewModel)
            list.loadViewIfNeeded()
            releasedList = list
        }

        XCTAssertNil(releasedList)
        await viewModel.load()
    }

    func testViewModelLoadsAndReplacesProductsFromProvider() async {
        let first = makeProduct(name: "First")
        let second = makeProduct(name: "Second")
        let provider = MutableProductProvider(items: [first])
        let viewModel = ProductListViewModel(productProvider: provider)

        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
        await viewModel.load()
        XCTAssertEqual(viewModel.products, [first])
        XCTAssertEqual(viewModel.state, .loaded([first]))

        provider.items = [second]
        await viewModel.load()
        XCTAssertEqual(viewModel.products, [second])

        provider.items = []
        await viewModel.load()
        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertEqual(viewModel.state, .empty)
    }

    func testListDisplaysInjectedProducts() async throws {
        let product = makeProduct(name: "Test product")
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: [product])))
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)

        XCTAssertEqual(list.tableView(list.tableView, numberOfRowsInSection: 0), 1)
        let cell = list.tableView(list.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let content = try XCTUnwrap(cell.contentConfiguration as? UIListContentConfiguration)
        XCTAssertEqual(content.text, product.name)
        XCTAssertEqual(content.secondaryText, product.description)
    }

    func testEmptyProviderProducesNoRows() async {
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: [])))
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)

        XCTAssertEqual(list.tableView(list.tableView, numberOfRowsInSection: 0), 0)
    }

    func testSelectionReportsProductWithoutNavigating() async {
        let products = [makeProduct(name: "First"), makeProduct(name: "Second")]
        let list = ProductListViewController(viewModel: ProductListViewModel(productProvider: StubProductProvider(items: products)))
        let delegate = SelectionSpy()
        list.delegate = delegate
        let navigation = UINavigationController(rootViewController: list)
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)

        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        XCTAssertEqual(delegate.selectedProduct, products[1])
        XCTAssertTrue(delegate.source === list)
        XCTAssertEqual(navigation.viewControllers.count, 1)
    }

    func testCoordinatorConnectsSelectionToCorrectDetail() async throws {
        let products = [makeProduct(name: "First"), makeProduct(name: "Second")]
        let navigation = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigation,
            productProvider: StubProductProvider(items: products)
        )
        coordinator.start()
        let list = try XCTUnwrap(navigation.viewControllers.first as? ProductListViewController)
        list.loadViewIfNeeded()
        await waitForListToFinishLoading(list)
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

    private func waitForListToFinishLoading(_ list: ProductListViewController) async {
        let ready = NSPredicate { _, _ in
            let configuration = list.contentUnavailableConfiguration as? UIContentUnavailableConfiguration
            return configuration?.text == "No products available"
                || configuration?.text == "Couldn't load products"
                || list.tableView.numberOfRows(inSection: 0) > 0
        }
        // Yield once so the initial Task can publish loading or its immediate result.
        await Task.yield()
        let expectation = XCTNSPredicateExpectation(predicate: ready, object: nil)
        await fulfillment(of: [expectation], timeout: 3)
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

    func products() async -> [Product] { items }
}

@MainActor
private final class RecoverableProductProvider: ProductProviding {
    enum Failure: Error { case unavailable }
    var result: Result<[Product], Failure> = .failure(.unavailable)
    private(set) var requestCount = 0

    func products() async throws -> [Product] {
        requestCount += 1
        return try result.get()
    }
}

@MainActor
private final class SuspendedProductProvider: ProductProviding {
    var onStart: (() -> Void)?
    private(set) var requestCount = 0
    private var continuation: CheckedContinuation<[Product], Never>?

    func products() async -> [Product] {
        requestCount += 1
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            onStart?()
        }
    }

    func complete(with products: [Product]) {
        let pending = continuation
        continuation = nil
        pending?.resume(returning: products)
    }
}

@MainActor
private final class MutableProductProvider: ProductProviding {
    var items: [Product]

    init(items: [Product]) {
        self.items = items
    }

    func products() async -> [Product] { items }
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
