import Foundation

public extension Optional {
    // liftA2 :: (a1 -> a2 -> a) -> Optional<a1> -> Optional<a2> -> Optional<a>
    static func liftA2<A1, A2>(_ fn: @escaping (A1, A2) -> A) -> (
        Optional<A1>, Optional<A2>
    ) -> Optional<A> {
        { optionalA, optionalB in
            Optional<(A1, A2)>.zip(optionalA, optionalB).map(fn)
        }
    }

    /// apply :: Optional<(a -> b)> -> Optional<a> -> Optional<b>
    static func apply<A>(_ functions: Optional<(A) -> Wrapped>, _ values: Optional<A>) -> Optional<Wrapped> {
        functions.flatMap(values.map)
    }

    /// seqRight :: Optional<a> -> Optional<b> -> Optional<b>
    /// Run both, discard the left result, return the right
    func seqRight<A>(_ rhs: Optional<A>) -> Optional<A> {
        flatMap(const(rhs))
    }

    /// seqLeft :: Optional<a> -> Optional<b> -> Optional<a>
    /// Run both, return the left result
    func seqLeft<Ignore>(_ rhs: Optional<Ignore>) -> Optional<Wrapped> {
        flatMap { a in rhs.map(const(a)) }
    }

    fileprivate struct UnwrapError: Error {}
    static func zip<A1, A2, each Ax>(
        _ first: A1?,
        _ second: A2?,
        _ additional: repeat (each Ax)?
    ) -> A?
    where A == (A1, A2, repeat each Ax) {
        func unwrap<T>(_ t: T?) throws -> T {
            guard let t else { throw UnwrapError() }
            return t
        }

        do {
            return try (
                unwrap(first),
                unwrap(second),
                repeat unwrap(each additional)
            )
        } catch {
            return nil
        }
    }
}
