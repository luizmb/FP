import CoreFP

public extension Newtype where RawValue: Numeric & ExpressibleByIntegerLiteral & Sendable {
    /// This raw value viewed under the **additive** monoid (`+`, identity `0`).
    ///
    /// A bare `Newtype<…, Int>` can't *be* a `Monoid` (`Int` has two — addition and
    /// multiplication), so the choice is exposed as a one-hop view instead:
    ///
    /// ```swift
    /// mconcat([UserScore(2), UserScore(3)].map(\.sum)).rawValue   // 5
    /// ```
    var sum: NumericMonoid<RawValue>.Sum { NumericMonoid<RawValue>.Sum(rawValue) }

    /// This raw value viewed under the **multiplicative** monoid (`*`, identity `1`).
    var product: NumericMonoid<RawValue>.Product { NumericMonoid<RawValue>.Product(rawValue) }
}
