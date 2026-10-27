@MainActor
final class ProductListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Product])
        case empty
        case failed(message: String)
    }

    private let productProvider: any ProductProviding
    private(set) var state: State = .idle
    var onStateChange: (() -> Void)?

    var products: [Product] {
        if case let .loaded(products) = state {
            return products
        }
        return []
    }

    init(productProvider: any ProductProviding) {
        self.productProvider = productProvider
    }

    func load() async {
        guard state != .loading else { return }
        state = .loading
        onStateChange?()
        do {
            let products = try await productProvider.products()
            state = products.isEmpty ? .empty : .loaded(products)
        } catch {
            state = .failed(message: "Please try loading the products again.")
        }
        onStateChange?()
    }
}
