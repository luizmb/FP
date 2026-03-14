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
