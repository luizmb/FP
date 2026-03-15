import Foundation

public extension Optional {
    static func fmap<A1>(
        _ fn: @escaping (A) -> A1
    ) -> (A?) -> A1? {
        { $0.map(fn) }
    }
}
