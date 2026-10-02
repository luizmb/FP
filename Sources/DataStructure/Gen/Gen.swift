// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A composable generator of random `Value`s, driven by an explicitly injected random number
/// generator `R`.
///
/// `Gen` is the random-generator monad familiar from property-based testing — QuickCheck's
/// `Gen a` (Haskell) and ScalaCheck's `Gen[A]` (Scala). It is a ``Stateful`` computation whose
/// state is the RNG, so it inherits all of `Stateful`'s `Functor`/`Applicative`/`Monad` machinery:
///
/// ```swift
/// public typealias Gen<R: RandomNumberGenerator & Sendable, Value> = Stateful<R, Value>
/// ```
///
/// A generator is only a description, `(inout R) -> Value`. There is deliberately no runner that
/// creates the RNG for you: you always inject it, so every source of randomness is visible at the
/// call site. Use the seedable ``SplitMix64`` for reproducible output, `SystemRandomNumberGenerator`
/// for entropy (at the edge of your program), or ``AnyRandomNumberGenerator`` to erase the type.
///
/// ## Composing generators
///
/// ```swift
/// typealias G<V> = Gen<SplitMix64, V>
///
/// let die: G<Int> = .int(in: 1...6)
/// let pair = G.zip(die, die).map { $0 + $1 } // 2...12
/// ```
///
/// ## Running a generator
///
/// Inject the generator and run the `Stateful`:
///
/// ```swift
/// var rng = SplitMix64(seed: 42) // reproducible: same seed, same values
/// let value = die.run(&rng)
/// let many = die.array(ofCount: 100).run(&rng)
/// ```
///
/// - SeeAlso: ``Stateful``, ``SplitMix64``, ``AnyRandomNumberGenerator``
public typealias Gen<R: RandomNumberGenerator & Sendable, Value> = Stateful<R, Value>

// MARK: - Type-erased Sendable RNG

/// A type-erased, `Sendable` `RandomNumberGenerator`.
///
/// Use it as ``Gen``'s `R` when the concrete generator should not appear in the type. The wrapped
/// value is constrained to `RandomNumberGenerator & Sendable`, so the eraser is itself `Sendable`.
public struct AnyRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var base: any RandomNumberGenerator & Sendable

    /// Erases a concrete `Sendable` random number generator.
    public init(_ base: some RandomNumberGenerator & Sendable) {
        self.base = base
    }

    public mutating func next() -> UInt64 {
        base.next()
    }
}

// MARK: - Seedable PRNG

/// A small, fast, **seedable** pseudo-random number generator implementing the public-domain
/// SplitMix64 algorithm.
///
/// SplitMix64 (Steele, Lea & Flood, *"Fast Splittable Pseudorandom Number Generators,"* OOPSLA
/// 2014) has a single 64-bit state seeded from one `UInt64`, which is exactly what reproducible
/// property-based testing needs: the same seed yields the same sequence on every platform. The
/// algorithm is unpatented and the canonical reference implementation is dedicated to the public
/// domain (CC0); this is an independent Swift implementation of the published algorithm.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// Creates a generator seeded with `seed`.
    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
