import Foundation

public extension Optional {
    static func fmap<A1>(
        _ fn: @escaping @Sendable (A) -> A1
    ) -> @Sendable (A?) -> A1? {
        { $0.map(fn) }
    }
}
