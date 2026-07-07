// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Writer: Semigroup / Monoid

//
// `Writer<W, A>` is a product type `(A, W)`. Its natural `Semigroup` / `Monoid` combines
// BOTH components pointwise — the value via `A: Semigroup` and the log via the already-required
// `W: Monoid` — unlike `Reader`, whose Semigroup/Monoid lifts over a function *result* instead
// of a stored product.
//
//   combine(w1, w2) = Writer(combine(w1.value, w2.value), combine(w1.log, w2.log))
//   identity        = Writer(A.identity, W.identity)

extension Writer: Semigroup where A: Semigroup {
    /// Combines two `Writer`s by merging their values with `A.combine` and their logs with
    /// `W.combine`.
    ///
    /// ```swift
    /// let combined = Writer<[String], String>.combine(
    ///     Writer("foo", ["step 1"]),
    ///     Writer("bar", ["step 2"])
    /// )
    /// combined.value // "foobar"
    /// combined.log   // ["step 1", "step 2"]
    /// ```
    public static func combine(_ lhs: Self, _ rhs: Self) -> Self {
        Writer(A.combine(lhs.value, rhs.value), W.combine(lhs.log, rhs.log))
    }
}

extension Writer: Monoid where A: Monoid {
    /// The identity `Writer` — `A.identity` paired with `W.identity`.
    ///
    /// ```swift
    /// let id = Writer<[String], String>.identity
    /// id.value // ""
    /// id.log   // []
    /// ```
    public static var identity: Self {
        Writer(A.identity, W.identity)
    }
}
