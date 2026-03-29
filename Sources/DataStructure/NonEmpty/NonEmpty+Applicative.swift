import CoreFP

// MARK: - Applicative

public extension NonEmpty {
    /// Lift a single value into a singleton NonEmpty.
    static func pure(_ value: A) -> NonEmpty<A> {
        NonEmpty(head: value)
    }

    /// Apply every wrapped function to every wrapped value (cartesian product).
    /// Result is always non-empty since both inputs are non-empty.
    static func apply<Input>(_ nf: NonEmpty<(Input) -> A>, _ na: NonEmpty<Input>) -> NonEmpty<A> {
        let all = nf.toArray.flatMap { f in na.toArray.map { f($0) } }
        return NonEmpty(head: all[0], tail: Array(all.dropFirst()))
    }

    /// Run both, keep the right result. Left structure still contributes to count.
    func seqRight<B>(_ other: NonEmpty<B>) -> NonEmpty<B> {
        flatMap(CoreFP.const(other))
    }

    /// Run both, keep the left result. Right structure still contributes to count.
    func seqLeft<B>(_ other: NonEmpty<B>) -> NonEmpty<A> {
        flatMap { a in other.map(CoreFP.const(a)) }
    }

    /// Lift a binary function across all combinations.
    static func liftA2<B, C>(
        _ fn: @escaping (A, B) -> C
    ) -> (NonEmpty<A>, NonEmpty<B>) -> NonEmpty<C> {
        { na, nb in NonEmpty<C>.apply(na.map { a in { b in fn(a, b) } }, nb) }
    }

    /// Zip by index (shortest wins) — paired semantics, not cartesian.
    static func zip<A1, A2>(_ na1: NonEmpty<A1>, _ na2: NonEmpty<A2>) -> NonEmpty<A>
    where A == (A1, A2) {
        let pairs = Swift.zip(na1.toArray, na2.toArray).map { ($0, $1) }
        return NonEmpty<(A1, A2)>(head: pairs[0], tail: Array(pairs.dropFirst()))
    }
}
