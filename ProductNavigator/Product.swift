import Foundation

struct Product: Equatable, Sendable {
    let id: UUID
    let name: String
    let description: String
}
