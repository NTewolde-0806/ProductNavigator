import Foundation

struct SampleProductProvider: ProductProviding {
    private let sampleProducts: [Product] = [
        Product(
            id: UUID(),
            name: "Notebook",
            description: "A hardcover notebook for everyday ideas."
        ),
        Product(
            id: UUID(),
            name: "Desk Lamp",
            description: "An adjustable lamp for a comfortable workspace."
        ),
        Product(
            id: UUID(),
            name: "Travel Mug",
            description: "An insulated mug for drinks on the go."
        )
    ]

    func products() async -> [Product] {
        sampleProducts
    }
}
