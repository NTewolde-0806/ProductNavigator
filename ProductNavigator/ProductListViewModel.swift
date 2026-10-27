@MainActor
final class ProductListViewModel {
    private let productProvider: any ProductProviding
    private(set) var products: [Product] = []

    init(productProvider: any ProductProviding) {
        self.productProvider = productProvider
    }

    func load() {
        products = productProvider.products()
    }
}
