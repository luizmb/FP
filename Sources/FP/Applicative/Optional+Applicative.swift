import Foundation

public extension Optional {
    // liftA2 :: (b1 -> b2 -> b) -> Either a b1 -> Either a b2 -> Either a b
    static func liftA2<A1, A2>(_ fn: @escaping (A1, A2) -> A) -> (
        Optional<A1>, Optional<A2>
    ) -> Optional<A> {
        { optionalA, optionalB in
            Optional<(A1, A2)>.zip(optionalA, optionalB).map(fn)
        }
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
