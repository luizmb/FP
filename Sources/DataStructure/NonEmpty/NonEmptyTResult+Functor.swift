// NonEmptyTResult: outer = NonEmpty, inner = Result
// Type: NonEmpty<Result<A, E>>  (Success = A, Failure = E)

public extension NonEmpty {
    /// mapT for NonEmpty<Result<A, E>> — maps over the success values.
    func mapT<Inner, E, Output>(_ fn: (Inner) -> Output) -> NonEmpty<Result<Output, E>>
    where A == Result<Inner, E> {
        let h: Result<Inner, E> = head
        let t: [Result<Inner, E>] = tail
        return NonEmpty<Result<Output, E>>(
            head: h.map(fn),
            tail: t.map { r in r.map(fn) }
        )
    }

    static func fmapT<Inner, E, Output>(
        _ fn: @escaping @Sendable (Inner) -> Output
    ) -> @Sendable (NonEmpty<Result<Inner, E>>) -> NonEmpty<Result<Output, E>> {
        { $0.mapT(fn) }
    }
}
