// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Foldable

public extension NonEmpty {
    /// Left fold — accumulates left-to-right.
    func foldLeft<B>(_ initial: B, _ fn: (B, A) -> B) -> B {
        toArray.reduce(initial, fn)
    }

    /// Right fold — accumulates right-to-left.
    func foldRight<B>(_ initial: B, _ fn: (A, B) -> B) -> B {
        toArray.reversed().reduce(initial) { acc, a in fn(a, acc) }
    }

    /// Map each element to a `Monoid`, then combine all results.
    func foldMap<M: Monoid>(_ fn: (A) -> M) -> M {
        mconcat(toArray.map(fn))
    }

    /// Convenience alias — matches Swift's `Array` vocabulary.
    var toList: [A] { toArray }
}
