import Foundation

public extension Optional {
    static func fmap<A1>(
        _ fn: @escaping (A) -> A1
    ) -> (A?) -> A1? where Self: Sendable {
        { $0.map(fn) }
    }
}
