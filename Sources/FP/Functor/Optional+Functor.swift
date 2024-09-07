import Foundation

public extension Optional {
    static func fmap<A0>(
        _ fn: @escaping (A0) -> A
    ) -> (Optional<A0>) -> Optional<A> where Self: Sendable {
        { previous in previous.map(fn) }
    }
}
