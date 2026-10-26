import UIKit

@MainActor
protocol ProductListViewControllerDelegate: AnyObject {
    func productListViewController(
        _ controller: ProductListViewController,
        didSelect product: Product
    )
}

@MainActor
final class ProductListViewController: UITableViewController {
    weak var delegate: (any ProductListViewControllerDelegate)?

    private let productProvider: any ProductProviding
    private var products: [Product] = []
    private let cellIdentifier = "ProductCell"

    init(productProvider: any ProductProviding) {
        self.productProvider = productProvider
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(productProvider:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Products"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        products = productProvider.products()
        tableView.reloadData()
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        products.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath
        )
        let product = products[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = product.name
        content.secondaryText = product.description
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.productListViewController(self, didSelect: products[indexPath.row])
    }
}
