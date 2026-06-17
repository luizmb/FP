import Foundation

public extension Array {
    /// Left-associative fold using an accumulator.
    /// foldLeft :: b -> (b -> a -> b) -> [a] -> b
    static func foldLeft<B>(
        _ initial: B,
        _ f: @escaping @Sendable (B, Element) -> B
    ) -> ([Element]) -> B {
        { $0.reduce(initial, f) }
    }

    /// Right-associative fold using an accumulator.
    /// foldRight :: (a -> b -> b) -> b -> [a] -> b
    static func foldRight<B>(
        _ f: @escaping @Sendable (Element, B) -> B,
        _ initial: B
    ) -> ([Element]) -> B {
        { $0.reversed().reduce(initial) { acc, elem in f(elem, acc) } }
    }

    /// Map each element to a Monoid, then combine.
    /// foldMap :: Monoid m => (a -> m) -> [a] -> m
    static func foldMap<M: Monoid>(
        _ f: @escaping @Sendable (Element) -> M
    ) -> ([Element]) -> M {
        // Module-qualified: inside `extension Array` the bare name now binds to the
        // `Array.mconcat` member (which expects `[[Element]]`), not this free function.
        { CoreFP.mconcat($0.map(f)) }
    }
}
