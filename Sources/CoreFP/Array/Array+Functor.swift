import Foundation

public extension Array {
    /// Curried version of Swift's native map for functional composition
    /// fmap :: (a -> b) -> f a -> f b
    static func fmap<A1>(
        _ fn: @escaping @Sendable (Element) -> A1
    ) -> @Sendable ([Element]) -> [A1] {
        { array in
            array.map(fn)
        }
    }
}
