// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Optional {
    /// liftA2 :: (a1 -> a2 -> a) -> Optional<a1> -> Optional<a2> -> Optional<a>
    static func liftA2<A1, A2>(_ fn: @escaping @Sendable (A1, A2) -> A) -> @Sendable (A1?, A2?) -> A? {
        { optionalA, optionalB in
            (A1, A2)?.zip(optionalA, optionalB).map(fn)
        }
    }

    /// apply :: Optional<(a -> b)> -> Optional<a> -> Optional<b>
    static func apply<A>(_ functions: (@Sendable (A) -> Wrapped)?, _ values: A?) -> Wrapped? {
        functions.flatMap(values.map)
    }

    /// seqRight :: Optional<a> -> Optional<b> -> Optional<b>
    /// Run both, discard the left result, return the right
    func seqRight<A>(_ rhs: A?) -> A? {
        flatMap(const(rhs))
    }

    /// seqLeft :: Optional<a> -> Optional<b> -> Optional<a>
    /// Run both, return the left result
    func seqLeft<Ignore>(_ rhs: Ignore?) -> Wrapped? {
        flatMap { a in rhs.map(const(a)) }
    }

    fileprivate struct UnwrapError: Error {}
    /// The `property` property.
    static func zip<A1, A2, each Ax>(
        _ first: A1?,
        _ second: A2?,
        _ additional: repeat (each Ax)?
    ) -> A?
    where A == (A1, A2, repeat each Ax) {
        // swiftlint:disable:next throws_instead_result
        func unwrap<T>(_ t: T?) throws -> T { // throws for do/catch zip, returns Optional at boundary
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
