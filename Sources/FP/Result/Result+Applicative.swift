import Foundation

public extension Result {
    // liftA2 :: (a1 -> a2 -> a) -> Result<a1, b> -> Result<a2, b> -> Result<a, b>
    static func liftA2<A1, A2>(_ fn: @escaping (A1, A2) -> A) -> (
        Result<A1, B>, Result<A2, B>
    ) -> Result<A, B> {
        { resultA, resultB in
            resultA.flatMap { a in resultB.map { b in fn(a, b) } }
        }
    }

    /// apply :: Result<(a -> b), e> -> Result<a, e> -> Result<b, e>
    static func apply<A>(_ functions: Result<(A) -> Success, Failure>, _ values: Result<A, Failure>) -> Result<Success, Failure> {
        functions.flatMap(values.map)
    }

    /// seqRight :: Result<a, e> -> Result<b, e> -> Result<b, e>
    /// Run both, discard the left result, return the right
    func seqRight<A>(_ rhs: Result<A, Failure>) -> Result<A, Failure> {
        flatMap(const(rhs))
    }

    /// seqLeft :: Result<a, e> -> Result<b, e> -> Result<a, e>
    /// Run both, return the left result
    func seqLeft<Ignore>(_ rhs: Result<Ignore, Failure>) -> Result<Success, Failure> {
        flatMap { a in rhs.map(const(a)) }
    }

    static func zip<A1, A2, each Ax>(
        _ first: Result<A1, B>,
        _ second: Result<A2, B>,
        _ additional: repeat Result<(each Ax), B>
    ) -> Result<A, B>
    where A == (A1, A2, repeat each Ax) {
        func unwrap<T, E: Error>(_ t: Result<T, E>) throws(E) -> T {
            try t.get()
        }

        do {
            return try Result.success((
                unwrap(first),
                unwrap(second),
                repeat unwrap(each additional)
            ))
        } catch {
            return Result.failure(error)
        }
    }
}
