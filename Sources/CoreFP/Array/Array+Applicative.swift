// SPDX-License-Identifier: Apache-2.0
import Foundation

public extension Array {
    /// pure :: a -> [a]
    /// Lift a value into the minimal successful context — a singleton array.
    static func pure(_ value: Element) -> [Element] {
        [value]
    }

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

    /// zip3 :: [a1] -> [a2] -> [a3] -> [(a1, a2, a3)]
    /// Truncates to the shortest input, same as `zip(_:_:)`.
    static func zip3<A1, A2, A3>(_ a1: [A1], _ a2: [A2], _ a3: [A3]) -> [Element]
    where Element == (A1, A2, A3) {
        Swift.zip(Swift.zip(a1, a2), a3).map { ab, c in (ab.0, ab.1, c) }
    }

    /// zip4 :: [a1] -> [a2] -> [a3] -> [a4] -> [(a1, a2, a3, a4)]
    /// Truncates to the shortest input, same as `zip(_:_:)`.
    static func zip4<A1, A2, A3, A4>(_ a1: [A1], _ a2: [A2], _ a3: [A3], _ a4: [A4]) -> [Element]
    where Element == (A1, A2, A3, A4) {
        Swift.zip(Swift.zip(Swift.zip(a1, a2), a3), a4).map { abc, d in (abc.0.0, abc.0.1, abc.1, d) }
    }
}
