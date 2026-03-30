// NonEmptyTResult: outer = NonEmpty, inner = Result
// Type: NonEmpty<Result<A, E>>  (Success = A, Failure = E)

public extension NonEmpty {
    /// flatMapT for NonEmpty<Result<A, E>> — maps over success values, preserves failures.
    /// .failure → .failure
    /// .success(a) → fn(a)  (inner flatMap)
    func flatMapT<Inner, E, Output>(
        _ fn: (Inner) -> NonEmpty<Result<Output, E>>
    ) -> NonEmpty<Result<Output, E>> where A == Result<Inner, E> {
        let h: Result<Inner, E> = head
        let t: [Result<Inner, E>] = tail
        func step(_ element: Result<Inner, E>) -> NonEmpty<Result<Output, E>> {
            switch element {
            case .failure(let e): NonEmpty<Result<Output, E>>(head: .failure(e))
            case .success(let a): fn(a)
            }
        }
        let headResult = step(h)
        let tailResults = t.flatMap { step($0).toArray }
        return NonEmpty<Result<Output, E>>(head: headResult.head, tail: headResult.tail + tailResults)
    }

    static func bindT<Inner, E, Output>(
        _ fn: @escaping (Inner) -> NonEmpty<Result<Output, E>>
    ) -> (NonEmpty<Result<Inner, E>>) -> NonEmpty<Result<Output, E>> {
        { $0.flatMapT(fn) }
    }
}
