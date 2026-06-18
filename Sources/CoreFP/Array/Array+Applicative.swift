// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Array {
    /// liftA2 :: (a -> b -> c) -> [a] -> [b] -> [c]
    static func liftA2<A1, A2>(
        _ fn: @escaping @Sendable (A1, A2) -> Element
    ) -> @Sendable ([A1], [A2]) -> [Element] {
        { arrayA, arrayB in
            arrayA.flatMap { a in
                arrayB.map { b in
                    fn(a, b)
                }
            }
        }
    }

    /// Applicative apply - applies an array of functions to an array of values
    /// (<*>) :: [a -> b] -> [a] -> [b]
    static func apply<A>(_ functions: [@Sendable (A) -> Element], _ values: [A]) -> [Element] {
        functions.flatMap(values.map)
    }

    /// seqRight :: [a] -> [b] -> [b]
    /// Cartesian product, keeping right values
    func seqRight<A>(_ rhs: [A]) -> [A] {
        flatMap(const(rhs))
    }

    /// seqLeft :: [a] -> [b] -> [a]
    /// Cartesian product, keeping left values
    func seqLeft<Ignore>(_ rhs: [Ignore]) -> [Element] {
        flatMap { a in rhs.map(const(a)) }
    }

    /// zip :: [a] -> [b] -> [(a, b)]
    static func zip<A1, A2>(_ lhs: [A1], _ rhs: [A2]) -> [Element]
    where Element == (A1, A2) {
        Swift.zip(lhs, rhs).map(CoreFP.id)
    }
}
