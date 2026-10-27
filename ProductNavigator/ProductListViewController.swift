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

    private let viewModel: ProductListViewModel
    private let cellIdentifier = "ProductCell"

    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(viewModel:) instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Products"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        viewModel.onStateChange = { [weak self] in
            self?.render()
        }
        loadProducts()
    }

    private func loadProducts() {
        let viewModel = viewModel
        Task {
            await viewModel.load()
        }
    }

    private func render() {
        switch viewModel.state {
        case .idle, .loaded:
            contentUnavailableConfiguration = nil
        case .loading:
            var configuration = UIContentUnavailableConfiguration.loading()
            configuration.text = "Loading products…"
            contentUnavailableConfiguration = configuration
        case .empty:
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.text = "No products available"
            configuration.secondaryText = "Products will appear here when available."
            contentUnavailableConfiguration = configuration
        case let .failed(message):
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.text = "Couldn't load products"
            configuration.secondaryText = message
            configuration.button = .borderedProminent()
            configuration.button.title = "Retry"
            configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
                self?.loadProducts()
            }
            contentUnavailableConfiguration = configuration
        }
        tableView.reloadData()
    }

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.products.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath
        )
        let product = viewModel.products[indexPath.row]
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
        delegate?.productListViewController(self, didSelect: viewModel.products[indexPath.row])
    }
}
