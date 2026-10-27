@MainActor
protocol ProductProviding {
    func products() async throws -> [Product]
}
