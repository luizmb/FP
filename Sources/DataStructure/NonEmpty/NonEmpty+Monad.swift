import CoreFP

// MARK: - Monad

public extension NonEmpty {
    /// Map each element to a NonEmpty, then concatenate all results.
    /// Result is always non-empty because fn(head) is non-empty.
    func flatMap<B>(_ fn: (A) -> NonEmpty<B>) -> NonEmpty<B> {
        let headResult = fn(head)
        let tailResults = tail.flatMap { fn($0).toArray }
        return NonEmpty<B>(head: headResult.head, tail: headResult.tail + tailResults)
    }

    static func bind<B>(
        _ fn: @escaping (A) -> NonEmpty<B>
    ) -> (NonEmpty<A>) -> NonEmpty<B> {
        { $0.flatMap(fn) }
    }

    static func kleisli<O0, B>(
        _ fn1: @escaping (O0) -> NonEmpty<A>,
        _ fn2: @escaping (A) -> NonEmpty<B>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    static func kleisliBack<O0, B>(
        _ fn2: @escaping (A) -> NonEmpty<B>,
        _ fn1: @escaping (O0) -> NonEmpty<A>
    ) -> (O0) -> NonEmpty<B> {
        { fn1($0).flatMap(fn2) }
    }

    static func join<O>(
        _ nested: NonEmpty<NonEmpty<O>>
    ) -> NonEmpty<O> where A == NonEmpty<O> {
        nested.flatMap(CoreFP.id)
    }

    func void() -> NonEmpty<Void> {
        map(ignore)
    }
}
